//
//  Util.swift
//  LottieInVideo
//
//  Created by lvpengwei on 2018/12/15.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import UIColor_Hex_Swift

class Util {
    class var screenWidth: CGFloat {
        get {
            return UIScreen.main.bounds.width
        }
    }
    class var screenHeight: CGFloat {
        get {
            return UIScreen.main.bounds.height
        }
    }
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
    
    static func timeStringMMSS(duration: TimeInterval) -> String {
        return formatter.string(from: Date(timeIntervalSince1970: max(0, duration)))
    }
}

extension UIFont {
    
    class func xdFont(ofSize: CGFloat) -> UIFont {
        if let font = UIFont(name: "PingFangSC-Regular", size: ofSize) {
            return font
        }
        return UIFont.systemFont(ofSize: ofSize, weight: UIFont.Weight.regular)
    }
    
    class func lightXDFont(ofSize: CGFloat) -> UIFont {
        if let font = UIFont(name: "PingFangSC-Light", size: ofSize) {
            return font
        }
        return UIFont.systemFont(ofSize: ofSize, weight: UIFont.Weight.light)
    }
    
    class func boldXDFont(ofSize: CGFloat) -> UIFont {
        if let font = UIFont(name: "PingFangSC-Semibold", size: ofSize) {
            return font
        }
        return UIFont.systemFont(ofSize: ofSize, weight: UIFont.Weight.semibold)
    }
    
}

extension UIColor {
    
    class var xd_262626: UIColor {
        get {
            return UIColor.init(hex6: 0x262626)
        }
    }
    
    class var xd_00b1f7: UIColor {
        get {
            return UIColor.init(hex6: 0x00b1f7)
        }
    }
    
    class var xd_bcc1cc: UIColor {
        get {
            return UIColor.init(hex6: 0xbcc1cc)
        }
    }
    
    class var xd_e76464: UIColor {
        get {
            return UIColor.init(hex6: 0xe76464)
        }
    }
    
    class var xd_333333: UIColor {
        get {
            return UIColor.init(hex6: 0x333333)
        }
    }
    
    class var xd_efeff4: UIColor {
        get {
            return UIColor.init(hex6: 0xefeff4)
        }
    }
    
    class var xd_666666: UIColor {
        get {
            return UIColor.init(hex6: 0x666666)
        }
    }
    
    class var xd_fafafa: UIColor {
        get {
            return UIColor.init(hex6: 0xfafafa)
        }
    }
    
    class var xd_e9e9e9: UIColor {
        get {
            return UIColor.init(hex6: 0xe9e9e9)
        }
    }
    
    class var xd_ff981e: UIColor {
        get {
            return UIColor.init(hex6: 0xff981e)
        }
    }
    
    class var xd_555555: UIColor {
        get {
            return UIColor.init(hex6: 0x555555)
        }
    }
    
    class var xd_161616: UIColor {
        get {
            return UIColor.init(hex6: 0x161616)
        }
    }
    
    class var xd_8c8c8c: UIColor {
        get {
            return UIColor.init(hex6: 0x8c8c8c)
        }
    }
    
    class var xd_111111: UIColor {
        get {
            return UIColor.init(hex6: 0x111111)
        }
    }
    
    class var xd_19171a: UIColor {
        get {
            return UIColor.init(hex6: 0x19171a)
        }
    }
    
    class var xd_03a9f4: UIColor {
        get {
            return UIColor.init(hex6: 0x03a9f4)
        }
    }
    
    class var xd_999999: UIColor {
        get {
            return UIColor.init(hex6: 0x999999)
        }
    }
    
    class var xd_ff8080: UIColor {
        get {
            return UIColor.init(hex6: 0xff8080)
        }
    }
    
    class var xd_ff5050: UIColor {
        get {
            return UIColor.init(hex6: 0xff5050)
        }
    }
    
    class var xd_e5e6e8: UIColor {
        get {
            return UIColor.init(hex6: 0xe5e6e8)
        }
    }
    
    class var xd_878787: UIColor {
        get {
            return UIColor.init(hex6: 0x878787)
        }
    }
    
    class var xd_eaebed: UIColor {
        get {
            return UIColor.init(hex6: 0xeaebed)
        }
    }
    
    class var xd_eeeeee: UIColor {
        get {
            return UIColor.init(hex6: 0xeeeeee)
        }
    }
    
    class var xd_cccccc: UIColor {
        get {
            return UIColor.init(hex6: 0xcccccc)
        }
    }
    
    class var xd_383838: UIColor {
        get {
            return UIColor.init(hex6: 0x383838)
        }
    }
    
    // 编辑器 button 禁用状态的颜色
    class var xd_ve_btn_disabled: UIColor {
        return xd_333333
    }
    
    func image() -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(cgColor)
            context.fill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    class var iosAzure: UIColor {
        return UIColor(red: 3.0 / 255.0, green: 169.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
    }
    class var iosGrapefruit: UIColor {
        return UIColor(red: 255.0 / 255.0, green: 80.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)
    }
    class var iosPaleGrey: UIColor {
        return UIColor(red: 234.0 / 255.0, green: 235.0 / 255.0, blue: 237.0 / 255.0, alpha: 1.0)
    }
    class var iosWarmGrey: UIColor {
        return UIColor(white: 153.0 / 255.0, alpha: 1.0)
    }
    class var iosBlackThree: UIColor {
        return UIColor(white: 22.0 / 255.0, alpha: 1.0)
    }
    class var iosBlack: UIColor {
        return UIColor(white: 38.0 / 255.0, alpha: 1.0)
    }
    class var iosPinkishGrey: UIColor {
        return UIColor(white: 204.0 / 255.0, alpha: 1.0)
    }
    class var iosBrownishGrey: UIColor {
        return UIColor(white: 102.0 / 255.0, alpha: 1.0)
    }
}

extension CGRect {
    func equals(_ right: CGRect) -> Bool {
        return origin.equals(right.origin) && size.equals(right.size)
    }
}

extension CGPoint {
    func equals(_ right: CGPoint) -> Bool {
        return x.equals(right.x) && y.equals(right.y)
    }
}

extension CGSize {
    func equals(_ right: CGSize) -> Bool {
        return width.equals(right.width) && height.equals(right.width)
    }
}

extension CGFloat {
    func equals(_ right: CGFloat) -> Bool {
        return abs(self - right) < 0.01
    }
}

extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
    func equals(_ right: Float) -> Bool {
        return abs(self - right) < 0.01
    }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
    func equals(_ right: Double) -> Bool {
        return abs(self - right) < 0.01
    }
}

// MARK: RxSwift - ignoreNil
public protocol OptionalType {
    associatedtype Wrapped
    
    var optional: Wrapped? { get }
}

extension Optional: OptionalType {
    public var optional: Wrapped? { return self }
}

// Unfortunately the extra type annotations are required, otherwise the compiler gives an incomprehensible error.
extension Observable where Element: OptionalType {
    func ignoreNil() -> Observable<Element.Wrapped> {
        return flatMap { value in
            value.optional.map { Observable<Element.Wrapped>.just($0) } ?? Observable<Element.Wrapped>.empty()
        }
    }
}

extension AVPlayer {
    func xd_play() {
        guard currentItem != nil else { return }
        if rate != 0 {
            pause()
        } else if currentTime() == currentItem?.duration {
            fl_seekSmoothly(to: CMTime.zero)
            play()
        } else {
            play()
        }
    }
}

extension AVPlayerItem {
    func disPlaySize() -> CGSize {
        if let videoComposition = videoComposition {
            return videoComposition.renderSize
        }
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else {
            return .zero
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}
