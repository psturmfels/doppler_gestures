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
    var audioInputPlot: EZAudioPlot!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup_audio_nodes()
        create_play_button()
        create_plot()
        
        do {
            try AudioKit.start()
        } catch {
            print("Unexpected error starting audio engine: \(error)")
        }
    }
    
    func setup_audio_nodes() {
        AKSettings.audioInputEnabled = true
        oscillator.frequency = 3000
        oscillator.amplitude = 1.0
        
        microphone = AKMicrophone()
        let tracker: AKFrequencyTracker = AKFrequencyTracker(microphone, hopSize: 2048, peakCount: 20)
        let silence: AKBooster = AKBooster(tracker, gain: 0)

        let mixer: AKMixer = AKMixer(oscillator, silence)
        AudioKit.output = mixer
        AudioKit.output = oscillator
    }
    
    func create_play_button() {
        let button: UIButton = UIButton(type: UIButton.ButtonType.system)
        button.frame = CGRect(origin: self.view.center, size: CGSize(width: 200.0, height: 50.0))
        button.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 200.0)
        
        button.setTitle("Play Tone", for: UIControl.State.normal)
        if let title = button.titleLabel {
            title.font = UIFont.systemFont(ofSize: 32.0)
        }
        
        button.addTarget(self, action: #selector(button_tapped), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(button_down), for: UIControl.Event.touchDown)
        button.addTarget(self, action: #selector(button_up), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(button_up), for: UIControl.Event.touchUpOutside)
        self.view.addSubview(button)
    }
    
    func create_plot() {
        let plotSize: CGSize = CGSize(width: self.view.frame.width - 50.0, height: 200.0)
        audioInputPlot = EZAudioPlot(frame: CGRect(origin: CGPoint.zero, size: plotSize))
        audioInputPlot.center = self.view.center

        let plot: AKNodeOutputPlot = AKNodeOutputPlot(microphone, frame: audioInputPlot.bounds)
        plot.plotType = EZPlotType.rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.systemBlue
        audioInputPlot.addSubview(plot)
        self.view.addSubview(audioInputPlot)
    }
    
    @objc func button_down() {
        oscillator.start()
    }
    
    @objc func button_up() {
        oscillator.stop()
    }

    @objc func button_tapped() {
        print("Button was tapped.")
    }

}

