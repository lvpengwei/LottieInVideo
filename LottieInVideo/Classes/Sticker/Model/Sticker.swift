//
//  Sticker.swift
//  LottieInVideo
//
//  Created by lvpengwei on 2018/12/15.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Lottie

class Sticker {
    var url = ""
    var centerX: CGFloat = 50
    var centerY: CGFloat = 50
    var width: CGFloat = 100
    var transform: CGAffineTransform = .identity
    var compSize: CGSize = .zero
    var aspectRatio: CGFloat { // 宽高比
        get {
            if compSize == .zero {
                return 100
            }
            return (compSize.width / compSize.height) * 100
        }
    }
    @objc dynamic var range: CMTimeRange = CMTimeRange.zero
    @objc dynamic var speed: Float = 1
    
    func bounds(containerBounds: CGRect) -> CGRect {
        var newWidth = containerBounds.width * width / 100
        var newHeight = newWidth / (aspectRatio / 100)
        if newHeight > containerBounds.height {
            newHeight = containerBounds.height
            newWidth = newHeight * (aspectRatio / 100)
        }
        return CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
    }
    
    func setBounds(_ bounds: CGRect, containerBounds: CGRect) {
        width = bounds.width / containerBounds.width * 100
    }
    
    func center(containerBounds: CGRect) -> CGPoint {
        let newCenterX = containerBounds.width * centerX / 100
        let newCenterY = containerBounds.height * centerY / 100
        return CGPoint(x: newCenterX, y: newCenterY)
    }
    
    func setCenter(_ center: CGPoint, containerBounds: CGRect) {
        centerX = center.x / containerBounds.width * 100
        centerY = center.y / containerBounds.height * 100
    }
}
