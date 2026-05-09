//
//  EPUBDocmarkDetailView.swift
//  YABA
//
//  EPUB document rendering using Readium ``EPUBNavigatorViewController`` (scroll-mode reflowable EPUB).
//

import ReadiumNavigator
import ReadiumShared
import SwiftUI
import UIKit

// MARK: - Toolbar navigation bridge

@MainActor
final class EpubNavigatorNavigationCoordinator {
    weak var navigator: EPUBNavigatorViewController?

    func goForward() async {
        _ = await navigator?.goForward()
    }

    func goBackward() async {
        _ = await navigator?.goBackward()
    }
}

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
    var navigationCoordinator: EpubNavigatorNavigationCoordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(navigationCoordinator: navigationCoordinator)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        navigationCoordinator.navigator = nil
        do {
            let nav = try EPUBNavigatorViewController(
                publication: publication,
                initialLocation: nil,
                config: EPUBNavigatorViewController.Configuration(
                    preferences: preferences,
                    defaults: EPUBDefaults(),
                    disablePageTurnsWhileScrolling: true
                )
            )
            navigationCoordinator.navigator = nav
            nav.delegate = context.coordinator
            nav.view.backgroundColor = .systemBackground
            return nav
        } catch {
            let placeholder = UIViewController()
            placeholder.view.backgroundColor = .systemBackground
            return placeholder
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let nav = uiViewController as? EPUBNavigatorViewController else { return }
        navigationCoordinator.navigator = nav
        nav.delegate = context.coordinator
        nav.submitPreferences(preferences)
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if let nav = uiViewController as? EPUBNavigatorViewController {
            nav.delegate = nil
        }
        coordinator.navigationCoordinator.navigator = nil
    }

    final class Coordinator: EPUBNavigatorDelegate {
        let navigationCoordinator: EpubNavigatorNavigationCoordinator

        init(navigationCoordinator: EpubNavigatorNavigationCoordinator) {
            self.navigationCoordinator = navigationCoordinator
        }

        /// Extra breathing room inside device / SwiftUI chrome so body text clears bars and toolbars.
        private static let innerPadding = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        func navigatorContentInset(_ navigator: VisualNavigator) -> UIEdgeInsets? {
            guard let epubVC = navigator as? EPUBNavigatorViewController else {
                return nil
            }

            let windowInsets = epubVC.view.window?.safeAreaInsets ?? .zero
            let viewInsets = epubVC.view.safeAreaInsets
            let merged = UIEdgeInsets(
                top: max(windowInsets.top, viewInsets.top),
                left: max(windowInsets.left, viewInsets.left),
                bottom: max(windowInsets.bottom, viewInsets.bottom),
                right: max(windowInsets.right, viewInsets.right)
            )

            return UIEdgeInsets(
                top: merged.top + Self.innerPadding.top,
                left: merged.left + Self.innerPadding.left,
                bottom: merged.bottom + Self.innerPadding.bottom,
                right: merged.right + Self.innerPadding.right
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

    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var loadState: LoadState = .idle

    @State
    private var navigationCoordinator = EpubNavigatorNavigationCoordinator()

    private enum LoadState {
        case idle
        case loading
        case ready(publication: Publication, tempURL: URL)
        case failed
    }

    var body: some View {
        ZStack {
            epubReaderBackground(readerTheme: machine.state.epubReaderTheme)
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
                    navigationCoordinator: navigationCoordinator
                )
                .ignoresSafeArea(edges: .all)
            case .failed:
                ContentUnavailableView {
                    Label {
                        Text("Reader Not Available Title")
                    } icon: {
                        YabaIconView(bundleKey: "book-bookmark-02")
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundStyle(folderTint)
                    }
                } description: {
                    Text("Reader Not Available Description")
                }
            }
        }
        .preferredColorScheme(effectiveReaderColorScheme(readerTheme: machine.state.epubReaderTheme))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if case .ready = loadState {
                HStack {
                    Spacer(minLength: 0)
                    EpubDocmarkReaderToolbar(
                        folderAccent: folderTint,
                        readerTheme: machine.state.epubReaderTheme,
                        readerFontSize: machine.state.epubReaderFontSize,
                        readerLineHeight: machine.state.epubReaderLineHeight,
                        onPrevious: {
                            Task { await navigationCoordinator.goBackward() }
                        },
                        onNext: {
                            Task { await navigationCoordinator.goForward() }
                        },
                        onSelectTheme: { t in
                            Task { await machine.send(.onSetEpubReaderTheme(t)) }
                        },
                        onSelectFontSize: { f in
                            Task { await machine.send(.onSetEpubReaderFontSize(f)) }
                        },
                        onSelectLineHeight: { lh in
                            Task { await machine.send(.onSetEpubReaderLineHeight(lh)) }
                        }
                    )
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 8)
            }
        }
        .task(id: epubData) {
            await openPublicationIfNeeded()
        }
        .onDisappear {
            tearDownLoadedPublication(deleteFile: true)
        }
    }

    private func epubReaderBackground(readerTheme: ReaderTheme) -> SwiftUI.Color {
        if readerTheme == .sepia {
            Color(red: 0.98, green: 0.95, blue: 0.88)
        } else {
            Color(.systemBackground)
        }
    }

    private func effectiveReaderColorScheme(readerTheme: ReaderTheme) -> ColorScheme {
        switch readerTheme {
        case .light, .sepia:
            return .light
        case .dark:
            return .dark
        case .system:
            return colorScheme
        }
    }

    private func tearDownLoadedPublication(deleteFile: Bool) {
        if case let .ready(_, url) = loadState, deleteFile {
            try? FileManager.default.removeItem(at: url)
        }
        if case .ready = loadState {
            loadState = .idle
        }
    }

    private func openPublicationIfNeeded() async {
        guard !epubData.isEmpty else {
            tearDownLoadedPublication(deleteFile: true)
            loadState = .failed
            return
        }

        tearDownLoadedPublication(deleteFile: true)

        loadState = .loading

        guard let result = await EpubPublicationOpening.openPublication(fromEPUBData: epubData) else {
            loadState = .failed
            return
        }

        loadState = .ready(publication: result.publication, tempURL: result.tempFileURL)
    }
}
