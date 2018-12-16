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
        guard let stickerPath = Bundle.main.path(forResource: "drinks", ofType: "json") else { return }
        let sticker = Sticker()
        sticker.url = stickerPath
        sticker.range = CMTimeRange(start: CMTime(seconds: 1, preferredTimescale: 600), duration: CMTime(seconds: 3, preferredTimescale: 600))
        sticker.speed = 1
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
        
        exportSession?.exportAsynchronously(completionHandler: { [weak self] in
            guard let s = self else { return }
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
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 1.0, timeRange: CMTimeRangeMake(start: .zero, duration: asset.duration))
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        if let animationLayer = createStickerLayer(in: renderSize) {
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            let contentLayer = CALayer()
            parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
            videoLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
            contentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
            contentLayer.addSublayer(animationLayer)
            contentLayer.isGeometryFlipped = true
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(contentLayer)
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        }
        return videoComposition
    }
    private func createStickerLayer(in size: CGSize) -> CALayer? {
        guard let sticker = sticker else { return nil }
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        do {
            let animationData = try Data(contentsOf: URL(fileURLWithPath: sticker.url))
            if let animationJSON = try JSONSerialization.jsonObject(with: animationData, options: JSONSerialization.ReadingOptions(rawValue: UInt(0))) as? Dictionary<String, Any> {
                let animationLayer = LOTAnimationLayer.animation(fromJSON: animationJSON, customData: [], loop: false)!
                animationLayer.bounds = sticker.bounds(containerBounds: layer.bounds)
                animationLayer.position = sticker.center(containerBounds: layer.bounds)
                animationLayer.setAffineTransform(sticker.transform)
                animationLayer.beginTime = sticker.range.start.seconds
                animationLayer.duration = sticker.range.duration.seconds
                animationLayer.speed = sticker.speed
                layer.addSublayer(animationLayer)
            }
        } catch let e {
            print(e)
        }
        return layer
    }
}

extension ViewController: SCAssetExportSessionDelegate {
    func assetExportSessionDidProgress(_ assetExportSession: SCAssetExportSession) {
        print("progress: \(assetExportSession.progress)")
    }
}
