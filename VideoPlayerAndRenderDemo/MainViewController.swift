//
//  MainViewController.swift
//  SimpleProgramSwift
//
//  Created by zjn on 2018/10/28.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    /// 视频资源名称
    let videoName = "VideoSource01.MP4"
    /// [原始视频]播放器
    lazy var playerBodyViewOfOriginal = {
        let myself = DRNEVideoPlayerBodyView(title: NSLocalizedString("原始视频", comment: ""))
        return myself
    }()
    /// [渲染视频]播放器
    lazy var playerBodyViewOfRender = {
        let myself = DRNEVideoPlayerBodyView(title: NSLocalizedString("渲染视频", comment: ""))
        return myself
    }()
    let dataSourceOfSliderItems = {
        let dataSource = [
            sliderItemModel(name: NSLocalizedString("光照强度", comment: ""),
                            minValue: 0.0, maxValue: 1.25, defaultValue: 0.25,
                            itemTag: .brightness),
            
            sliderItemModel(name: NSLocalizedString("对比度", comment: ""),
                            minValue: 1.0, maxValue: 2.0, defaultValue: 1.0,
                            itemTag: .contrast),
            
            sliderItemModel(name: NSLocalizedString("饱和度", comment: ""),
                            minValue: 1.0, maxValue: 2.0, defaultValue: 1.25,
                            itemTag: .saturation),
        ]
        return dataSource
    }()
    lazy var sliderItems = {
        var myself = [UISlider]()

        for itemModel in self.dataSourceOfSliderItems {
            let sliderItem = UISlider()
            sliderItem.minimumValue = itemModel.minValue
            sliderItem.maximumValue = itemModel.maxValue
            sliderItem.value = itemModel.defaultValue
            sliderItem.tag = itemModel.itemTag.rawValue
            
            sliderItem.addTarget(self, action: #selector(sliderValueEndAction), for: UIControl.Event.touchUpInside)
            sliderItem.addTarget(self, action: #selector(sliderValueEndAction), for: UIControl.Event.touchUpOutside)
            sliderItem.addTarget(self, action: #selector(sliderValueEndAction), for: UIControl.Event.touchCancel)
            myself.append(sliderItem)
        }
        return myself
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = kHexRGBA(hexStr: "#FFFFFFFF")
        
        let playerBodyWidth = (kScreenWidth - 30)/2
        let playerBodyHeight = playerBodyWidth * 2.0
        self.playerBodyViewOfOriginal.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.playerBodyViewOfOriginal)
        NSLayoutConstraint.activate([
            self.playerBodyViewOfOriginal.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            self.playerBodyViewOfOriginal.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            self.playerBodyViewOfOriginal.widthAnchor.constraint(equalToConstant: playerBodyWidth),
            self.playerBodyViewOfOriginal.heightAnchor.constraint(equalToConstant: playerBodyHeight)
        ])
        guard let avAssetStr = Bundle.main.path(forResource: self.videoName, ofType: "") else {
            return
        }
        let avAssetUrl = NSURL(fileURLWithPath: avAssetStr) as URL
        let avAsset = AVAsset(url: avAssetUrl)
        self.playerBodyViewOfOriginal.loadAsset(asset: avAsset)
        
        
        self.playerBodyViewOfRender.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.playerBodyViewOfRender)
        NSLayoutConstraint.activate([
            self.playerBodyViewOfRender.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            self.playerBodyViewOfRender.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            self.playerBodyViewOfRender.widthAnchor.constraint(equalToConstant: playerBodyWidth),
            self.playerBodyViewOfRender.heightAnchor.constraint(equalToConstant: playerBodyHeight)
        ])
        
        let sliderItemHeight = 40.0
        for index in self.sliderItems.indices {
            let sliderItem = self.sliderItems[index]
            sliderItem.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(sliderItem)
            NSLayoutConstraint.activate([
                sliderItem.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20.0 - CGFloat(index) * sliderItemHeight),
                sliderItem.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 100),
                sliderItem.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
                sliderItem.heightAnchor.constraint(equalToConstant: sliderItemHeight)
            ])
            
            let sliderNameLab = UILabel()
            sliderNameLab.textAlignment = NSTextAlignment.left
            sliderNameLab.textColor = kHexRGBA(hexStr: "#000000FF")
            sliderNameLab.font = UIFont.boldSystemFont(ofSize: 15)
            sliderNameLab.text = self.dataSourceOfSliderItems[index].name
            sliderNameLab.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(sliderNameLab)
            NSLayoutConstraint.activate([
                sliderNameLab.centerYAnchor.constraint(equalTo: sliderItem.centerYAnchor, constant: 0),
                sliderNameLab.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
                sliderNameLab.widthAnchor.constraint(equalToConstant: 80),
                sliderNameLab.heightAnchor.constraint(equalToConstant: sliderItemHeight)
            ])
        }
        
        self.renderVideoAction()
    }
    /// 滑动条滑动[结束后]的响应事件
    /// - Parameter sender: 滑动条控件的对象
    @objc func sliderValueEndAction (sender: UISlider) {
        self.renderVideoAction()
    }
    
    /// [渲染视频]核心方法
    func renderVideoAction() {
        var brightness = 0.0
        var contrast = 0.0
        var saturation = 0.0
        
        for sliderItem in self.sliderItems {
            switch sliderItem.tag {
            case DRNESliderItemType.brightness.rawValue:
                brightness = Double(sliderItem.value)
                break
                
            case DRNESliderItemType.contrast.rawValue:
                contrast = Double(sliderItem.value)
                break
                
            case DRNESliderItemType.saturation.rawValue:
                saturation = Double(sliderItem.value)
                break
                
            default:break
            }
        }
        
        guard let videoAssetStr = Bundle.main.path(forResource: self.videoName, ofType: "") else {
            return
        }
        let videoAssetUrl = NSURL(fileURLWithPath: videoAssetStr) as URL
        /* ========== [显示]过渡动画,[关闭]用户交互 start ==========  */
        kMainWindow?.isUserInteractionEnabled = false
        self.view.makeToastActivity(.center)
        /* ========== [显示]过渡动画,[关闭]用户交互 end ==========  */
        self.playerBodyViewOfRender.isPlay = false
        DRNERenderVideoManager.videoRender(videoUrl: videoAssetUrl, outputName: self.videoName,
                                           brightness: brightness, inputContrast: contrast, saturation: saturation) { outputPath in
            /* ========== [隐藏]过渡动画,[开启]用户交互 start ==========  */
            kMainWindow?.isUserInteractionEnabled = true
            self.view.hideToastActivity()
            /* ========== [隐藏]过渡动画,[开启]用户交互 end ==========  */
            
            guard let outputPath = outputPath else {
                return
            }
            
            let avAssetUrl = NSURL(fileURLWithPath: outputPath) as URL
            let avAsset = AVAsset(url: avAssetUrl)
            self.playerBodyViewOfRender.loadAsset(asset: avAsset)
        }
    }

    deinit {
        // 销毁 视频播放器对象
        self.playerBodyViewOfOriginal.destroy()
        // 销毁 视频播放器对象
        self.playerBodyViewOfRender.destroy()
    }
}


struct sliderItemModel {
    ///
    let name: String
    ///
    let minValue: Float
    ///
    let maxValue: Float
    ///
    let defaultValue: Float
    ///
    let itemTag: DRNESliderItemType
}
enum DRNESliderItemType: NSInteger {
    /// 光照强度
    case brightness = 101
    /// 对比度
    case contrast = 102
    /// 鲜明度
    case saturation = 103
}
