//
//  EPUBDocmarkDetailView.swift
//  YABA
//
//  EPUB document rendering using Readium ``EPUBNavigatorViewController`` (scroll-mode reflowable EPUB).
//

import ReadiumNavigator
import ReadiumShared
import SwiftUI

// MARK: - Readium preferences mapping

private extension EPUBPreferences {
    static func yabaMapped(
        readerTheme: ReaderTheme,
        colorScheme: ColorScheme,
        fontSize: ReaderFontSize,
        lineHeight: ReaderLineHeight
    ) -> EPUBPreferences {
        let readiumTheme: ReadiumNavigator.Theme = switch readerTheme {
        case .system:
            colorScheme == .dark ? .dark : .light
        case .light:
            .light
        case .dark:
            .dark
        case .sepia:
            .sepia
        }

        let fontMultiplier: Double = switch fontSize {
        case .small: 0.8
        case .medium: 1.2
        case .large: 1.6
        }

        let lineHeightValue: Double = switch lineHeight {
        case .normal: 1
        case .relaxed: 1.45
        }

        return EPUBPreferences(
            fontSize: fontMultiplier,
            lineHeight: lineHeightValue,
            publisherStyles: false,
            scroll: true,
            theme: readiumTheme
        )
    }
}

// MARK: - UIViewControllerRepresentable

struct EpubReadiumNavigatorRepresentable: UIViewControllerRepresentable {
    let publication: Publication
    var preferences: EPUBPreferences
    var tocBridge: EPUBDocmarkTOCBridge

    func makeCoordinator() -> Coordinator {
        Coordinator(tocBridge: tocBridge)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        do {
            let nav = try EPUBNavigatorViewController(
                publication: publication,
                initialLocation: nil,
                config: EPUBNavigatorViewController.Configuration(
                    preferences: preferences,
                    defaults: EPUBDefaults(),
                )
            )
            nav.delegate = context.coordinator
            nav.view.backgroundColor = .systemBackground
            context.coordinator.tocBridge.attach(navigator: nav)
            return nav
        } catch {
            let placeholder = UIViewController()
            placeholder.view.backgroundColor = .systemBackground
            context.coordinator.tocBridge.attach(navigator: nil)
            return placeholder
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let nav = uiViewController as? EPUBNavigatorViewController else {
            context.coordinator.tocBridge.attach(navigator: nil)
            return
        }
        nav.delegate = context.coordinator
        nav.submitPreferences(preferences)
        context.coordinator.tocBridge.attach(navigator: nav)
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if let nav = uiViewController as? EPUBNavigatorViewController {
            nav.delegate = nil
        }
        coordinator.tocBridge.attach(navigator: nil)
    }

    final class Coordinator: EPUBNavigatorDelegate {
        let tocBridge: EPUBDocmarkTOCBridge

        init(tocBridge: EPUBDocmarkTOCBridge) {
            self.tocBridge = tocBridge
        }
        /// Extra breathing room inside device / SwiftUI chrome so body text clears bars and toolbars.
        private static let innerPadding = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        func navigatorContentInset(_ navigator: VisualNavigator) -> UIEdgeInsets? {
            guard let epubVC = navigator as? EPUBNavigatorViewController else {
                return nil
            }
            
            let windowInsets = epubVC.view.window?.safeAreaInsets ?? .zero
            let viewInsets = epubVC.view.safeAreaInsets
            let top = max(windowInsets.top, viewInsets.top) + Self.innerPadding.top
            let bottom = max(windowInsets.bottom, viewInsets.bottom) + Self.innerPadding.bottom

            return UIEdgeInsets(
                top: top,
                left: Self.innerPadding.left,
                bottom: bottom,
                right: Self.innerPadding.right
            )
        }

        func navigator(_ navigator: Navigator, presentError error: NavigatorError) {}
    }
}

// MARK: - SwiftUI detail surface

struct EPUBDocmarkDetailView: View {
    let epubData: Data
    let folderTint: SwiftUI.Color

    @Bindable
    var machine: DocmarkDetailStateMachine

    let tocBridge: EPUBDocmarkTOCBridge

    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var loadState: LoadState = .idle

    private enum LoadState {
        case idle
        case loading
        case ready(publication: Publication, tempURL: URL)
        case failed
    }

    var body: some View {
        ZStack {
            BookmarkDetailReaderChrome.readerSurfaceBackground(readerTheme: machine.state.epubReaderTheme)
                .ignoresSafeArea()

            switch loadState {
            case .idle, .loading:
                ProgressView()
                    .tint(folderTint)
            case let .ready(publication, _):
                EpubReadiumNavigatorRepresentable(
                    publication: publication,
                    preferences: EPUBPreferences.yabaMapped(
                        readerTheme: machine.state.epubReaderTheme,
                        colorScheme: colorScheme,
                        fontSize: machine.state.epubReaderFontSize,
                        lineHeight: machine.state.epubReaderLineHeight
                    ),
                    tocBridge: tocBridge
                )
                .ignoresSafeArea(edges: [.top, .bottom])
            case .failed:
                BookmarkDetailReaderChrome.readerUnavailablePlaceholder(
                    iconBundleKey: "book-bookmark-02",
                    tint: folderTint
                )
            }
        }
        .preferredColorScheme(
            BookmarkDetailReaderChrome.preferredColorScheme(
                readerTheme: machine.state.epubReaderTheme,
                userInterfaceColorScheme: colorScheme
            )
        )
        .task(id: epubData) {
            await openPublicationIfNeeded()
        }
        .onDisappear {
            tearDownLoadedPublication(deleteFile: true)
            tocBridge.resetForUnload()
        }
    }

    private func tearDownLoadedPublication(deleteFile: Bool) {
        if case let .ready(_, url) = loadState, deleteFile {
            try? FileManager.default.removeItem(at: url)
        }
        if case .ready = loadState {
            tocBridge.setPublication(nil)
            loadState = .idle
        }
    }

    private func openPublicationIfNeeded() async {
        guard !epubData.isEmpty else {
            tearDownLoadedPublication(deleteFile: true)
            tocBridge.setPublication(nil)
            loadState = .failed
            return
        }

        tearDownLoadedPublication(deleteFile: true)
        tocBridge.setPublication(nil)

        loadState = .loading

        guard let result = await EPUBPublicationOpening.openPublication(fromEPUBData: epubData) else {
            loadState = .failed
            tocBridge.setPublication(nil)
            return
        }

        tocBridge.setPublication(result.publication)
        loadState = .ready(publication: result.publication, tempURL: result.tempFileURL)
    }
}
