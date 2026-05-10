//
//  PDFDocmarkDetailView.swift
//  YABA
//
//  PDF document rendering for docmark bookmarks (PDFKit viewer only).
//

import PDFKit
import SwiftUI

struct DocmarkPDFKitView: UIViewRepresentable {
    let pdfData: Data

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        guard context.coordinator.lastData != pdfData else { return }
        context.coordinator.lastData = pdfData
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true
    }

    final class Coordinator {
        var lastData: Data?
    }
}

struct PDFDocmarkDetailView: View {
    let pdfData: Data
    let folderTint: Color

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            if !pdfData.isEmpty {
                DocmarkPDFKitView(pdfData: pdfData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: [.top, .bottom])
            } else {
                ContentUnavailableView {
                    Label {
                        Text("Reader Not Available Title")
                    } icon: {
                        YabaIconView(bundleKey: "pdf-02")
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundStyle(folderTint)
                    }
                } description: {
                    Text("Reader Not Available Description")
                }
            }
        }
    }
}
