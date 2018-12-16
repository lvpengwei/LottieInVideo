//
//  StickerWrapView.swift
//  XDtv
//
//  Created by lvpengwei on 19/02/2017.
//  Copyright © 2017 xiaodao.tv. All rights reserved.
//

import Foundation
import UIKit

class StickerWrapView: UIView {
    
    var padding: CGFloat = 0
    var stickerLayer: CALayer
    
    init(stickerLayer: CALayer) {
        self.stickerLayer = stickerLayer
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var bounds: CGRect {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            stickerLayer.bounds = bounds.insetBy(dx: padding, dy: padding)
            CATransaction.commit()
        }
    }
    
    override var center: CGPoint {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            stickerLayer.position = center
            CATransaction.commit()
        }
    }
    
    override var transform: CGAffineTransform {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            stickerLayer.setAffineTransform(transform)
            CATransaction.commit()
        }
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        if let view = view as? StickerWrapView {
            stickerLayer.addSublayer(view.stickerLayer)
        }
    }
    
    override func insertSubview(_ view: UIView, at index: Int) {
        super.insertSubview(view, at: index)
        if let view = view as? StickerWrapView {
            stickerLayer.insertSublayer(view.stickerLayer, at: UInt32(index))
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        stickerLayer.removeFromSuperlayer()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden {
            return nil
        }
        var view = super.hitTest(point, with: event)
        if view == nil {
            for subview in subviews {
                if let subview = subview as? StickerWrapView, !subview.isHidden {
                    if subview.frame.contains(point) {
                        view = subview
                        break
                    }
                }
            }
        }
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        stickerLayer.bounds = bounds.insetBy(dx: padding, dy: padding)
        stickerLayer.position = center
        stickerLayer.setAffineTransform(transform)
        CATransaction.commit()
    }
    
}

