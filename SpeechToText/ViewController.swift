//
//  ViewController.swift
//  SpeechToText
//
//  Created by Victor Lee on 6/2/17.
//  Copyright © 2017 VictorLee. All rights reserved.
//

import UIKit
import Speech
import AVFoundation



class ViewController: UIViewController, SFSpeechRecognitionTaskDelegate, SFSpeechRecognizerDelegate {
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    var audioEngine: AVAudioEngine!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?

    @IBOutlet var microphoneButton: UIButton!
    
    @IBOutlet var textView: UITextView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self
        
        self.microphoneButton.layer.cornerRadius = 10
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            OperationQueue.main.addOperation {
                switch authStatus {
                    
                case .authorized:
                    self.microphoneButton.isEnabled = true
                    
                case .denied:
                    self.microphoneButton.isEnabled = false
                    self.textView.text = "User denied access to speech recognizer"
                    print("User denied access to speech recognizer")
                    
                case .notDetermined:
                    self.microphoneButton.isEnabled = false
                    self.textView.text = "User not yet authorized"
                    print("Speech recognizer not yet authorized")
                    
                case .restricted:
                    self.microphoneButton.isEnabled = false
                    self.textView.text = "User not authorized"
                    print("Speeceh recognizer not authorized on this device")
                    break
                    
                }
            }
        }
        
        
        
    }
    
    
    func startRecording() throws {
        
        guard let node = self.audioEngine.inputNode else {
            print("Audio engine has no input mode.")
            return
        }
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
        } catch {
            print("AudioEngine coud not start because of an error")
        }
        self.textView.text = "Say something! I am waiting to record."
        
        
        if self.recognitionTask != nil {
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
        } else {
            self.recognitionTask?.finish()
        }
        
        // Get an instance of AVAudioEngine and set up an audio session
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            self.textView.text = "audioSEssion properties were not set because of an error."
            print("audioSEssion properties were not set because of an error.")
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        
        
        guard self.recognitionRequest != nil else {
            print("Unable to create an SFSpeechAudioBufferRecognitionRequest object.")
            return
        }
        
        self.recognitionRequest?.shouldReportPartialResults = true
        self.recognitionTask = self.speechRecognizer?.recognitionTask(with: self.recognitionRequest!, resultHandler: { (result, error) in
            var isFinal = false
            if let error = error {
                print("there was an error: \(error)")
                self.audioEngine.stop()
                node.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = false
            } else if result != nil || isFinal {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
        })
        
        
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.microphoneButton.isEnabled = true
        }else {
            self.microphoneButton.isEnabled = false
            
        }
    }
    
    
    
    
    
    
    func cancelRecording() {
        audioEngine.stop()
        self.recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        self.microphoneButton.isEnabled = false
    }
    
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            cancelRecording()
            microphoneButton.setTitle("Start Recording", for: .normal)
        }else {
            try? startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
        
    }

}

