//
//  ResizableSlider.swift
//  LottieInVideo
//
//  Created by lvpengwei on 2018/12/16.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import UIKit

class ResizableSlider: UISlider {
    
    var trackHeight: CGFloat = 2 {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.trackRect(forBounds: bounds)
        rect.size.height = trackHeight
        rect.origin.y = (bounds.height - trackHeight) * 0.5
        return rect
    }
    
}

extension ResizableSlider {
    static func editorSlider() -> ResizableSlider {
        let slider = ResizableSlider()
        slider.trackHeight = 4
        
        slider.minimumValue = 0
        slider.maximumValue = 2
        slider.minimumTrackTintColor = UIColor.iosBrownishGrey
        slider.maximumTrackTintColor = UIColor.iosBlack
        slider.setThumbImage(#imageLiteral(resourceName: "asset_slider_thumb"), for: .normal)
        
        return slider
    }
}
