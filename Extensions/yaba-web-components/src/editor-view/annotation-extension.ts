import {
  RangeSetBuilder,
  StateEffect,
  StateField,
  type Extension,
  type Transaction,
} from "@codemirror/state"
import { Decoration, DecorationSet, EditorView } from "@codemirror/view"

/** Native-driven annotation metadata; character ranges live in editor state until a future storage format exists. */
export interface AnnotationForRendering {
  id: string
  colorRole: string
}

type AnnRange = { id: string; from: number; to: number; colorRole: string }

export type AnnotationModel = { ranges: AnnRange[]; palette: Map<string, string> }

const colorRoleToClass: Record<string, string> = {
  NONE: "yaba-highlight-yellow",
  BLUE: "yaba-highlight-blue",
  BROWN: "yaba-highlight-brown",
  CYAN: "yaba-highlight-cyan",
  GRAY: "yaba-highlight-gray",
  GREEN: "yaba-highlight-green",
  INDIGO: "yaba-highlight-indigo",
  MINT: "yaba-highlight-mint",
  ORANGE: "yaba-highlight-orange",
  PINK: "yaba-highlight-pink",
  PURPLE: "yaba-highlight-purple",
  RED: "yaba-highlight-red",
  TEAL: "yaba-highlight-teal",
  YELLOW: "yaba-highlight-yellow",
}

function getAnnotationClass(colorRole: string): string {
  return colorRoleToClass[colorRole.toUpperCase()] ?? "yaba-highlight-yellow"
}

function mapRangesOnChange(ranges: AnnRange[], tr: Transaction): AnnRange[] {
  return ranges
    .map((a) => ({
      ...a,
      from: tr.changes.mapPos(a.from),
      to: tr.changes.mapPos(a.to),
    }))
    .filter((a) => a.from < a.to)
}

export const addAnnotationRange = StateEffect.define<AnnRange>()
export const removeAnnotationId = StateEffect.define<string>()
export const setAnnotationPaletteEffect = StateEffect.define<AnnotationForRendering[]>()

function buildDecorationSet(ranges: AnnRange[]): DecorationSet {
  const b = new RangeSetBuilder<Decoration>()
  for (const a of ranges) {
    const cls = getAnnotationClass(a.colorRole)
    b.add(
      a.from,
      a.to,
      Decoration.mark({
        class: `yaba-annotation-decoration ${cls}`,
        attributes: { "data-annotation-id": a.id },
      }),
    )
  }
  return b.finish()
}

export const resetAnnotationRanges = StateEffect.define<true>()

export const annotationModel = StateField.define<AnnotationModel>({
  create: () => ({ ranges: [], palette: new Map() }),
  update(value, tr) {
    let ranges = tr.docChanged ? mapRangesOnChange(value.ranges, tr) : value.ranges
    let palette = value.palette

    for (const e of tr.effects) {
      if (e.is(resetAnnotationRanges)) {
        ranges = []
      } else if (e.is(addAnnotationRange)) {
        ranges = [...ranges, e.value]
      } else if (e.is(removeAnnotationId)) {
        const id = e.value
        ranges = ranges.filter((a) => a.id !== id)
      } else if (e.is(setAnnotationPaletteEffect)) {
        palette = new Map(e.value.map((x) => [x.id, x.colorRole]))
        ranges = ranges.map((a) => {
          const role = palette.get(a.id)
          return role != null ? { ...a, colorRole: role } : a
        })
      }
    }

    return { ranges, palette }
  },
})

export const annotationDecorations = StateField.define<DecorationSet>({
  create(s) {
    return buildDecorationSet(s.field(annotationModel).ranges)
  },
  update(value, tr) {
    if (
      tr.docChanged ||
      tr.effects.some(
        (e) =>
          e.is(setAnnotationPaletteEffect) ||
          e.is(addAnnotationRange) ||
          e.is(removeAnnotationId) ||
          e.is(resetAnnotationRanges),
      )
    ) {
      return buildDecorationSet(tr.state.field(annotationModel).ranges)
    }
    return value.map(tr.changes)
  },
  provide: (f) => EditorView.decorations.from(f),
})

export function createAnnotationDomHandlers(): Extension {
  return EditorView.domEventHandlers({
    click(ev) {
      const t = ev.target as HTMLElement | null
      const el = t?.closest?.(".yaba-annotation-decoration") as HTMLElement | null
      const annotationId = el?.getAttribute?.("data-annotation-id")
      if (annotationId) {
        ev.preventDefault()
        const win = window as Window & {
          YabaEditorBridge?: { onAnnotationTap?: (id: string) => void }
        }
        win.YabaEditorBridge?.onAnnotationTap?.(annotationId)
        return true
      }
      return false
    },
  })
}

export function selectionOverlapsAnnotationRange(ranges: AnnRange[], from: number, to: number): boolean {
  if (from === to) return false
  for (const a of ranges) {
    if (a.from < to && a.to > from) return true
  }
  return false
}

export function getDefaultColorRoleForId(model: AnnotationModel, id: string): string {
  return model.palette.get(id) ?? "YELLOW"
}

export const annotationExtensions: Extension[] = [
  annotationModel,
  annotationDecorations,
  createAnnotationDomHandlers(),
]
