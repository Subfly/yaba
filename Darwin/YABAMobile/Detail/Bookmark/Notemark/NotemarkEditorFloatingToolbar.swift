//
//  NotemarkEditorFloatingToolbar.swift
//  YABA
//

import SwiftUI

// MARK: - Editor floating toolbar

/// Floating Markdown editor chrome — mirrors ``LinkmarkReaderFloatingToolbar`` glass / fallback styling.
struct NotemarkEditorFloatingToolbar: View {
    let folderAccent: Color
    let isVisible: Bool
    /// Done control — only while the software keyboard is on-screen (driven by the host).
    let showsDoneButton: Bool
    let onDispatch: (String) -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 30) {
                    toolbarMenusRow(padLabels: true)
                }
                .glassEffect(.regular.interactive())
            } else {
                toolbarMenusRow(padLabels: false)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .animation(.smooth, value: isVisible)
        .allowsHitTesting(isVisible)
    }

    @ViewBuilder
    private func toolbarMenusRow(padLabels: Bool) -> some View {
        HStack(spacing: padLabels ? 0 : 10) {
            headingMenu(padLabels: padLabels)
            textStyleMenu(padLabels: padLabels)
            insertMenu(padLabels: padLabels)
            highlightButton(padLabels: padLabels)
            indentMenu(padLabels: padLabels)
            historyMenu(padLabels: padLabels)
            if showsDoneButton {
                doneButton(padLabels: padLabels)
            }
        }
        .animation(.smooth, value: showsDoneButton)
    }

    // MARK: Menus

    @ViewBuilder
    private func headingMenu(padLabels: Bool) -> some View {
        Menu {
            ForEach(Array((1 ... 6).reversed()), id: \.self) { level in
                Button {
                    onDispatch(YabaEditorDispatchPayload.setHeading(level: level))
                } label: {
                    HStack {
                        toolbarGlyph(Self.headingIconKey(level), color: folderAccent)
                        Text("Heading \(level)")
                    }
                }
            }
        } label: {
            menuLabelIcon("heading", padLabels: padLabels, color: folderAccent)
        }
    }

    @ViewBuilder
    private func textStyleMenu(padLabels: Bool) -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleBold)
            } label: {
                menuRow(icon: "text-bold", title: "Bold")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleItalic)
            } label: {
                menuRow(icon: "text-italic", title: "Italic")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleStrikethrough)
            } label: {
                menuRow(icon: "text-strikethrough", title: "Strikethrough")
            }
        } label: {
            menuLabelIcon("text-font", padLabels: padLabels, color: folderAccent)
        }
    }

    @ViewBuilder
    private func insertMenu(padLabels: Bool) -> some View {
        Menu {
            Button {} label: {
                menuRow(icon: "grid-table", title: "Table")
            }
            Button {} label: {
                menuRow(icon: "link-04", title: "Link")
            }
            Button {} label: {
                menuRow(icon: "at", title: "Mention")
            }
            Menu {
                Button {} label: {
                    menuRow(icon: "image-02", title: "Image from gallery")
                }
                Button {} label: {
                    menuRow(icon: "camera-01", title: "Image from camera")
                }
            } label: {
                menuRow(icon: "image-add-02", title: "Image")
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleCode)
                } label: {
                    menuRow(icon: "code", title: "Inline code")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleCodeBlock)
                } label: {
                    menuRow(icon: "source-code-square", title: "Code block")
                }
            } label: {
                menuRow(icon: "source-code", title: "Code")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleQuote)
            } label: {
                menuRow(icon: "quote-down", title: "Blockquote")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.insertHr)
            } label: {
                menuRow(icon: "solid-line-01", title: "Horizontal line")
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleBulletedList)
                } label: {
                    menuRow(icon: "left-to-right-list-bullet", title: "Unordered list")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleNumberedList)
                } label: {
                    menuRow(icon: "left-to-right-list-number", title: "Ordered list")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleTaskList)
                } label: {
                    menuRow(icon: "check-list", title: "Task list")
                }
            } label: {
                menuRow(icon: "left-to-right-list-dash", title: "List")
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.insertInlineMathEmpty)
                } label: {
                    menuRow(icon: "absolute", title: "Inline math")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.insertBlockMathEmpty)
                } label: {
                    menuRow(icon: "alpha-square", title: "Block math")
                }
            } label: {
                menuRow(icon: "calculator", title: "Math")
            }
        } label: {
            menuLabelIcon("add-01", padLabels: padLabels, color: folderAccent)
        }
    }

    @ViewBuilder
    private func highlightButton(padLabels: Bool) -> some View {
        Button {} label: {
            menuLabelIcon("highlighter", padLabels: padLabels, color: folderAccent)
        }
    }

    @ViewBuilder
    private func indentMenu(padLabels: Bool) -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.indent)
            } label: {
                menuRow(icon: "text-indent-more", title: "Indent")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.outdent)
            } label: {
                menuRow(icon: "text-indent-less", title: "Outdent")
            }
        } label: {
            menuLabelIcon("text-indent", padLabels: padLabels, color: folderAccent)
        }
    }

    @ViewBuilder
    private func historyMenu(padLabels: Bool) -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.undo)
            } label: {
                menuRow(icon: "undo-03", title: "Undo")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.redo)
            } label: {
                menuRow(icon: "redo-03", title: "Redo")
            }
        } label: {
            menuLabelIcon("repeat", padLabels: padLabels, color: folderAccent)
        }
    }

    @ViewBuilder
    private func doneButton(padLabels: Bool) -> some View {
        Button {
            onDismissKeyboard()
        } label: {
            menuLabelIcon("tick-01", padLabels: padLabels, color: folderAccent)
        }
        .accessibilityLabel(Text("Done"))
    }

    // MARK: Pieces

    private func menuRow(icon: String, title: String) -> some View {
        HStack {
            toolbarGlyph(icon, color: folderAccent)
            Text(title)
        }
    }

    @ViewBuilder
    private func menuLabelIcon(
        _ icon: String,
        padLabels: Bool,
        color: Color
    ) -> some View {
        if padLabels {
            toolbarGlyph(icon, color: color).padding()
        } else {
            toolbarGlyph(icon, color: color)
        }
    }

    private func toolbarGlyph(_ icon: String, color: Color) -> some View {
        YabaIconView(bundleKey: icon)
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
    }

    private static func headingIconKey(_ level: Int) -> String {
        String(format: "heading-%02d", level)
    }
}
