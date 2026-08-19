//
//  DRNEVideoPlayerBodyView.swift
//  ImageRenderTool
//
//  Created by zjn on 2026/8/18.
//  Copyright © 2026 zjn. All rights reserved.
//

import UIKit
import AVFoundation

class DRNEVideoPlayerBodyView: UIView {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init(title: String) {
        super.init(frame: CGRectZero)
        self.titleLab.text = title
    }
    
    var isFinishedLayoutSubView = false
    override func layoutSubviews() {
        super.layoutSubviews()
        if isFinishedLayoutSubView == true || self.frame.size.equalTo(CGSizeZero) {
            return
        }
        self.isFinishedLayoutSubView = true
        
        self.backgroundColor = kHexRGBA(hexStr: "#9F9F9FFF")
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        let bodyWidth = self.frame.size.width
        let bodyHeight = self.frame.size.height
        
        let titleLabHeight = 20.0
        self.addSubview(self.titleLab)
        self.titleLab.frame = CGRectMake(0, 10, bodyWidth, titleLabHeight)
        let titleLabMaxY = CGRectGetMaxY(self.titleLab.frame)
                
        let playItemWidth = 26.0
        let playItemHeight = 25.0
        self.addSubview(self.playBtn)
        self.playBtn.frame = CGRectMake(0, bodyHeight - playItemHeight,
                                        playItemWidth, playItemHeight)
        let playItemMaxX = CGRectGetMaxX(self.playBtn.frame)
        let playItemMinY = CGRectGetMinY(self.playBtn.frame)
        
        self.playerLayer.frame = CGRectMake(0, titleLabMaxY + 10,
                                            bodyWidth,
                                            bodyHeight - titleLabMaxY - playItemHeight - 10)
        self.layer.addSublayer(self.playerLayer)
        
        
        self.addSubview(self.slider)
        self.slider.frame = CGRectMake(playItemMaxX + 5, playItemMinY,
                                       bodyWidth - playItemWidth - 10,
                                       playItemHeight)
    }
    func loadAsset(asset: AVAsset) {
        if let lastPlayer = self.playerLayer.player {
            lastPlayer.pause()
            lastPlayer.replaceCurrentItem(with: nil)
            self.playerLayer.player = nil
        }
        self.isPlay = false
        self.slider.value = 0.0
        
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        self.playerLayer.player = player
        NotificationCenter.default.addObserver(self, selector: #selector(playToEndTimeAction), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    @objc func playToEndTimeAction(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else {
            return
        }
        self.isPlay = false
        // 视频进度条重置到初始位置
        playerItem.seek(to: .zero) { isFinished in}
        self.slider.value = 0.0
    }
    
    /// 销毁对象
    func destroy() {
        guard let player = self.playerLayer.player else {
            return
        }
        guard let playerItem = player.currentItem else {
            return
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        player.pause()
        player.replaceCurrentItem(with: nil)
        self.playerLayer.player = nil
        
        
        if let playerTimer = self.playerTimer {
            playerTimer.invalidate()
            self.playerTimer = nil
        }
    }
    
    // MARK: - ================= Get And Set =================
    var isPlay = false {
        didSet {
            if isPlay == false {
                self.playBtn.isSelected = false
                if let playerTimer = self.playerTimer {
                    playerTimer.invalidate()
                    self.playerTimer = nil
                }
                
                guard let videoPlayer = self.playerLayer.player else {
                    return
                }
                videoPlayer.pause()
                return
            }
            
            self.playBtn.isSelected = true
            guard let videoPlayer = self.playerLayer.player else {
                return
            }
            videoPlayer.play()
            
            // 启动Timer定时器
            let timeInterval = 1.0
            self.playerTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    return
                }
                
                guard let videoPlayer = self.playerLayer.player else {
                    return
                }
                guard let playerItem = videoPlayer.currentItem else {
                    return
                }
                
                let currentSecond = playerItem.currentTime().seconds
                let sumSecond = playerItem.duration.seconds
                let ratio = Float(currentSecond/sumSecond)
                self.slider.value = ratio
            })
        }
    }
    var playerTimer: Timer?
    
    lazy var titleLab = {
        let myself: UILabel = UILabel()
        myself.textAlignment = NSTextAlignment.center
        myself.textColor = kHexRGBA(hexStr: "#FFFFFFFF")
        myself.font = UIFont.boldSystemFont(ofSize: 18)
        return myself
    }()
    
    lazy var playerLayer = {
        let myself = AVPlayerLayer()
        myself.backgroundColor = kHexRGBA(hexStr: "#1F1F1FFF").cgColor
        myself.videoGravity = .resizeAspect
        return myself
    }()
    
    lazy var playBtn = {
        let myself = UIButton(type: .system)
        myself.tintColor = UIColor.clear
        if let icon = UIImage(named: "DRNE_VideoPlayer_Play_Icon") {
            myself.setImage(icon.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        if let icon = UIImage(named: "DRNE_VideoPlayer_Pause_Icon") {
            myself.setImage(icon.withRenderingMode(.alwaysOriginal), for: .selected)
        }
        myself.addTarget(self, action: #selector(playBtnAction), for: .touchUpInside)
        return myself
    }()
    @objc func playBtnAction() {
        self.isPlay = !self.isPlay
    }
    
    lazy var slider = {
        let myself = UISlider()
        if let icon = UIImage(named: "DRNE_VideoPlayer_Slider_Thumb_White") {
            myself.setThumbImage(icon, for: .normal)
        }
        myself.minimumValue = 0.0
        myself.maximumValue = 1.0
        
        myself.addTarget(self, action: #selector(sliderValueInChangeAction), for: UIControl.Event.valueChanged)

        myself.addTarget(self, action: #selector(sliderValueEndAction), for: UIControl.Event.touchUpInside)
        myself.addTarget(self, action: #selector(sliderValueEndAction), for: UIControl.Event.touchUpOutside)
        myself.addTarget(self, action: #selector(sliderValueEndAction), for: UIControl.Event.touchCancel)
        return myself
    }()
    /// 滑动条滑动[过程中]的响应事件
    /// - Parameter sender: 滑动条控件的对象
    @objc func sliderValueInChangeAction (sender: UISlider) {
        guard let videoPlayer = self.playerLayer.player else {
            return
        }
        guard let playerItem = videoPlayer.currentItem else {
            return
        }
        
        guard let frame = playerItem.asset.tracks.first else {
            return
        }
        let ratio = sender.value
        let fps = frame.nominalFrameRate
        let sumTime = playerItem.duration.seconds
        
        // 先暂停视频播放, 以免异步多线程情况下影响播放器对象
        videoPlayer.pause()
        // 设置视频进度条
        let cmTime = CMTime(seconds: sumTime * Double(ratio), preferredTimescale: CMTimeScale(fps))
        videoPlayer.seek(to: cmTime)
    }
    
    /// 滑动条滑动[结束后]的响应事件
    /// - Parameter sender: 滑动条控件的对象
    @objc func sliderValueEndAction (sender: UISlider) {
        guard let videoPlayer = self.playerLayer.player else {
            return
        }
        if self.isPlay == true {
            videoPlayer.play()
        }
    }
}



