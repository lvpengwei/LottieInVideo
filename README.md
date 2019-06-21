
# LottieInVideo
Render Lottie in video by AVFoundation

### Lottie 3.1.0
分支 master 使用的 Lottie 版本

### Lottie 2.5.2
分支 lottie-2.5.2
在 Lottie 2.5.2 版本，Lottie 重构了生成动画的方案。新的方案使用了各种插值器（`Interpolate`）来生成每一帧的贝塞尔曲线/点等等，最后用`CoreGraphics`来画。所以我们可以对`layer`做截图，然后把生成的图片和视频图片进行叠加。

### Lottie 1.0.4
在 Lottie 1.0.4 版本，Lottie 是基于 `CAAnimation` 实现的动画，那时候合成到视频中需要借助 `AVVideoComposition` 的 `animationTool`。
```
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
```
