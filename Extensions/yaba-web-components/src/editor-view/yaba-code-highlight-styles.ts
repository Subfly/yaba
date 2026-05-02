/**
 * Programming-token colors for fenced code blocks.
 *
 * CodeMirror's [defaultHighlightStyle] is tuned for light backgrounds. For dark mode we pair
 * [themeType: "dark"] with [EditorView.darkTheme], driven from the host/reader pipeline in
 * [surface.syncCodemirrorDarkTheme].
 */
import { HighlightStyle } from "@codemirror/language"
import { tags } from "@lezer/highlight"

/** Mirrors @codemirror/language `defaultHighlightStyle` with explicit light theming. */
export const yabaLightCodeHighlightStyle = HighlightStyle.define(
  [
    { tag: tags.meta, color: "#404740" },
    { tag: tags.link, textDecoration: "underline" },
    {
      tag: tags.heading,
      textDecoration: "underline",
      fontWeight: "bold",
    },
    { tag: tags.emphasis, fontStyle: "italic" },
    { tag: tags.strong, fontWeight: "bold" },
    { tag: tags.strikethrough, textDecoration: "line-through" },
    { tag: tags.keyword, color: "#708" },
    {
      tag: [tags.atom, tags.bool, tags.url, tags.contentSeparator, tags.labelName],
      color: "#219",
    },
    { tag: [tags.literal, tags.inserted], color: "#164" },
    { tag: [tags.string, tags.deleted], color: "#a11" },
    {
      tag: [tags.regexp, tags.escape, tags.special(tags.string)],
      color: "#e40",
    },
    { tag: tags.definition(tags.variableName), color: "#00f" },
    { tag: tags.local(tags.variableName), color: "#30a" },
    { tag: [tags.typeName, tags.namespace], color: "#085" },
    { tag: tags.className, color: "#167" },
    {
      tag: [tags.special(tags.variableName), tags.macroName],
      color: "#256",
    },
    { tag: tags.definition(tags.propertyName), color: "#00c" },
    { tag: tags.comment, color: "#940" },
    { tag: tags.invalid, color: "#f00" },
  ],
  { themeType: "light" },
)

/** YABA dark palette–friendly contrasts on `#121318` (see [yabaDark] in `@/theme/yaba-palette`). */
export const yabaDarkCodeHighlightStyle = HighlightStyle.define(
  [
    { tag: tags.meta, color: "#a6a9b9" },
    { tag: tags.link, textDecoration: "underline" },
    {
      tag: tags.heading,
      textDecoration: "underline",
      fontWeight: "bold",
    },
    { tag: tags.emphasis, fontStyle: "italic" },
    { tag: tags.strong, fontWeight: "bold" },
    { tag: tags.strikethrough, textDecoration: "line-through" },
    /* primary */
    { tag: tags.keyword, color: "#B1C5FF" },
    {
      tag: [tags.atom, tags.bool, tags.url, tags.contentSeparator, tags.labelName],
      color: "#9CCFFF",
    },
    { tag: [tags.literal, tags.inserted], color: "#7FD8BE" },
    { tag: [tags.string, tags.deleted], color: "#F0B8A8" },
    {
      tag: [tags.regexp, tags.escape, tags.special(tags.string)],
      color: "#FFB59A",
    },
    /* on-background–biased blues / violets */
    { tag: tags.definition(tags.variableName), color: "#DAE2FF" },
    { tag: tags.local(tags.variableName), color: "#C9CCE4" },
    { tag: [tags.typeName, tags.namespace], color: "#83E3C8" },
    { tag: tags.className, color: "#B8C9FF" },
    {
      tag: [tags.special(tags.variableName), tags.macroName],
      color: "#CBB7F7",
    },
    { tag: tags.definition(tags.propertyName), color: "#A8D8FF" },
    { tag: tags.comment, color: "#8F9099" },
    { tag: tags.invalid, color: "#FFB4AB" },
  ],
  { themeType: "dark" },
)
