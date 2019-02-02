//
//  CustomLayerInstruction.swift
//  MixPhotoAndVideo
//
//  Created by lvpengwei on 2018/12/26.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import AVFoundation
import CoreImage
import UIKit

public class TimeRangeStore<T> {
    public init() {}
    private(set) var data: [(CMTimeRange, T)] = []
    public func setItem(_ item: T, timeRange: CMTimeRange, at index: Int = -1) {
        if index >= 0, index < data.count {
            data.insert((timeRange, item), at: index)
        } else {
            data.append((timeRange, item))
        }
    }
    @discardableResult
    public func remove(at index: Int) -> (CMTimeRange, T) {
        return data.remove(at: index)
    }
    public func getItems(at time: CMTime) -> [(CMTimeRange, T)] {
        var result = [(CMTimeRange, T)]()
        data.forEach { (item) in
            if item.0.containsTime(time) {
                result.append(item)
            }
        }
        return result
    }
    public func getItems(at timeRange: CMTimeRange) -> [(CMTimeRange, T)] {
        var result = [(CMTimeRange, T)]()
        data.forEach { (item) in
            if item.0.intersection(timeRange).duration.seconds > 0 {
                result.append(item)
            }
        }
        
        return result
    }
}

public protocol ImageProvider: class {
    
    /// 根据时间渲染出 CIImage
    ///
    /// - Parameters:
    ///   - time: 当前显示到的时间点
    ///   - renderSize: 渲染画布尺寸
    ///   - presentationTimeRange: 这个 ImageProvider 显示的时间段
    /// - Returns: CIImage
    func image(at time: CMTime, renderSize: CGSize, presentationTimeRange: CMTimeRange) -> CIImage?
    
}

public class CustomLayerInstruction: AVMutableVideoCompositionLayerInstruction {
    public override func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    public var overlayStore = TimeRangeStore<ImageProvider>()
    func apply(request: AVAsynchronousVideoCompositionRequest, sourceImage: CIImage) -> CIImage {
        var sourceImage = sourceImage
        if let sourcePixel = request.sourceFrame(byTrackID: trackID) {
            sourceImage = CIImage(cvPixelBuffer: sourcePixel).composited(over: sourceImage)
        }
        let compositionTime = request.compositionTime
        let renderSize = request.renderContext.size
        
        var flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: sourceImage.extent.origin.y * 2 + sourceImage.extent.height) // 反转Y轴
        sourceImage = sourceImage.transformed(by: flipYTransform)
        var timeRange = CMTimeRange.zero
        var result = false
        
        // Crop
        let originalRect = sourceImage.extent
        var startCropRect = CGRect.zero
        var endCropRect = CGRect.zero
        result = getCropRectangleRamp(for: compositionTime, startCropRectangle: &startCropRect, endCropRectangle: &endCropRect, timeRange: &timeRange)
        if (timeRange.containsTime(compositionTime) && result && !startCropRect.equalTo(originalRect)) {
            sourceImage = sourceImage.cropped(to: startCropRect)
        }
        
        // Transform
        var startTransform = CGAffineTransform.identity
        var endTransfrom = CGAffineTransform.identity
        var transform = CGAffineTransform.identity
        result = getTransformRamp(for: compositionTime, start: &startTransform, end: &endTransfrom, timeRange: &timeRange)
        transform = endTransfrom
        
        // Opacity
        var opacityStart: Float = 1
        var opacityEnd: Float = 1
        result = getOpacityRamp(for: compositionTime, startOpacity: &opacityStart, endOpacity: &opacityEnd, timeRange: &timeRange)
        var currentAlpha: Float = 1
        if (timeRange.containsTime(compositionTime) && result) {
            let elapsed = CMTimeSubtract(compositionTime, timeRange.start)
            let tweenFactor = CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(timeRange.duration)
            currentAlpha = (opacityEnd - opacityStart) * (Float)(tweenFactor) + opacityStart
        }
        sourceImage = sourceImage.transformed(by: transform)
        flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: sourceImage.extent.origin.y * 2 + sourceImage.extent.height) // 反转Y轴
        sourceImage = sourceImage.transformed(by: flipYTransform)
        if (currentAlpha != 1) {
            let colorMatrixFilter = CustomVideoCompositor.colorMatrixFilter
            colorMatrixFilter.setDefaults()
            colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: (CGFloat)(currentAlpha)), forKey: "inputAVector")
            colorMatrixFilter.setValue(sourceImage, forKey: "inputImage")
            if let image = colorMatrixFilter.outputImage {
                sourceImage = image
            }
        }
        let overlays = overlayStore.getItems(at: compositionTime)
        overlays.forEach { (overlayInfo) in
            if let overlayImage = overlayInfo.1.image(at: compositionTime, renderSize: renderSize, presentationTimeRange: overlayInfo.0) {
                sourceImage = overlayImage.composited(over: sourceImage)
            }
        }
        return sourceImage
    }
}
