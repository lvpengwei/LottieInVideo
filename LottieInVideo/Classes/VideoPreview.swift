//
//  VideoPreview.swift
//  LottieInVideo
//
//  Created by lvpengwei on 2018/12/16.
//  Copyright © 2018 lvpengwei. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SCRecorder
import AVFoundation
import AVPlayerSeeker

class VideoPreview: UIView {
    private var videoView: UIView! {
        return scFilterImageView
    }
    private weak var scFilterImageView: SCFilterImageView!
    let player = SCPlayer()
    private let playButton = UIButton()
    private let slider = ResizableSlider.editorSlider()
    private let leftTimeLabel = UILabel()
    private let rightTimeLabel = UILabel()
    private let stickerWrapLayer = CALayer()
    private var stickerWrapView: StickerWrapView!
    private let controlView = UIView()
    private var currentItem: AVPlayerItem? {
        return player.currentItem
    }
    @objc dynamic var hideStickerWrapView: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit() {
        let scFilterImageView = SCFilterImageView()
        scFilterImageView.contentMode = .scaleAspectFit
        addSubview(scFilterImageView)
        self.scFilterImageView = scFilterImageView
        
        player.scImageView = scFilterImageView
        player.delegate = self
        player.beginSendingPlayMessages()
        
        stickerWrapLayer.masksToBounds = true
        layer.addSublayer(stickerWrapLayer)
        
        stickerWrapView = StickerWrapView(stickerLayer: stickerWrapLayer)
        stickerWrapView.clipsToBounds = true
        addSubview(stickerWrapView)
        
        controlView.isHidden = true
        controlView.backgroundColor = UIColor.xd_161616
        addSubview(controlView)
        
        playButton.isUserInteractionEnabled = false
        playButton.setImage(#imageLiteral(resourceName: "icon_play"), for: .normal)
        playButton.setImage(#imageLiteral(resourceName: "icon_pause"), for: .selected)
        playButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        controlView.addSubview(playButton)
        
        slider.maximumValue = 1
        slider.minimumTrackTintColor = UIColor.init(hex6: 0xffffff, alpha: 0.64)
        slider.maximumTrackTintColor = UIColor.init(hex6: 0xffffff, alpha: 0.16)
        slider.setThumbImage(#imageLiteral(resourceName: "asset_slider_thumb"), for: .normal)
        slider.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(handleSliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(handleSliderTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        controlView.addSubview(slider)
        
        leftTimeLabel.font = UIFont.boldXDFont(ofSize: 11)
        leftTimeLabel.textAlignment = .left
        leftTimeLabel.textColor = .white
        leftTimeLabel.text = "00:00"
        controlView.addSubview(leftTimeLabel)
        
        rightTimeLabel.font = UIFont.boldXDFont(ofSize: 11)
        rightTimeLabel.textAlignment = .left
        rightTimeLabel.textColor = .white
        controlView.addSubview(rightTimeLabel)
        
        controlView.bounds = CGRect(x: 0, y: 0, width: Util.screenWidth, height: 32)
        
        playButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(9)
            make.centerY.equalToSuperview()
        }
        leftTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(playButton.snp.trailing).offset(9)
            make.width.equalTo(32)
            make.centerY.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.leading.equalTo(leftTimeLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        rightTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(slider.snp.trailing).offset(8)
            make.width.equalTo(32)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-15)
        }
        
        stickerWrapView.isHidden = true
        let statusObservable = player.rx.observe(AVPlayer.Status.self, "status").takeUntil(rx.deallocated).ignoreNil()
        let rateObservable = player.rx.observe(Float.self, "rate").takeUntil(rx.deallocated).ignoreNil()
        let hideStickerWrapViewObservable = rx.observeWeakly(Bool.self, "hideStickerWrapView").takeUntil(rx.deallocated).ignoreNil()
        _ = Observable.combineLatest(statusObservable, rateObservable, hideStickerWrapViewObservable) { !($0 == .readyToPlay && $1 == 0 && !$2) }.bind(to: stickerWrapView.rx.isHidden)
        _ = rateObservable.subscribe(onNext: { [weak self] (_) in
            guard let s = self else { return }
            if s.player.rate != 0 {
                // 播放
                s.playButton.isSelected = true
            } else {
                s.playButton.isSelected = false
            }
        })
        _ = hideStickerWrapViewObservable.subscribe(onNext: { [weak self] in
            self?.stickerWrapLayer.isHidden = $0
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(play as () -> Void))
        addGestureRecognizer(tap)
    }
    @objc private func handleSliderValueChanged(s: UISlider) {
        if let duration = player.currentItem?.duration {
            let time = CMTime(seconds: Double(s.value) * duration.seconds, preferredTimescale: duration.timescale)
            player.fl_seekSmoothly(to: time)
        }
    }
    @objc private func handleSliderTouchDown() {
        player.rate = 0
    }
    @objc private func handleSliderTouchUp() {
        player.rate = 0
    }
    @objc func play() {
        player.xd_play()
    }
    func play(withAsset asset: AVAsset, autoPlay: Bool = true) {
        play(withItem: AVPlayerItem(asset: asset), autoPlay: autoPlay)
    }
    func play(withItem item: AVPlayerItem, from time: CMTime = CMTime.zero, autoPlay: Bool = false) {
        stickerWrapLayer.opacity = 0
        DispatchQueue.main.async {
            self.player.replaceCurrentItem(with: item)
            self.player.fl_seekSmoothly(to: time)
            if autoPlay {
                self.player.play()
            } else {
                self.player.pause()
            }
            self.setNeedsLayout()
            self.stickerWrapLayer.opacity = 1
        }
    }
    func addSticker(sticker: Sticker) {
        let stickerView = StickerView(sticker: sticker)
        if stickerView.center == .zero {
            stickerView.center = CGPoint(x: stickerWrapView.bounds.midX, y: stickerWrapView.bounds.midY)
        }
        stickerWrapView.addSubview(stickerView)
        if let syncLayer = stickerView.stickerLayer as? AVSynchronizedLayer {
            syncLayer.playerItem = player.currentItem
        }
    }
    func removeSticker(sticker: Sticker) {
        let subviews = stickerWrapView.subviews
        for view in subviews {
            guard let stickerView = view as? StickerView else { continue }
            guard stickerView.sticker === sticker else { continue }
            stickerView.removeFromSuperview()
        }
    }
    deinit {
        player.endSendingPlayMessages()
    }
    override var isHidden: Bool {
        set {
            super.isHidden = newValue
            if newValue && player.rate != 0 {
                player.rate = 0
            }
        }
        get {
            return super.isHidden
        }
    }
    private var disPlaySize: CGSize? {
        get {
            return currentItem?.disPlaySize()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }
    var controlViewAlwaysStickyBottom: Bool = false {
        didSet {
            if controlViewAlwaysStickyBottom {
                controlView.backgroundColor = UIColor.init(hex6: 0x000000, alpha: 0.48)
            } else {
                controlView.backgroundColor = UIColor.xd_161616
            }
        }
    }
    fileprivate var renderAspectRatio: Float = 0
    fileprivate func layoutViews() {
        if var size = disPlaySize {
            if size.width == 0 || size.height == 0 {
                return
            }
            size = CGSize(width: abs(size.width), height: abs(size.height))
            var aspectRatio = CGFloat(renderAspectRatio)
            if aspectRatio == 0 {
                aspectRatio = size.width / size.height
            }
            var actualWidth = bounds.width
            var actualHeight = bounds.height
            if controlViewAlwaysStickyBottom {
                videoView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            } else {
                if controlView.isHidden {
                    actualHeight = bounds.height
                    videoView.center = CGPoint(x: bounds.midX, y: bounds.midY)
                } else {
                    actualHeight = bounds.height - 32
                    videoView.center = CGPoint(x: bounds.midX, y: bounds.midY - 16)
                }
            }
            var newWidth: CGFloat
            var newHeight: CGFloat
            
            let actualRatio = actualWidth / actualHeight
            if actualRatio > aspectRatio {
                actualWidth = actualHeight * aspectRatio
            } else if actualRatio < aspectRatio {
                actualHeight = actualWidth / aspectRatio
                if !controlViewAlwaysStickyBottom {
                    if !controlView.isHidden && (bounds.height - actualHeight) >= 32 {
                        videoView.center = CGPoint(x: bounds.midX, y: bounds.midY)
                    }
                }
            }
            newWidth = actualWidth
            newHeight = actualHeight
            
            videoView.bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
            videoView.setNeedsLayout()
            
            // control view
            controlView.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: 32)
            if controlViewAlwaysStickyBottom {
                controlView.center = CGPoint(x: bounds.midX, y: bottom - 16)
            } else {
                controlView.center = CGPoint(x: bounds.midX, y: videoView.centerY + newHeight * 0.5 + 16)
            }
            // sticker wrap view
            stickerWrapView.bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
            stickerWrapView.center = videoView.center
        }
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil && player.rate != 0 {
            player.pause()
        }
    }
}

extension VideoPreview: SCPlayerDelegate {
    func updateLeftTimeLabel() {
        guard let item = player.currentItem else { return }
        let currentTime = player.currentTime()
        let duration = item.duration
        slider.setValue(Float(currentTime.seconds / duration.seconds), animated: true)
        leftTimeLabel.text = "\(Util.timeStringMMSS(duration: currentTime.seconds))"
    }
    func updateRightTimeLabel() {
        guard let item = player.currentItem else { return }
        let duration = item.asset.duration
        rightTimeLabel.text = "\(Util.timeStringMMSS(duration: duration.seconds))"
    }
    func player(_ player: SCPlayer, didPlay currentTime: CMTime, loopsCount: Int) {
        updateLeftTimeLabel()
    }
    func player(_ player: SCPlayer, didChange item: AVPlayerItem?) {
        controlView.isHidden = item == nil
        changeStickerLayerItem()
        if let item = item {
            if item.asset.statusOfValue(forKey: "duration", error: nil) == .loaded {
                updateRightTimeLabel()
            } else {
                rightTimeLabel.text = "--:--"
                item.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    DispatchQueue.main.async {
                        self.updateRightTimeLabel()
                    }
                }
            }
        }
        setNeedsLayout()
    }
    func changeStickerLayerItem() {
        guard let sublayers = stickerWrapLayer.sublayers else { return }
        for sublayer in sublayers {
            if let syncLayer = sublayer as? AVSynchronizedLayer {
                syncLayer.playerItem = currentItem
            }
        }
    }
}
