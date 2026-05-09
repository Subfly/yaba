//
//  ShareViewController.swift
//  YABAShareMac
//

import AppKit
import SwiftUI

@objc(ShareViewController)
final class ShareViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        Task { await handleIncomingShare() }
    }

    private func handleIncomingShare() async {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        guard let payload = await BookmarkSharePayloadExtractor.firstPayload(from: extensionItems) else {
            close()
            return
        }

        await MainActor.run {
            let launch = BookmarkShareLaunchBuilder.formLaunch(for: payload)
            presentCreationView(launch: launch)
        }
    }

    @MainActor
    private func presentCreationView(launch: BookmarkKindFormLaunch) {
        let host = NSHostingController(
            rootView: BookmarkKindCreationSheet(launch: launch, onDone: close, onCloseRequest: close)
                .modelContext(try! ParityModelContainer.makeContext())
        )
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }

    @MainActor
    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
