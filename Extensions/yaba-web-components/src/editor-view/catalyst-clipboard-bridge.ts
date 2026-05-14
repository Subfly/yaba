/**
 * Mac Catalyst: WKWebView clipboard + ⌘-key routing is unreliable. When `window.__YABA_MAC_CATALYST__`
 * is set by the native host, copy/cut/paste go through `UIPasteboard` via the yabaNativeHost JSON bridge.
 */
import { EditorState, EditorSelection } from "@codemirror/state"
import { EditorView } from "@codemirror/view"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"

declare global {
  interface Window {
    __YABA_MAC_CATALYST__?: boolean
    __yabaDeliverNativePaste?: (text: string) => void
    __yabaTriggerNativeCopy?: () => void
    __yabaTriggerNativeCut?: () => void
  }
}

function bridgeActive(view: EditorView): boolean {
  if (typeof window === "undefined") return false
  if (window.__YABA_MAC_CATALYST__ !== true) return false
  if (!window.YabaNativeHost) return false
  return view.state.facet(EditorState.readOnly) !== true
}

export function yabaMacCatalystClipboardBridge(): import("@codemirror/state").Extension {
  return EditorView.domEventHandlers({
    copy(event, view) {
      if (!bridgeActive(view)) return false
      const main = view.state.selection.main
      if (main.empty) {
        event.preventDefault()
        return true
      }
      const text = view.state.sliceDoc(main.from, main.to)
      event.preventDefault()
      postToYabaNativeHost({ type: "catalystClipboard", op: "write", text })
      return true
    },
    cut(event, view) {
      if (!bridgeActive(view)) return false
      const main = view.state.selection.main
      if (main.empty) {
        event.preventDefault()
        return true
      }
      const text = view.state.sliceDoc(main.from, main.to)
      event.preventDefault()
      postToYabaNativeHost({ type: "catalystClipboard", op: "write", text })
      view.dispatch({
        changes: { from: main.from, to: main.to, insert: "" },
        userEvent: "cut",
      })
      return true
    },
    paste(event, view) {
      if (!bridgeActive(view)) return false
      event.preventDefault()
      postToYabaNativeHost({ type: "catalystClipboard", op: "readPaste" })
      return true
    },
  })
}

export function installYabaCatalystClipboardGlobals(getView: () => EditorView | null): void {
  if (typeof window === "undefined") return
  window.__yabaDeliverNativePaste = (text: string) => {
    const view = getView()
    if (!view || !bridgeActive(view)) return
    const t = text ?? ""
    const main = view.state.selection.main
    view.focus()
    view.dispatch({
      changes: { from: main.from, to: main.to, insert: t },
      selection: EditorSelection.cursor(main.from + t.length),
      userEvent: "input.paste",
    })
  }
  window.__yabaTriggerNativeCopy = () => {
    const view = getView()
    if (!view || !bridgeActive(view)) return
    const main = view.state.selection.main
    if (main.empty) return
    const text = view.state.sliceDoc(main.from, main.to)
    postToYabaNativeHost({ type: "catalystClipboard", op: "write", text })
  }
  window.__yabaTriggerNativeCut = () => {
    const view = getView()
    if (!view || !bridgeActive(view)) return
    const main = view.state.selection.main
    if (main.empty) return
    const text = view.state.sliceDoc(main.from, main.to)
    postToYabaNativeHost({ type: "catalystClipboard", op: "write", text })
    view.dispatch({
      changes: { from: main.from, to: main.to, insert: "" },
      userEvent: "cut",
    })
  }
}
