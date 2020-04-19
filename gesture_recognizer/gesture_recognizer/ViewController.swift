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
    var bufferHandler: BufferHandler!
    var text: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudioNodes()
//        createPlots()
        setupText()
        
        do {
            try AudioKit.start()
        } catch {
            print("Unexpected error starting audio engine: \(error)")
        }
        
        oscillator.start()
    }
    
    func setupText() {
        self.text = UITextView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: 100)))
        self.text.center = self.view.center
        self.text.textAlignment = NSTextAlignment.center
        self.text.text = ""
        self.text.font = UIFont.systemFont(ofSize: 64, weight: UIFont.Weight.medium)
        self.view.addSubview(self.text)
    }
    
    func updateText(dopplerRatio: Float) {
        if dopplerRatio < 0.8 {
            self.text.text = "Push"
        } else if dopplerRatio > 2.0 {
            self.text.text = "Pull"
        } else {
            self.text.text = ""
        }
    }

    func setupAudioNodes() {
        AKSettings.audioInputEnabled = true
        oscillator.frequency = 18000
        oscillator.amplitude = 1.0
        
        microphone = AKMicrophone()
        
        micCopy1 = AKBooster(microphone)
        micCopy2 = AKBooster(microphone)
        
        AudioKit.output = oscillator
        
        self.bufferHandler = BufferHandler(nodeToTap: microphone.avAudioUnitOrNode, withBufferSize: 2048)
        self.bufferHandler.startTap()
        self.bufferHandler.parentViewController = self
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

}

