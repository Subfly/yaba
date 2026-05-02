//
//  CanvmarkEditorFloatingToolbar.swift
//  YABA
//

import PhotosUI
import SwiftUI

/// Floating toolbar for the canvas editor (structure only — actions wire to the web host later).
struct CanvmarkEditorFloatingToolbar: View {
    let folderAccent: Color
    let isVisible: Bool
    let onTool: (CanvmarkToolbarTool) -> Void
    let onRequestAddLinkSheet: (AddLinkSheetMode) -> Void
    let onRequestAddMentionSheet: () -> Void
    let onRequestPickImageFromCamera: () -> Void
    var galleryPhotoItem: Binding<PhotosPickerItem?>
    let onUndo: () -> Void
    let onRedo: () -> Void

    @State
    private var showGalleryPhotoPicker = false

    enum CanvmarkToolbarTool: Sendable {
        case selectionMode
        case handMode
        case paintBrush
        case deleteSelection
        case lineTool
        case arrowTool
        case addText
        case addFrame
        case shapeCircle
        case shapeDiamond
        case shapeSquare
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 18) {
                    toolbarRow
                }
                .glassEffect(.regular.interactive())
            } else {
                toolbarRow
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
    private var toolbarRow: some View {
        HStack(spacing: 0) {
            cursorToolMenu()
            paintBrushButton()
            deleteToolButton()
            lineArrowMenu()
            addMenu()
            historyMenu()
        }
    }

    @ViewBuilder
    private func cursorToolMenu() -> some View {
        Menu {
            Button {
                onTool(.selectionMode)
            } label: {
                menuRow(icon: "cursor-rectangle-selection-01", title: "Canvmark Option Selection Label")
            }
            Button {
                onTool(.handMode)
            } label: {
                menuRow(icon: "drag-04", title: "Canvmark Option Hand Label")
            }
        } label: {
            menuLabelIcon("cursor-02", color: folderAccent)
        }
    }

    @ViewBuilder
    private func paintBrushButton() -> some View {
        Button {
            onTool(.paintBrush)
        } label: {
            menuLabelIcon("paint-brush-01", color: folderAccent)
        }
        .accessibilityLabel(Text("Canvmark Option Selection Label"))
    }

    @ViewBuilder
    private func deleteToolButton() -> some View {
        Button {
            onTool(.deleteSelection)
        } label: {
            menuLabelIcon("eraser", color: folderAccent)
        }
        .accessibilityLabel(Text("Canvmark Option Delete Label"))
    }

    @ViewBuilder
    private func lineArrowMenu() -> some View {
        Menu {
            Button {
                onTool(.lineTool)
            } label: {
                menuRow(icon: "arrow-left-right-round", title: "Canvmark Option Line Label")
            }
            Button {
                onTool(.arrowTool)
            } label: {
                menuRow(icon: "arrow-up-right-01", title: "Canvmark Option Arrow Label")
            }
        } label: {
            menuLabelIcon("arrow-left-right-round", color: folderAccent)
        }
    }

    @ViewBuilder
    private func addMenu() -> some View {
        Menu {
            Button {
                onTool(.addText)
            } label: {
                menuRow(icon: "text", title: "Canvmark Option Add Text Label")
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
            Button {
                onTool(.addFrame)
            } label: {
                menuRow(icon: "dashed-line-02", title: "Canvmark Option Add Frame Label")
            }
            Menu {
                Button {
                    onTool(.shapeCircle)
                } label: {
                    menuRow(icon: "circle", title: "Canvmark Option Add Cricle Shape Label")
                }
                Button {
                    onTool(.shapeDiamond)
                } label: {
                    menuRow(icon: "diamond", title: "Canvmark Option Add Diamond Shape Label")
                }
                Button {
                    onTool(.shapeSquare)
                } label: {
                    menuRow(icon: "square", title: "Canvmark Option Add Square Shape Label")
                }
            } label: {
                menuRow(icon: "shapes", title: "Canvmark Option Add Shape Label")
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
        } label: {
            menuLabelIcon("add-01", color: folderAccent)
        }
    }

    @ViewBuilder
    private func historyMenu() -> some View {
        Menu {
            Button {
                onUndo()
            } label: {
                menuRow(icon: "undo-02", title: "Notemark Option Do Undo Label")
            }
            Button {
                onRedo()
            } label: {
                menuRow(icon: "redo-02", title: "Notemark Option Do Redo Label")
            }
        } label: {
            menuLabelIcon("repeat", color: folderAccent)
        }
    }

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
}
