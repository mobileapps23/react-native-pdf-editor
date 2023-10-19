//
//  ContainerView.swift
//  react-native-pdf-editor
// 

import Foundation
import PDFKit
import UIKit

@objc(ContainerView)
class ContainerView: UIView {

    enum CanvasType: String {
        case pdf
        case image
    }

    @objc var pdfView: NonSelectablePDFView!

    @objc var options: [String: Any] = [:] {
        didSet {
            updateWithOptions(options)
        }
    }

    @objc var onSave: RCTDirectEventBlock?
    @objc var onError: RCTDirectEventBlock?

    private var toolBarView: ToolBarView!
    private let pdfDrawer = PDFDrawer()
    private var filePath: [String] = []
    private var canvasType: CanvasType = .pdf

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("RNPDFEditor: init(coder:) has not been implemented")
    }

    private func setupView() {
        let toolBarView = ToolBarView()
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.delegate = self
        toolBarView.isHidden = true

        let pdfView = NonSelectablePDFView()
        pdfView.backgroundColor = .lightGray
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        pdfView.autoScales = true
        pdfView.isHidden = true

        let stackView = UIStackView(arrangedSubviews: [toolBarView, pdfView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill

        self.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            self.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            toolBarView.heightAnchor.constraint(equalToConstant: 40),

            stackView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
            self.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])

        self.pdfView = pdfView
        self.toolBarView = toolBarView
    }

    private func updateWithOptions(_ options: [String: Any]) {

        if let canvasType = options["canvasType"] as? String {
            if canvasType == CanvasType.pdf.rawValue {
                self.canvasType = .pdf
            } else if canvasType == CanvasType.image.rawValue {
                self.canvasType = .image
            }
        } else {
            print("RNPDFEditor: \"fileName\" value is wrong")
        }

        if let filePath = options["filePath"] as? [String], !filePath.isEmpty, let firstPath = filePath.first {
            self.filePath = filePath
            switch canvasType {
            case .image:
                loadImage(for: filePath)
            case .pdf:
                loadPDF(for: firstPath)
            }
        } else {
            print("RNPDFEditor: \"filePath\" value is wrong or empty")
        }

        if let isHidden = options["isToolBarHidden"] as? Bool {
            toolBarView.isHidden = isHidden
        } else {
            print("RNPDFEditor: \"isToolBarHidden\" value is wrong")
        }

        if let pdfViewBackgroundColor = options["viewBackgroundColor"] as? String {
            pdfView.backgroundColor  = UIColor(hexString: pdfViewBackgroundColor)
        } else {
            print("RNPDFEditor: \"pdfViewBackgroundColor\" value is wrong")
        }

        if let lineColor = options["lineColor"] as? String {
            pdfDrawer.color = UIColor(hexString: lineColor)
        } else {
            print("RNPDFEditor: \"lineColor\" value is wrong")
        }

        if let lineWidth = options["lineWidth"] as? Float {
            pdfDrawer.width = CGFloat(lineWidth)
        } else {
            print("RNPDFEditor: \"lineWidth\" value is wrong")
        }

    }

    private func loadPDF(for pathString: String) {
        guard let url = URL(string: pathString) else {
            print("RNPDFEditor: can't create URL from string")
            return
        }
        if let document = PDFDocument(url: url) {
            self.pdfView.isHidden = false
            self.pdfView.drawingDelegate = pdfDrawer
            self.pdfView.document = document
            self.pdfView.disableSelection(in: self.pdfView)

            self.pdfDrawer.pdfView = pdfView
        } else {
            print("RNPDFEditor: can't create PDF document from URL")
        }
    }

    private func loadImage(for arrayOfPathStrings: [String]) {
        let document = PDFDocument()
        for (index, value) in arrayOfPathStrings.enumerated() {
            let url = URL(fileURLWithPath: value)
            if let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                let pdfPage = PDFPage(image: image)
                document.insert(pdfPage!, at: index)
            } else {
                print("RNPDFEditor: can't create Image from URL", url)
            }
        }

        if document.pageCount > 0 {
            self.pdfView.isHidden = false
            self.pdfView.drawingDelegate = pdfDrawer
            self.pdfView.document = document
            self.pdfView.disableSelection(in: self.pdfView)

            self.pdfDrawer.pdfView = pdfView
        } else {
            print("RNPDFEditor: no images to show")
        }
    }

    private func savePDF() {
        guard let onSave = self.onSave else {
            print("RNPDFEditor: onSave is nil, can't return value")
            return
        }

        var params: [String : [String?]?] = ["url" : nil]

        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"

        if let filePath = filePath.first,  let fileNameWithExt = filePath.components(separatedBy: "/").last,
           let fileNameRaw = fileNameWithExt.components(separatedBy: ".").first {
            let newPathComponent = fileNameRaw + "_" + formatter.string(from: today) + ".pdf"
            let fileURL = getDocumentsDirectory().appendingPathComponent(newPathComponent)

            guard let document = pdfView.document,
                  let page = document.page(at: 0) else {
                print("RNPDFEditor: PDF not writed locally")
                onSave(params as [AnyHashable : Any])
                return
            }
            let bounds = page.bounds(for: .cropBox)

            let renderer = UIGraphicsImageRenderer(bounds: bounds, format: UIGraphicsImageRendererFormat.default())

            let image = renderer.image { (context) in
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: bounds.height)
                context.cgContext.concatenate(CGAffineTransform.init(scaleX: 1, y: -1))
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }

            let newPage = PDFPage(image: image)!

            for annotation in page.annotations {
                newPage.addAnnotation(annotation)
            }

            document.insert(newPage, at: 0)
            document.removePage(at: 1)

            document.write(to: fileURL)

            params["url"] = [fileURL.absoluteString]
            onSave(params as [AnyHashable : Any])
        } else {
            print("RNPDFEditor: can't handle URL")
            onSave(params as [AnyHashable : Any])
        }
    }

    private func saveImage() {
        guard let onSave = self.onSave, let document = pdfView.document else {
            print("RNPDFEditor: error while saving image, onSave is nil, can't return value")
            return
        }

        var params: [String : [String?]?] = ["url" : nil]
        var resultArray: [String] = []

        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"

        for (index, value) in filePath.enumerated() {
            if let fileNameWithExt = value.components(separatedBy: "/").last,
               let fileNameRaw = fileNameWithExt.components(separatedBy: ".").first {
                let newPathComponent = fileNameRaw + "_" + formatter.string(from: today) + ".png"
                let fileURL = getDocumentsDirectory().appendingPathComponent(newPathComponent)
                guard let page = document.page(at: index) else {
                    print("RNPDFEditor: image at path \(value) not writed locally")
                    onSave(params as [AnyHashable : Any])
                    return
                }
                let bounds = page.bounds(for: .cropBox)

                let renderer = UIGraphicsImageRenderer(bounds: bounds, format: UIGraphicsImageRendererFormat.default())

                let image = renderer.image { (context) in
                    context.cgContext.saveGState()
                    context.cgContext.translateBy(x: 0, y: bounds.height)
                    context.cgContext.concatenate(CGAffineTransform.init(scaleX: 1, y: -1))
                    page.draw(with: .mediaBox, to: context.cgContext)
                    context.cgContext.restoreGState()
                }

                if let data = image.pngData() {
                    do {
                        try data.write(to: fileURL)
                        resultArray.append(fileURL.absoluteString)
                    } catch {
                        print("RNPDFEditor: can't create image for saving")
                        onSave(params as [AnyHashable : Any])
                        return
                    }
                }
            }

        }

        if !resultArray.isEmpty {
            params["url"] = resultArray
            onSave(params as [AnyHashable : Any])
        } else {
            print("RNPDFEditor: can't handle URLs")
            onSave(params as [AnyHashable : Any])
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

extension ContainerView: ToolBarViewDelegate {

    func undoButtonTapped() {
        pdfDrawer.undo()
    }

    func clearButtonTapped() {
        pdfDrawer.clear()
    }

    func saveButtonTapped() {
        canvasType == .image ? self.saveImage() : self.savePDF()
    }
}
