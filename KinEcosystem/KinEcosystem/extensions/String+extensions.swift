//
//  String+localized.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 08/10/2018.
//

import Foundation


public extension String {
    
    enum JwtJSONDecodeError: Error {
        case invalidParts
        case invalidBase64Url
        case invalidJSON
    }
    
    func localized(_ fallback:String = "") -> String {
        let path = "./\(Locale(identifier: Locale.preferredLanguages.first!).identifier).lproj/Localizable"
        let a = NSLocalizedString(self, tableName:path, bundle: KinBundle.localization.rawValue, value: "", comment: "")
        let b = NSLocalizedString(self, tableName: "./en.lproj/Localizable", bundle: KinBundle.localization.rawValue, value: fallback, comment: "")
        return a != self ? a : b
    }
    
    func jwtJson() throws -> [String: Any] {
        let jwtComponents = components(separatedBy: ".")
        guard jwtComponents.count == 3 else {
            throw JwtJSONDecodeError.invalidParts
        }
        return ["header": try decodeJWTComponent(jwtComponents[0]),
                "body": try decodeJWTComponent(jwtComponents[1])]
    }
    
    private func decodeBase64(_ url: String) -> Data? {
        var base64 = url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    
    private func decodeJWTComponent(_ value: String) throws -> [String: Any] {
        guard let bodyData = decodeBase64(value) else {
            throw JwtJSONDecodeError.invalidBase64Url
        }
        
        guard   let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
            let payload = json as? [String: Any] else {
                throw JwtJSONDecodeError.invalidJSON
        }
        
        return payload
    }
}
