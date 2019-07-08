//
//  UIColor+variations.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/05/2019.
//

extension Color {
    
    func adjustBrightness(_ percentage: CGFloat) -> Color {
        let converted = hsba
        return UIColor(hue: converted.hue, saturation: converted.saturation, brightness: min(1.0, converted.brightness * (1.0 + percentage)), alpha: converted.alpha)
    }
    
    func grayed() -> UIColor {
        let converted = hsba
        return UIColor(hue: converted.hue, saturation: 0.0, brightness: converted.brightness, alpha: converted.alpha)
    }
    
    var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return (hue, saturation, brightness, alpha)
        }
        return (0,0,0,0)
    }
    
}
