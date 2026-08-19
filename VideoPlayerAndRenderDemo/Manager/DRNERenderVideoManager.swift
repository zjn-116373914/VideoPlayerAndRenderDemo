//
//  DRNERenderVideoManager.swift
//  ImageRenderTool
//
//  Created by zjn on 2026/8/19.
//  Copyright © 2026 zjn. All rights reserved.
//

import UIKit
import AVFoundation

class DRNERenderVideoManager: NSObject {
    static func videoRender(videoUrl: URL, outputName: String,
                            brightness: CGFloat, inputContrast: CGFloat, saturation: CGFloat,
                            completion: ((String?) -> Void)? = nil) {
        let avAsset = AVAsset(url: videoUrl)
        
        guard let filter = CIFilter(name: "CIColorControls") else {
            completion?(nil)
            return
        }
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(inputContrast, forKey: kCIInputContrastKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        let coreImageContext = CIContext(options: [.workingColorSpace: NSNull()])
        let videoComposition = AVVideoComposition(asset: avAsset) { request in
            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)
            let output = (filter.outputImage ?? request.sourceImage).cropped(to: request.sourceImage.extent)
            request.finish(with: output, context: coreImageContext)
        }
        
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion?(nil)
            return
        }
        let tempPath = NSTemporaryDirectory()
        let outputPath = "\(tempPath)\(outputName)"
        var isDirectory: ObjCBool = false
        let isExist = FileManager.default.fileExists(atPath: outputPath, isDirectory: &isDirectory)
        if (isExist == true && isDirectory.boolValue == false) {
            do {
                try FileManager.default.removeItem(atPath: outputPath)
            } catch {
                completion?(nil)
                return
            }
        }
        
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .failed:
                completion?(nil)
                break
            case .cancelled:
                completion?(nil)
                break
            case .completed:
                DispatchQueue.main.async {
                    completion?(outputPath)
                }
                break
            default:break
            }
        }
    }
}
