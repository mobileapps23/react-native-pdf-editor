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
//          guard let id = data["id"] as? String,
//                  let verificationCode = data["verificationCode"] as? String else {
//        reject("PACKAGE_NOT_FOUND", "Id and Verification code didn't match a package", nil)
//
//        return
//      }
//      reject("PACKAGE_NOT_FOUND", "Id and Verification code didn't match a package", nil)
//      return

//print("WILL BE RESOLVED")
//      resolve(["request": "SOME STRING", "distance": "SOME STRING", "status": "SOME STRING"])
    }

}
