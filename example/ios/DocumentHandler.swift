import Foundation
import React

@objc(DocumentsHandler)
class DocumentsHandler: NSObject {

  @objc
    static func requiresMainQueueSetup() -> Bool {
      return false //class can be initialized on a background thread
    }

  @objc
    func process(_ data: NSDictionary,  resolver resolve: @escaping RCTPromiseResolveBlock,  rejecter reject: @escaping RCTPromiseRejectBlock) {
      guard let arrayOfPaths = data["documents"] as? [String] else {
        reject("RNDocumentsHandler", "\"arrayOfPaths\" value is wrong", nil)
        return
      }
      guard let expectedWidth = data["expectedWidth"] as? Float else {
        reject("RNDocumentsHandler", "\"expectedWidth\" value is wrong", nil)
        return
      }
      guard let grayscale = data["grayscale"] as? Bool else {
        reject("RNDocumentsHandler", "\"grayscale\" value is wrong", nil)
        return
      }

      print(arrayOfPaths)
      print(expectedWidth)
      print(grayscale)

      resolve(["documents": arrayOfPaths])
    }
}
