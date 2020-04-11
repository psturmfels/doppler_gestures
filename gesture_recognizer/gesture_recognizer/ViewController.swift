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
    let microphone: AKMicrophone = AKMicrophone()!
    var audioInputPlot: EZAudioPlot!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button: UIButton = UIButton(type: UIButton.ButtonType.system)
        button.frame = CGRect(origin: self.view.center, size: CGSize(width: 200.0, height: 50.0))
        button.center = self.view.center
        
        button.setTitle("Play Tone", for: UIControl.State.normal)
        if let title = button.titleLabel {
            title.font = UIFont.systemFont(ofSize: 32.0)
        }
        
        button.addTarget(self, action: #selector(button_tapped), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(button_down), for: UIControl.Event.touchDown)
        button.addTarget(self, action: #selector(button_up), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(button_up), for: UIControl.Event.touchUpOutside)
        self.view.addSubview(button)
        
        oscillator.frequency = 300
        oscillator.amplitude = 0.5
        
        let tracker: AKFrequencyTracker = AKFrequencyTracker(microphone, hopSize: 2048, peakCount: 20)
        let silence: AKBooster = AKBooster(tracker, gain: 0)
        AudioKit.output = silence
        
        
        
        do {
            try AudioKit.start()
        } catch {
            print("Unexpected error starting audio engine: \(error)")
        }
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

