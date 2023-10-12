import CoreImage
import Foundation
import PDFKit

class Document {

  enum DocumentType {
    case pdf
    case image
  }

  private var id: Int
  private var type: DocumentType
  private var pageCount: Int?
  private var documentURL: URL?
  private var pdfDocument: PDFDocument?
  private var grayscale: Bool
  private var newWidth: CGFloat
  private var incomingPath: String

  init?(id: Int, path: String, grayscale: Bool, newWidth: CGFloat){
    self.id = id
    self.incomingPath = path
    self.documentURL = URL(string: path)
    let documentExtension = path.components(separatedBy: ".").last
    switch documentExtension {
    case "pdf", "PDF":
      self.type = .pdf
      if let url = self.documentURL, let pdfDocument = PDFDocument(url: url) {
        self.pdfDocument = pdfDocument
        self.pageCount = pdfDocument.pageCount
      }
    case "jpg", "JPG", "jpeg", "JPEG", "heic","HEIC", "png", "PNG":
      self.type = .image
      self.pageCount = 1
    default:
      return nil
    }
    self.grayscale = grayscale
    self.newWidth = newWidth
  }

  func process(completion: @escaping (([String]?) -> Void)) {
    guard let documentURL = documentURL else { return }
    switch type {
    case .image:
      guard let image = loadImage(fileURL: documentURL) else { return }
      var resultImage = scalePreservingAspectRatio(image, newWidth: newWidth)
      if grayscale, let image = grayscale(resultImage) {
        resultImage = image
      }
      if let fileNameWithExt = incomingPath.components(separatedBy: "/").last,
         let fileNameRaw = fileNameWithExt.components(separatedBy: ".").first {
        let newPathComponent = fileNameRaw + "_" + "resized" + ".png"
        let fileURL = getDocumentsDirectory().appendingPathComponent(newPathComponent)

        if let pngData = resultImage.pngData(), let _ = try? pngData.write(to: fileURL) {
          completion([fileURL.absoluteString])
        }
      }
    case .pdf:
      convertToImagesAndSave(pdfURL: documentURL) { result in
        completion(result)
      }
    }
  }
}

// MARK: Helpers Methods

extension Document {

  private func convertToImagesAndSave(pdfURL: URL, completion: @escaping (([String]?) -> Void)) {
    guard let pdfDocument = PDFDocument(url: pdfURL),
          let fileNameWithExt = incomingPath.components(separatedBy: "/").last,
          let fileNameRaw = fileNameWithExt.components(separatedBy: ".").first else {
      completion(nil)
      return
    }
    let documentsDirectoryURL = getDocumentsDirectory()
    var outcomingPath: [String] = []

    let dispatchGroup = DispatchGroup()
    for pageIndex in 0..<pdfDocument.pageCount {
      dispatchGroup.enter()
      autoreleasepool {
        if let pdfPage = pdfDocument.page(at: pageIndex) {
          let pdfPageSize = pdfPage.bounds(for: .mediaBox)

          let format = UIGraphicsImageRendererFormat()
          format.scale = 1

          let renderer = UIGraphicsImageRenderer(size: pdfPageSize.size, format: format)

          var image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pdfPageSize)
            ctx.cgContext.translateBy(x: 0.0, y: pdfPageSize.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            pdfPage.draw(with: .mediaBox, to: ctx.cgContext)
          }

          image = scalePreservingAspectRatio(image, newWidth: newWidth)
          if grayscale, let grayImage = grayscale(image) {
            image = grayImage
          }
          let newPathComponent = fileNameRaw + "_" + "\(pageIndex)_" + "resized" + ".png"
          let fileURL = documentsDirectoryURL.appendingPathComponent(newPathComponent)
          if let pngData = image.pngData(), let _ = try? pngData.write(to: fileURL) {
            outcomingPath.append(fileURL.absoluteString)
            dispatchGroup.leave()
          }
        }
      }
    }

    dispatchGroup.notify(queue: .global(qos: .background)) {
      completion(outcomingPath)
    }
  }

  private func loadImage(fileURL: URL) -> UIImage? {
    do {
      let imageData = try Data(contentsOf: fileURL)
      return UIImage(data: imageData)
    } catch {
      print("RNDocumentsHandler: Error loading image : \(error)")
    }
    return nil
  }

  private func grayscale(_ image: UIImage) -> UIImage? {
    let context = CIContext(options: nil)
    if let filter = CIFilter(name: "CIPhotoEffectNoir") {
      filter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
      if let output = filter.outputImage {
        if let cgImage = context.createCGImage(output, from: output.extent) {
          return UIImage(cgImage: cgImage)
        }
      }
    }
    return nil
  }

  private func scalePreservingAspectRatio(_ image: UIImage, newWidth: CGFloat) -> UIImage {
    let scaleFactor = newWidth / image.size.width
    let scaledImageSize = CGSize(
      width: newWidth,
      height: image.size.height * scaleFactor
    )
    let renderer = UIGraphicsImageRenderer(
      size: scaledImageSize
    )

    let scaledImage = renderer.image { _ in
      image.draw(in: CGRect(
        origin: .zero,
        size: scaledImageSize
      ))
    }
    return scaledImage
  }

  private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
}
