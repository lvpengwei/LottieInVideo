//
//  StickerView.swift
//  XDtv
//
//  Created by lvpengwei on 19/02/2017.
//  Copyright © 2017 xiaodao.tv. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import AVFoundation

private func CGRectGetCenter(rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.midX, y: rect.midY)
}
private func CGRectScale(rect: CGRect, wScale: CGFloat, hScale: CGFloat) -> CGRect {
    return CGRect(x: rect.origin.x * wScale,
                  y: rect.origin.y * hScale,
                  width: rect.size.width * wScale,
                  height: rect.size.height * hScale)
}
private func CGPointGetDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
    let fx = point2.x - point1.x
    let fy = point2.y - point1.y
    return sqrt(fx*fx + fy*fy)
}
private func CGAffineTransformGetAngle(t: CGAffineTransform) -> CGFloat {
    return atan2(t.b, t.a)
}

class StickerView: StickerWrapView, UIGestureRecognizerDelegate {
    private var beginningPoint: CGPoint = .zero
    private var beginningCenter: CGPoint = .zero
    @objc private func handleMoveAction(_ recognizer: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let touchLocation = recognizer.location(in: superview)
        if recognizer.state == .began {
            beginningPoint = touchLocation
            beginningCenter = center
        } else if recognizer.state == .changed {
            let xSpacing: CGFloat = 0
            let ySpacing: CGFloat = 0
            var x = beginningCenter.x + (touchLocation.x - beginningPoint.x)
            x = x < xSpacing ? xSpacing : min(x, superview.bounds.width - xSpacing)
            var y = beginningCenter.y + (touchLocation.y - beginningPoint.y)
            y = y < ySpacing ? ySpacing : min(y, superview.bounds.height - ySpacing)
            center = CGPoint(x: x, y: y)
        } else if recognizer.state == .cancelled || recognizer.state == .failed || recognizer.state == .ended {
        }
    }
    
    private var deltaAngle: CGFloat = 0
    private var initialBounds: CGRect = .zero
    private var initialDistance: CGFloat = 0
    @objc private func handlePanAction(_ recognizer: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let touchLocation = recognizer.location(in: superview)
        let center = CGRectGetCenter(rect: frame)
        if recognizer.state == .began {
            deltaAngle = atan2(touchLocation.y - center.y, touchLocation.x - center.x) - CGAffineTransformGetAngle(t: transform)
            initialBounds = bounds
            initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
        } else if recognizer.state == .changed {
            let ang = atan2(touchLocation.y - center.y, touchLocation.x - center.x)
            let angleDiff = deltaAngle - ang
            transform = CGAffineTransform(rotationAngle: -angleDiff)
            let scale = sqrt(CGPointGetDistance(point1: center, point2: touchLocation) / initialDistance)
            let scaleRect = CGRectScale(rect: initialBounds, wScale: scale, hScale: scale)
            bounds = CGRect(x: 0, y: 0, width: scaleRect.size.width, height: scaleRect.size.height)
        } else if recognizer.state == .cancelled || recognizer.state == .failed || recognizer.state == .ended {
        }
    }
    
    override func layoutSubviews() {
        if let superview = superview {
            let stickerBounds = sticker.bounds(containerBounds: superview.bounds)
            let wrapBounds = CGRect(x: 0, y: 0, width: stickerBounds.width + padding * 2, height: stickerBounds.height + padding * 2)
            if !bounds.equals(wrapBounds) {
                bounds = wrapBounds
            }
            if !center.equals(sticker.center(containerBounds: superview.bounds)) {
                center = sticker.center(containerBounds: superview.bounds)
            }
            if transform != sticker.transform {
                transform = sticker.transform
            }
        }
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rotateImageView.bounds = CGRect(x: 0, y: 0, width: padding * 2, height: padding * 2)
        rotateImageView.center = CGPoint(x: bounds.width - padding, y: bounds.height - padding)
        borderLayer.bounds = bounds.insetBy(dx: padding, dy: padding)
        borderLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        if let borderLayer = borderLayer as? CAShapeLayer {
            borderLayer.path = UIBezierPath.init(rect: borderLayer.bounds).cgPath
        }
        CATransaction.commit()
    }
    
    override var bounds: CGRect {
        didSet {
            if let superview = superview {
                sticker.setBounds(bounds.insetBy(dx: padding, dy: padding), containerBounds: superview.bounds)
            }
        }
    }
    
    override var center: CGPoint {
        didSet {
            if let superview = superview {
                sticker.setCenter(center, containerBounds: superview.bounds)
            }
        }
    }
    
    override var transform: CGAffineTransform {
        didSet {
            sticker.transform = transform
        }
    }
    
    var isSelected: Bool = true {
        didSet {
            updateUI()
        }
    }
    var movable: Bool = true {
        didSet {
            panGestureRecognizer.isEnabled = movable
        }
    }
    var scalable: Bool = true {
        didSet {
            rotateImageView.isUserInteractionEnabled = scalable
            updateUI()
        }
    }
    
    private func updateUI() {
        if isSelected {
            borderLayer.isHidden = false
            rotateImageView.isHidden = !scalable
        } else {
            borderLayer.isHidden = true
            rotateImageView.isHidden = true
        }
        checkStickerLayer()
    }
    
    fileprivate func checkStickerLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        stickerLayer.isHidden = false
        CATransaction.commit()
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            if isSelected {
                return true
            } else {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    private var rotateImageView: UIImageView!
    private var borderLayer: CALayer!
    var sticker: Sticker
    var timeOffset: CMTime
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    init(sticker: Sticker, timeOffset: CMTime = CMTime.zero) {
        self.sticker = sticker
        self.timeOffset = timeOffset
        var stickerJSON: [ String: Any ] = [:]
        do {
            let animationData = try Data(contentsOf: URL(fileURLWithPath: sticker.url))
            if let animationJSON = try JSONSerialization.jsonObject(with: animationData, options: JSONSerialization.ReadingOptions(rawValue: UInt(0))) as? Dictionary<String, Any> {
                stickerJSON = animationJSON
            }
        } catch let e {
            print(e)
        }
        let animationLayer = CALayer.animation(fromJSON: stickerJSON, loop: false)
        sticker.compSize = animationLayer.compSize()
        let stickerLayer = StickerLayer.init(animationLayer: animationLayer)
        
        super.init(stickerLayer: stickerLayer)
        
        padding = 15
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleMoveAction(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer
        
        let borderLayer = CALayer()
        borderLayer.borderWidth = 2
        borderLayer.borderColor = UIColor.xd_03a9f4.cgColor
        borderLayer.zPosition = 1
        borderLayer.cornerRadius = 4
        borderLayer.masksToBounds = true
        layer.addSublayer(borderLayer)
        self.borderLayer = borderLayer
        
        let dragImageView = UIImageView()
        dragImageView.contentMode = .center
        dragImageView.image = #imageLiteral(resourceName: "sticker_drag")
        dragImageView.isUserInteractionEnabled = true
        dragImageView.layer.zPosition = 2
        addSubview(dragImageView)
        self.rotateImageView = dragImageView
        dragImageView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanAction(_:))))
        
        stickerLayer.isHidden = true
        updateLayerRange()
        updateUI()
    }
    func layoutForPreview() {
        self.borderLayer.removeFromSuperlayer()
        
        let borderLayer = CAShapeLayer()
        borderLayer.lineWidth = 4
        borderLayer.lineDashPattern = [2, 2]
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.init(hex6: 0x03a9f4, alpha: 0.63).cgColor
        borderLayer.zPosition = 1
        borderLayer.cornerRadius = 4
        borderLayer.masksToBounds = true
        layer.addSublayer(borderLayer)
        self.borderLayer = borderLayer
    }
    private func exchange(layer1: CALayer, layer2: CALayer) {
        layer2.bounds = layer1.bounds
        layer2.position = layer1.position
        layer2.isHidden = layer1.isHidden
        layer2.setAffineTransform(layer1.affineTransform())
        layer1.superlayer?.addSublayer(layer2)
        layer1.removeFromSuperlayer()
    }
    private var isDragging: Bool = false
    private func updateLayerRange() {
        guard let stickerLayer = stickerLayer as? StickerLayer else { return }
        stickerLayer.animationLayer.beginTime = timeOffset.seconds + sticker.range.start.seconds / Double(sticker.speed)
        stickerLayer.animationLayer.duration = sticker.range.duration.seconds
        stickerLayer.animationLayer.speed = sticker.speed
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StickerLayer: AVSynchronizedLayer {
    var animationLayer: CALayer
    init(animationLayer: CALayer) {
        self.animationLayer = animationLayer
        super.init()
        addSublayer(animationLayer)
    }
    override var bounds: CGRect {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let scale = bounds.width / animationLayer.bounds.width
            animationLayer.setAffineTransform(CGAffineTransform.init(scaleX: scale, y: scale))
            animationLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            CATransaction.commit()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
