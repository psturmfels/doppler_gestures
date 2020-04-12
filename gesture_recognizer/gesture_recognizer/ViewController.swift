//
//  ViewController.swift
//  gesture_recognizer
//
//  Created by Pascal Sturmfels on 4/8/20.
//  Copyright © 2020 LooseFuzz. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI

class ViewController: UIViewController {
    let oscillator: AKOscillator = AKOscillator()
    var microphone: AKMicrophone!
    var micCopy1: AKBooster!
    var micCopy2: AKBooster!
    var audioInputPlot: EZAudioPlot!
    var audioFFTPlot: AKNodeFFTPlot!
    
    var amplitudeTap: AKAmplitudeTap!
    private let bufferSize: UInt32 = 2_048
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudioNodes()
        tapAudioNodes()
        createPlayButton()
        createPlots()
        
        do {
            try AudioKit.start()
        } catch {
            print("Unexpected error starting audio engine: \(error)")
        }
    }
    
    func tapAudioNodes() {
        microphone.avAudioUnitOrNode.installTap(onBus: 0,
                                                bufferSize: bufferSize,
                                                format: AudioKit.format,
                                                block: handleTapBlock)
    }
    
    private func handleTapBlock(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard let floatData: UnsafePointer = buffer.floatChannelData else { return }

        let channelCount = Int(buffer.format.channelCount)
        let length = UInt(buffer.frameLength)

        let samples: Array = Array(UnsafeBufferPointer(start: $))
        
        //        TODO: Check out this link
        //        https://stackoverflow.com/questions/50805268/audiokit-how-to-get-real-time-floatchanneldata-from-microphone
        //        https://github.com/AudioKit/AudioKit/tree/master/AudioKit/Common/Taps
    }
    
    func setupAudioNodes() {
        AKSettings.audioInputEnabled = true
        oscillator.frequency = 3000
        oscillator.amplitude = 1.0
        
        microphone = AKMicrophone()
        
        micCopy1 = AKBooster(microphone)
        micCopy2 = AKBooster(microphone)
        
        let tracker: AKFrequencyTracker = AKFrequencyTracker(microphone, hopSize: 4096, peakCount: 20)
        let silence: AKBooster = AKBooster(tracker, gain: 0)

        let mixer: AKMixer = AKMixer(oscillator, silence)
        AudioKit.output = mixer
        AudioKit.output = oscillator
    }
    
    func createPlayButton() {
        let button: UIButton = UIButton(type: UIButton.ButtonType.system)
        button.frame = CGRect(origin: self.view.center, size: CGSize(width: 200.0, height: 50.0))
        button.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 200.0)
        
    
        button.setTitle("Play Tone", for: UIControl.State.normal)
        if let title = button.titleLabel {
            title.font = UIFont.systemFont(ofSize: 32.0)
        }
        
        button.addTarget(self, action: #selector(receiveButtonTapped), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(receiveButtonDown), for: UIControl.Event.touchDown)
        button.addTarget(self, action: #selector(receiveButtonUp), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(receiveButtonUp), for: UIControl.Event.touchUpOutside)
        self.view.addSubview(button)
    }
    
    func createPlots() {
        let plotSize: CGSize = CGSize(width: self.view.frame.width - 50.0, height: 200.0)
        audioInputPlot = EZAudioPlot(frame: CGRect(origin: CGPoint.zero, size: plotSize))
        audioInputPlot.center = self.view.center

        let plot: AKNodeOutputPlot = AKNodeOutputPlot(micCopy1, frame: audioInputPlot.bounds)
        plot.plotType = EZPlotType.rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.systemBlue
        audioInputPlot.addSubview(plot)
        self.view.addSubview(audioInputPlot)
        
        audioFFTPlot = AKNodeFFTPlot(micCopy2, frame: CGRect(origin: CGPoint.zero, size: plotSize), bufferSize: 2048)
        audioFFTPlot.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 200.0)
        audioFFTPlot.shouldFill = true
        audioFFTPlot.shouldMirror = false
        audioFFTPlot.shouldCenterYAxis = false
        audioFFTPlot.color = AKColor.purple
        audioFFTPlot.gain = 100
        self.view.addSubview(audioFFTPlot)
        
    }
    
    @objc func receiveButtonDown() {
        oscillator.start()
    }
    
    @objc func receiveButtonUp() {
        oscillator.stop()
    }

    @objc func receiveButtonTapped() {
    }

}

