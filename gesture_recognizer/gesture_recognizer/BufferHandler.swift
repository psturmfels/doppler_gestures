//
//  BufferHandler.swift
//  gesture_recognizer
//
//  Created by Pascal Sturmfels on 4/12/20.
//  Copyright © 2020 LooseFuzz. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI

class BufferHandler: NSObject, EZAudioFFTDelegate {
    internal var bufferSize: UInt32?
    internal var tappedNode: AVAudioNode?
    internal var fft: EZAudioFFT?
    internal var targetIndex: Int?
    internal let windowSize: Int = 6
    var parentViewController: ViewController?
    internal var movingAverageRatio: [Float] = Array.init(repeating: 0.0, count: 5)
    
    init(nodeToTap: AVAudioNode, withBufferSize bufferSize: UInt32, andTargetFrequency targetFrequency: Float = 18000.0) {
        super.init()
        
        self.tappedNode = nodeToTap
        self.bufferSize = bufferSize
        self.fft = EZAudioFFT(maximumBufferSize: vDSP_Length(bufferSize),
                              sampleRate: Float(AKSettings.sampleRate),
                              delegate: self)
        
        self.targetIndex = Int(round(targetFrequency * Float(bufferSize) / Float(AKSettings.sampleRate)))
    }
    
    func startTap() {
        guard let bufferSize = self.bufferSize else { return }
        guard let tappedNode = self.tappedNode else { return }
        
        tappedNode.installTap(onBus: 0,
                              bufferSize: bufferSize,
                              format: AudioKit.format,
                              block: { [weak self] (buffer, time) in
                                guard let strongSelf = self else { return }
                                strongSelf.handleTapBlock(buffer: buffer, at: time)
        })
    }
    
    func handleTapBlock(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        let bufferData: [[Float]]? = self.PCMBufferToFloatArray(buffer)
        guard let tappedData = bufferData else { return }
        
        let firstChannelData: [Float] = tappedData[0]
        let secondChannelData: [Float] = tappedData[1]
        
        var meanChannelData: [Float] = Array.init(repeating: 0.0, count: firstChannelData.count)
        for index in 0..<firstChannelData.count {
            meanChannelData[index] = (firstChannelData[index] + secondChannelData[index]) * 0.5
        }
        
        guard let existingFFT = self.fft else {return}
        guard let bufferSize = self.bufferSize else { return }
        
        existingFFT.computeFFT(withBuffer: &meanChannelData, withBufferSize: bufferSize)
    }
    
    func PCMBufferToFloatArray(_ pcmBuffer: AVAudioPCMBuffer) -> [[Float]]? {
        guard let bufferSize = self.bufferSize else { return nil }
        let intBufferSize: Int = Int(bufferSize)
        
        if let floatChannelData = pcmBuffer.floatChannelData {
            let channelCount: Int = Int(pcmBuffer.format.channelCount)
            let stride: Int = pcmBuffer.stride
            
            let offset: Int = Int(pcmBuffer.frameCapacity) - intBufferSize
            var result: [[Float]] = Array(repeating: Array(repeating: 0.0, count: intBufferSize), count: channelCount)
            
            for channel in 0..<channelCount {
                for sampleIndex in 0..<intBufferSize {
                    result[channel][sampleIndex] = floatChannelData[channel][(sampleIndex + offset) * stride]
                }
            }
            return result
        } else {
            print("Unable to unwrap floatChannelData from the audio data buffer.")
            return nil
        }
    }
    
    @objc open func fft(_ fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>!, bufferSize: vDSP_Length) {
        var frequencyArray: [Float] = Array.init(repeating: 0.0, count: Int(bufferSize))
        for i in 0..<frequencyArray.count {
            frequencyArray[i] = Float(fftData[i])
        }
        
        guard let targetIndex = self.targetIndex else { return }
        
        let sumLower: Float = frequencyArray[(targetIndex - windowSize)..<targetIndex].reduce(0.0, +)
        let sumUpper: Float = frequencyArray[(targetIndex + 1)...(targetIndex + windowSize)].reduce(0.0, +)
        let ratio: Float = sumLower / sumUpper
        
        for i in 1..<movingAverageRatio.count {
            movingAverageRatio[i] = movingAverageRatio[i - 1]
        }
        movingAverageRatio[0] = ratio
        let averageRatio: Float = movingAverageRatio.reduce(0.0, +) / Float(movingAverageRatio.count)
//        print(ratio)
//        print(fft.maxFrequencyMagnitude, frequencyArray[Int(fft.maxFrequencyIndex)], frequencyArray[targetIndex])
//        print(fft.maxFrequency, fft.maxFrequencyIndex, fft.maxFrequencyMagnitude, targetIndex)
        
        if let parent = self.parentViewController {
            DispatchQueue.main.async {
                parent.updateText(dopplerRatio: averageRatio)
            }
        }
    }
}
