//
//  NotemarkEditorNavigationTitleToolbar.swift
//  YABA
//
//  iPad / Mac Catalyst: one ``GlassEffectContainer`` around the full editor control row (same shell as
//  ``NotemarkEditorFloatingToolbar``), inside `ToolbarItemGroup(placement: .title)` so icons read as
//  one capsule instead of separate glass tiles.
//

import PhotosUI
import SwiftUI

// MARK: - Title toolbar

enum NotemarkEditorNavigationTitleToolbar {
    @ToolbarContentBuilder
    static func items(
        folderAccent: Color,
        showsDoneButton: Bool,
        showGalleryPhotoPicker: Binding<Bool>,
        galleryPhotoItem: Binding<PhotosPickerItem?>,
        onDispatch: @escaping (String) -> Void,
        onRequestAddLinkSheet: @escaping (AddLinkSheetMode) -> Void,
        onRequestAddTableSheet: @escaping () -> Void,
        onRequestAddMentionSheet: @escaping () -> Void,
        onDismissKeyboard: @escaping () -> Void,
        onRequestPickImageFromCamera: @escaping () -> Void
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: .title) {
            GlassEffectContainer(spacing: 18) {
                HStack(spacing: 0) {
                    headingMenu(folderAccent: folderAccent, onDispatch: onDispatch)
                    textStyleMenu(folderAccent: folderAccent, onDispatch: onDispatch)
                    insertMenu(
                        folderAccent: folderAccent,
                        showGalleryPhotoPicker: showGalleryPhotoPicker,
                        onDispatch: onDispatch,
                        onRequestAddLinkSheet: onRequestAddLinkSheet,
                        onRequestAddTableSheet: onRequestAddTableSheet,
                        onRequestAddMentionSheet: onRequestAddMentionSheet,
                        onRequestPickImageFromCamera: onRequestPickImageFromCamera
                    )
                    Button {
                        onDispatch(YabaEditorDispatchPayload.toggleHighlight)
                    } label: {
                        menuLabelIcon("highlighter", color: folderAccent)
                    }
                    indentMenu(folderAccent: folderAccent, onDispatch: onDispatch)
                    historyMenu(folderAccent: folderAccent, onDispatch: onDispatch)
                    if showsDoneButton {
                        Button(action: onDismissKeyboard) {
                            menuLabelIcon("tick-01", color: folderAccent)
                        }
                    }
                }
                .animation(.smooth, value: showsDoneButton)
            }
            .bookmarkFloatingReaderGlassEffectInteractive()
            .photosPicker(
                isPresented: showGalleryPhotoPicker,
                selection: galleryPhotoItem,
                matching: .images
            )
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    // MARK: Menus (navigation title bar)

    @ViewBuilder
    private static func headingMenu(folderAccent: Color, onDispatch: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(1 ... 6, id: \.self) { level in
                Button {
                    onDispatch(YabaEditorDispatchPayload.setHeading(level: level))
                } label: {
                    HStack {
                        toolbarGlyph(headingIconKey(level), color: folderAccent)
                        Text("Notemark Option Heading Label \(level)")
                    }
                }
            }
        } label: {
            menuLabelIcon("heading", color: folderAccent)
        }
    }

    @ViewBuilder
    private static func textStyleMenu(folderAccent: Color, onDispatch: @escaping (String) -> Void) -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleBold)
            } label: {
                menuRow(icon: "text-bold", title: "Notemark Option Bold Label", folderAccent: folderAccent)
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleItalic)
            } label: {
                menuRow(icon: "text-italic", title: "Notemark Option Italic Label", folderAccent: folderAccent)
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleStrikethrough)
            } label: {
                menuRow(icon: "text-strikethrough", title: "Notemark Option Strikethrough Label", folderAccent: folderAccent)
            }
        } label: {
            menuLabelIcon("text-font", color: folderAccent)
        }
    }

    @ViewBuilder
    private static func insertMenu(
        folderAccent: Color,
        showGalleryPhotoPicker: Binding<Bool>,
        onDispatch: @escaping (String) -> Void,
        onRequestAddLinkSheet: @escaping (AddLinkSheetMode) -> Void,
        onRequestAddTableSheet: @escaping () -> Void,
        onRequestAddMentionSheet: @escaping () -> Void,
        onRequestPickImageFromCamera: @escaping () -> Void
    ) -> some View {
        Menu {
            Button(action: onRequestAddTableSheet) {
                menuRow(icon: "grid-table", title: "Notemark Option Add Table Label", folderAccent: folderAccent)
            }
            Button {
                onRequestAddLinkSheet(.link)
            } label: {
                menuRow(icon: "link-04", title: "Notemark Option Add Link Label", folderAccent: folderAccent)
            }
            Button(action: onRequestAddMentionSheet) {
                menuRow(icon: "at", title: "Notemark Option Add Mention Label", folderAccent: folderAccent)
            }
            Menu {
                #if !targetEnvironment(macCatalyst)
                Button(action: onRequestPickImageFromCamera) {
                    menuRow(icon: "camera-01", title: "Notemark Option Pick Image From Camera Label", folderAccent: folderAccent)
                }
                #endif
                Button {
                    showGalleryPhotoPicker.wrappedValue = true
                } label: {
                    menuRow(icon: "image-02", title: "Notemark Option Pick Image From Gallery Label", folderAccent: folderAccent)
                }
                Button {
                    onRequestAddLinkSheet(.image)
                } label: {
                    menuRow(icon: "link-04", title: "Notemark Option Add Image From Link Label", folderAccent: folderAccent)
                }
            } label: {
                menuRow(icon: "image-add-02", title: "Notemark Option Add Image Label", folderAccent: folderAccent)
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleCode)
                } label: {
                    menuRow(icon: "code", title: "Notemark Option Add Inline Code Label", folderAccent: folderAccent)
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleCodeBlock)
                } label: {
                    menuRow(icon: "source-code-square", title: "Notemark Option Add Code Block Label", folderAccent: folderAccent)
                }
            } label: {
                menuRow(icon: "source-code", title: "Notemark Option Add Code Label", folderAccent: folderAccent)
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.toggleQuote)
            } label: {
                menuRow(icon: "quote-down", title: "Notemark Option Add Blockquote Label", folderAccent: folderAccent)
            }
            Button {
                onDispatch(YabaEditorDispatchPayload.insertHr)
            } label: {
                menuRow(icon: "solid-line-01", title: "Notemark Option Add Horizontal Line Label", folderAccent: folderAccent)
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleBulletedList)
                } label: {
                    menuRow(icon: "left-to-right-list-bullet", title: "Notemark Option Add Unordered List Label", folderAccent: folderAccent)
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleNumberedList)
                } label: {
                    menuRow(icon: "left-to-right-list-number", title: "Notemark Option Add Ordered List Label", folderAccent: folderAccent)
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.toggleTaskList)
                } label: {
                    menuRow(icon: "check-list", title: "Notemark Option Add Task List Label", folderAccent: folderAccent)
                }
            } label: {
                menuRow(icon: "left-to-right-list-dash", title: "Notemark Option Add List Label", folderAccent: folderAccent)
            }
            Menu {
                Button {
                    onDispatch(YabaEditorDispatchPayload.insertInlineMathEmpty)
                } label: {
                    menuRow(icon: "absolute", title: "Notemark Option Add Inline Math Label", folderAccent: folderAccent)
                }
                Button {
                    onDispatch(YabaEditorDispatchPayload.insertBlockMathEmpty)
                } label: {
                    menuRow(icon: "alpha-square", title: "Notemark Option Add Block Math Label", folderAccent: folderAccent)
                }
            } label: {
                menuRow(icon: "calculator", title: "Notemark Option Add Math Label", folderAccent: folderAccent)
            }
        } label: {
            menuLabelIcon("add-01", color: folderAccent)
        }
    }

    @ViewBuilder
    private static func indentMenu(folderAccent: Color, onDispatch: @escaping (String) -> Void) -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.indent)
            } label: {
                menuRow(icon: "text-indent-more", title: "Notemark Option Add Indent Label", folderAccent: folderAccent)
            }
            .menuActionDismissBehavior(.disabled)
            Button {
                onDispatch(YabaEditorDispatchPayload.outdent)
            } label: {
                menuRow(icon: "text-indent-less", title: "Notemark Option Add Outdent Label", folderAccent: folderAccent)
            }
            .menuActionDismissBehavior(.disabled)
        } label: {
            menuLabelIcon("text-indent", color: folderAccent)
        }
    }

    @ViewBuilder
    private static func historyMenu(folderAccent: Color, onDispatch: @escaping (String) -> Void) -> some View {
        Menu {
            Button {
                onDispatch(YabaEditorDispatchPayload.undo)
            } label: {
                menuRow(icon: "undo-02", title: "Notemark Option Do Undo Label", folderAccent: folderAccent)
            }
            .menuActionDismissBehavior(.disabled)
            Button {
                onDispatch(YabaEditorDispatchPayload.redo)
            } label: {
                menuRow(icon: "redo-02", title: "Notemark Option Do Redo Label", folderAccent: folderAccent)
            }
            .menuActionDismissBehavior(.disabled)
        } label: {
            menuLabelIcon("repeat", color: folderAccent)
        }
    }

    // MARK: Pieces

    private static func menuRow(icon: String, title: LocalizedStringKey, folderAccent: Color) -> some View {
        HStack {
            toolbarGlyph(icon, color: folderAccent)
            Text(title)
        }
    }

    @ViewBuilder
    private static func menuLabelIcon(_ icon: String, color: Color) -> some View {
        toolbarGlyph(icon, color: color).padding()
    }

    private static func toolbarGlyph(_ icon: String, color: Color) -> some View {
        YabaIconView(bundleKey: icon)
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
    }

    private static func headingIconKey(_ level: Int) -> String {
        String(format: "heading-%02d", level)
    }
}
