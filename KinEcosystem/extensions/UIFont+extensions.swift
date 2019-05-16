//
//  UIFont+extensions.swift
//  Base64
//
//  Created by Elazar Yifrach on 16/05/2019.
//



extension UIFont {
    
    class func loadFonts(from bundle: Bundle) {
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundle.bundlePath)
            contents.filter{ $0.contains(".otf") }.forEach { file in
                var fontError: Unmanaged<CFError>?
                let fontFileURL = bundle.bundleURL.appendingPathComponent(file)
                if  let fontData = try? Data(contentsOf: fontFileURL) as CFData,
                    let dataProvider = CGDataProvider(data: fontData) {
                    _ = UIFont()
                    let fontRef = CGFont(dataProvider)
                    if CTFontManagerRegisterGraphicsFont(fontRef!, &fontError) {
                        if let postScriptName = fontRef?.postScriptName {
                            print("Successfully loaded font: \(postScriptName).")
                        }
                    } else if let fontError = fontError?.takeRetainedValue() {
                        let errorDescription = CFErrorCopyDescription(fontError)
                        print("Failed to load font \(file): \(String(describing: errorDescription))")
                    }
                } else {
                    guard let fontError = fontError?.takeRetainedValue() else {
                        print("Failed to load font \(file).")
                        return
                    }
                    let errorDescription = CFErrorCopyDescription(fontError)
                    print("Failed to load font \(file): \(String(describing: errorDescription))")
                }
            }
        } catch let error as NSError {
            print("Error while loading fonts: \(String(describing: error))")
        }
        
    }
}
