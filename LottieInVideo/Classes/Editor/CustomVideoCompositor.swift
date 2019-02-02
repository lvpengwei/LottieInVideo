//
//  CustomVideoCompositor.swift
//  MixPhotoAndVideo
//
//  Created by lvpengwei on 2018/12/26.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage

class CustomVideoCompositor: NSObject, AVFoundation.AVVideoCompositing {
    
    override public init() {
        super.init()
    }
    
    private static let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
    public static let ciContext: CIContext = {
        let options = [ CIContextOption.workingColorSpace: NSNull(), CIContextOption.outputColorSpace: NSNull(), CIContextOption.useSoftwareRenderer: false ] as [CIContextOption : Any]
        return CIContext(eaglContext: eaglContext!, options: options)
    }()
    static let colorMatrixFilter: CIFilter = {
        return CIFilter(name: "CIColorMatrix")!
    }()
    
    private let renderContextQueue: DispatchQueue = DispatchQueue(label: "videoedit.rendercontextqueue")
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "videoedit.renderingqueue")
    private var renderContextDidChange = false
    private var shouldCancelAllRequests = false
    private var renderContext: AVVideoCompositionRenderContext?
    
    public var sourcePixelBufferAttributes: [String: Any]? {
        return [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    }
    
    public var requiredPixelBufferAttributesForRenderContext: [String: Any] {
        return [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    }
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.renderContext = newRenderContext
            strongSelf.renderContextDidChange = true
        }
    }
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.shouldCancelAllRequests {
                request.finishCancelledRequest()
            } else {
                autoreleasepool(invoking: { () -> () in
                    do {
                        if let resultPixels = try strongSelf.newRenderedPixelBufferForRequest(request: request) {
                            request.finish(withComposedVideoFrame: resultPixels)
                        } else {
                            request.finishCancelledRequest()
                        }
                    } catch let e {
                        request.finish(with: e)
                    }
                })
            }
        }
    }
    
    public func cancelAllPendingVideoCompositionRequests() {
        shouldCancelAllRequests = true
        renderingQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.shouldCancelAllRequests = false
        }
    }
    
    public func newRenderedPixelBufferForRequest(request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer? {
        guard let renderContext = renderContext else {
            let e = NSError(domain: "videoedit.customvideocompositor", code: 1000, userInfo: nil)
            throw e
        }
        guard let outputPixels = renderContext.newPixelBuffer() else {
            return nil
        }
        
        var image = CIImage(cvPixelBuffer: outputPixels)
        
        let backgroundColor = CIColor(color: UIColor.black)
        let backgroundImage = CIImage(color: backgroundColor).cropped(to: image.extent)
        image = backgroundImage.composited(over: image)

        let instruction = request.videoCompositionInstruction as! AVVideoCompositionInstruction
        instruction.layerInstructions.forEach { (layerInstruction) in
            guard let layerInstruction = layerInstruction as? CustomLayerInstruction else { return }
            image = layerInstruction.apply(request: request, sourceImage: image)
        }
        CustomVideoCompositor.ciContext.render(image, to: outputPixels)
        
        return outputPixels
    }
    
}
