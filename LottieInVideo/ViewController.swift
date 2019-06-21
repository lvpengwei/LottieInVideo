//
//  ViewController.swift
//  LottieInVideo
//
//  Created by lvpengwei on 2018/12/15.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import UIKit
import Photos
import SCRecorder
import AVFoundation
import Lottie

class ViewController: UIViewController {
    @IBOutlet weak var videoPreview: VideoPreview!
    @IBOutlet weak var progressLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideo()
    }
    private func setupVideo() {
        guard let path = Bundle.main.path(forResource: "1532072337.63853", ofType: "MP4") else { return }
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        videoPreview.play(withAsset: asset, autoPlay: false)
    }
    @IBAction func addStickerAction(_ sender: Any) {
        setupSticker()
    }
    @IBAction func exportAction(_ sender: Any) {
        exportVideo()
    }
    private var sticker: Sticker?
    private func setupSticker() {
        if let sticker = self.sticker {
            videoPreview.removeSticker(sticker: sticker)
        }
        guard let stickerPath = Bundle.main.path(forResource: "drinks", ofType: "json") else { return }
        let start = videoPreview.player.fl_currentTime()
        let duration = min(CMTime(seconds: 3, preferredTimescale: 600), videoPreview.player.itemDuration - start)
        let sticker = Sticker()
        sticker.url = stickerPath
        sticker.range = CMTimeRange(start: start, duration: duration)
        videoPreview.addSticker(sticker: sticker)
        self.sticker = sticker
    }
    private var exportSession: SCAssetExportSession?
    private func exportVideo() {
        guard let path = Bundle.main.path(forResource: "1532072337.63853", ofType: "MP4") else { return }
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
        try? videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: .zero)
        exportSession = SCAssetExportSession(asset: composition)
        exportSession?.videoConfiguration.composition = createVideoComposition(composition)
        exportSession?.delegate = self
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + "/\(Date().timeIntervalSince1970).mp4")
        exportSession?.outputUrl = outputURL
        exportSession?.outputFileType = AVFileType.mp4.rawValue
        
        progressLabel.isHidden = false
        exportSession?.exportAsynchronously(completionHandler: { [weak self] in
            guard let s = self else { return }
            s.progressLabel.isHidden = true
            if let err = s.exportSession?.error {
                print(err.localizedDescription)
            } else {
                print("complete")
                s.saveVideoToAlbum(outputURL, nil)
            }
        })
    }
    private func requestAuthorization(completion: @escaping ()->Void) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else if PHPhotoLibrary.authorizationStatus() == .authorized {
            completion()
        }
    }
    private func saveVideoToAlbum(_ outputURL: URL, _ completion: ((Error?) -> Void)?) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: outputURL, options: nil)
            }) { (result, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        print("保存成功")
                    }
                    completion?(error)
                }
            }
        }
    }
    private func createVideoComposition(_ asset: AVAsset) -> AVVideoComposition {
        let renderSize = CGSize(width: 1920, height: 1080)
        let videoTrack = asset.tracks(withMediaType: .video)[0]
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTimeMake(value: 20, timescale: 600)
        videoComposition.customVideoCompositorClass = CustomVideoCompositor.classForCoder() as? AVVideoCompositing.Type
        
        let layerInstruction = CustomLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 1.0, timeRange: CMTimeRangeMake(start: .zero, duration: asset.duration))
        if let layer = createStickerLayer(in: renderSize) {
            layerInstruction.overlayStore.setItem(layer, timeRange: CMTimeRangeMake(start: .zero, duration: asset.duration))
        }
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        return videoComposition
    }
    private func createStickerLayer(in size: CGSize) -> StickerContainerLayer? {
        guard let sticker = sticker else { return nil }
        let layer = StickerContainerLayer()
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let animationLayer = CALayer.animation(withPath: sticker.url)
        let bounds = sticker.bounds(containerBounds: layer.bounds)
        let scale = bounds.width / animationLayer.bounds.width
        var transform = CGAffineTransform.init(scaleX: scale, y: scale)
        transform = sticker.transform.concatenating(transform)
        animationLayer.setAffineTransform(transform)
        animationLayer.position = sticker.center(containerBounds: layer.bounds)
        animationLayer.beginTime = sticker.range.start.seconds
        animationLayer.duration = sticker.range.duration.seconds
        animationLayer.speed = sticker.speed
        layer.addSublayer(animationLayer)
        return layer
    }
}

extension ViewController: SCAssetExportSessionDelegate {
    func assetExportSessionDidProgress(_ assetExportSession: SCAssetExportSession) {
        print("progress: \(assetExportSession.progress)")
        DispatchQueue.main.async {
            self.progressLabel.text = "\(assetExportSession.progress.format(f: ".2"))"
        }
    }
}

class StickerContainerLayer: CALayer { }
extension StickerContainerLayer: ImageProvider {
    public func image(at time: CMTime, renderSize: CGSize, presentationTimeRange: CMTimeRange) -> CIImage? {
        guard let sublayers = sublayers else { return nil }
        for sublayer in sublayers {
            let beginTime = CMTime(seconds: sublayer.beginTime, preferredTimescale: 600)
            let duration = CMTime(seconds: sublayer.duration, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: beginTime, duration: duration)
            if (timeRange.containsTime(time)) {
                sublayer.isHidden = false
                let progress = (time - beginTime).seconds / duration.seconds
                sublayer.display(with: CGFloat(progress))
            } else {
                sublayer.isHidden = true
            }
        }
        let size = bounds.size
        let w = Int(size.width)
        let h = Int(size.height)
        guard let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 4 * w, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        render(in: context)
        guard let snapshot = context.makeImage() else { return nil }
        var result = CIImage(cgImage: snapshot)
        result = result.transformed(by: CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: result.extent.origin.y * 2 + result.extent.height))
        return result
    }
}
