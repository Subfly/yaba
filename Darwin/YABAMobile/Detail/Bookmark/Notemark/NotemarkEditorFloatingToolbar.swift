//
//  NotemarkEditorFloatingToolbar.swift
//  YABA
//

import PhotosUI
import SwiftUI

// MARK: - Editor floating toolbar

/// Floating Markdown editor chrome — mirrors ``LinkmarkReaderFloatingToolbar`` glass / fallback styling.
struct NotemarkEditorFloatingToolbar: View {
    let folderAccent: Color
    let isVisible: Bool
    let showsDoneButton: Bool
    let onDispatch: (String) -> Void
    let onRequestAddLinkSheet: (AddLinkSheetMode) -> Void
    let onRequestAddTableSheet: () -> Void
    let onRequestAddMentionSheet: () -> Void
    let onDismissKeyboard: () -> Void
    let onRequestPickImageFromCamera: () -> Void
    var galleryPhotoItem: Binding<PhotosPickerItem?>

    @State
    private var showGalleryPhotoPicker = false

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 18) {
                    toolbarMenusRow
                }
                .glassEffect(.regular.interactive())
            } else {
                toolbarMenusRow
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
            }
        }
        .photosPicker(
            isPresented: $showGalleryPhotoPicker,
            selection: galleryPhotoItem,
            matching: .images
        )
        .fixedSize(horizontal: true, vertical: false)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .animation(.smooth, value: isVisible)
        .allowsHitTesting(isVisible)
    }

    @ViewBuilder
    private var toolbarMenusRow: some View {
        HStack(spacing: 0) {
            headingMenu()
            textStyleMenu()
            insertMenu()
            highlightButton()
            indentMenu()
            historyMenu()
            if showsDoneButton {
                doneButton()
            }
        }
        .animation(.smooth, value: showsDoneButton)
    }

    // MARK: Menus

    @ViewBuilder
    private func headingMenu() -> some View {
        Menu {
            ForEach(Array((1 ... 6).reversed()), id: \.self) { level in
                Button {
                    onDispatch(YabaEditorDispatchPayload.setHeading(level: level))
                } label: {
                    HStack {
                        toolbarGlyph(Self.headingIconKey(level), color: folderAccent)
                        Text("Notemark Option Heading Label \(level)")
                    }
                }
            }
        } label: {
            menuLabelIcon("heading", color: folderAccent)
        }
    }

    @ViewBuilder
    private func textStyleMenu() -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleBold)
            } label: {
                menuRow(icon: "text-bold", title: "Notemark Option Bold Label")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleItalic)
            } label: {
                menuRow(icon: "text-italic", title: "Notemark Option Italic Label")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleStrikethrough)
            } label: {
                menuRow(icon: "text-strikethrough", title: "Notemark Option Strikethrough Label")
            }
        } label: {
            menuLabelIcon("text-font", color: folderAccent)
        }
    }

    @ViewBuilder
    private func insertMenu() -> some View {
        Menu {
            Button {
                onRequestAddTableSheet()
            } label: {
                menuRow(icon: "grid-table", title: "Notemark Option Add Table Label")
            }
            Button {
                onRequestAddLinkSheet(.link)
            } label: {
                menuRow(icon: "link-04", title: "Notemark Option Add Link Label")
            }
            Button {
                onRequestAddMentionSheet()
            } label: {
                menuRow(icon: "at", title: "Notemark Option Add Mention Label")
            }
            Menu {
                Button {
                    onRequestPickImageFromCamera()
                } label: {
                    menuRow(icon: "camera-01", title: "Notemark Option Pick Image From Camera Label")
                }
                Button {
                    showGalleryPhotoPicker = true
                } label: {
                    menuRow(icon: "image-02", title: "Notemark Option Pick Image From Gallery Label")
                }
                Button {
                    onRequestAddLinkSheet(.image)
                } label: {
                    menuRow(icon: "link-04", title: "Notemark Option Add Image From Link Label")
                }
            } label: {
                menuRow(icon: "image-add-02", title: "Notemark Option Add Image Label")
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleCode)
                } label: {
                    menuRow(icon: "code", title: "Notemark Option Add Inline Code Label")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleCodeBlock)
                } label: {
                    menuRow(icon: "source-code-square", title: "Notemark Option Add Code Block Label")
                }
            } label: {
                menuRow(icon: "source-code", title: "Notemark Option Add Code Label")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleQuote)
            } label: {
                menuRow(icon: "quote-down", title: "Notemark Option Add Blockquote Label")
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.insertHr)
            } label: {
                menuRow(icon: "solid-line-01", title: "Notemark Option Add Horizontal Line Label")
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleBulletedList)
                } label: {
                    menuRow(icon: "left-to-right-list-bullet", title: "Notemark Option Add Unordered List Label")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleNumberedList)
                } label: {
                    menuRow(icon: "left-to-right-list-number", title: "Notemark Option Add Ordered List Label")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleTaskList)
                } label: {
                    menuRow(icon: "check-list", title: "Notemark Option Add Task List Label")
                }
            } label: {
                menuRow(icon: "left-to-right-list-dash", title: "Notemark Option Add List Label")
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.insertInlineMathEmpty)
                } label: {
                    menuRow(icon: "absolute", title: "Notemark Option Add Inline Math Label")
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.insertBlockMathEmpty)
                } label: {
                    menuRow(icon: "alpha-square", title: "Notemark Option Add Block Math Label")
                }
            } label: {
                menuRow(icon: "calculator", title: "Notemark Option Add Math Label")
            }
        } label: {
            menuLabelIcon("add-01", color: folderAccent)
        }
    }

    @ViewBuilder
    private func highlightButton() -> some View {
        Button {
            onDispatch(YabaEditorDispatchPayload.toggleHighlight)
        } label: {
            menuLabelIcon("highlighter", color: folderAccent)
        }
    }

    @ViewBuilder
    private func indentMenu() -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.indent)
            } label: {
                menuRow(icon: "text-indent-more", title: "Notemark Option Add Indent Label")
            }.menuActionDismissBehavior(.disabled)
            Button {
                onDispatch(YabaEditorDispatchPayload.outdent)
            } label: {
                menuRow(icon: "text-indent-less", title: "Notemark Option Add Outdent Label")
            }.menuActionDismissBehavior(.disabled)
        } label: {
            menuLabelIcon("text-indent", color: folderAccent)
        }
    }

    @ViewBuilder
    private func historyMenu() -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.undo)
            } label: {
                menuRow(icon: "undo-02", title: "Notemark Option Do Undo Label")
            }.menuActionDismissBehavior(.disabled)
            Button {
                onDispatch(YabaEditorDispatchPayload.redo)
            } label: {
                menuRow(icon: "redo-02", title: "Notemark Option Do Redo Label")
            }.menuActionDismissBehavior(.disabled)
        } label: {
            menuLabelIcon("repeat", color: folderAccent)
        }
    }

    @ViewBuilder
    private func doneButton() -> some View {
        Button {
            onDismissKeyboard()
        } label: {
            menuLabelIcon("tick-01", color: folderAccent)
        }
    }

    // MARK: Pieces

    private func menuRow(icon: String, title: LocalizedStringKey) -> some View {
        HStack {
            toolbarGlyph(icon, color: folderAccent)
            Text(title)
        }
    }

    @ViewBuilder
    private func menuLabelIcon(_ icon: String, color: Color) -> some View {
        if #available(iOS 26, *) {
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
