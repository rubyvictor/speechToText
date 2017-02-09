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



class ViewController: UIViewController, SFSpeechRecognitionTaskDelegate, SFSpeechRecognizerDelegate, UITextViewDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @IBOutlet var microphoneButton: UIButton!
    
    @IBOutlet var textView: UITextView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.delegate = self
        self.microphoneButton.isEnabled = false
        self.microphoneButton.layer.cornerRadius = 10
        
    }
    
    
    public override func viewDidAppear(_ animated: Bool) {
        speechRecognizer?.delegate = self
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
   
    
    private func startRecording() throws {
        //1
        if self.recognitionTask != nil {
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
        } else {
            self.recognitionTask?.finish()
        }
        
        //2 Get an instance of AVAudioEngine and set up an audio session
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            self.textView.text = "audioSEssion properties were not set because of an error."
            print("audioSEssion properties were not set because of an error.")
        }
        //3
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let node = self.audioEngine.inputNode else {
            print("Audio engine has no input mode.")
            return
        }
        
        guard self.recognitionRequest != nil else {
            print("Unable to create an SFSpeechAudioBufferRecognitionRequest object.")
            return
        }
        
        self.recognitionRequest?.shouldReportPartialResults = true
        //4
        self.recognitionTask = self.speechRecognizer?.recognitionTask(with: self.recognitionRequest!) { (result, error) in
            var isFinal = false
            
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("There was an error: \(error)")
                self.audioEngine.stop()
                node.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = false
                self.microphoneButton.setTitle("Start Recording", for: [])
            }
        //5
        let recordingFormat = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        //6
        self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
        } catch {
            print("AudioEngine coud not start because of an error")
        }
        self.textView.text = "Say something! I am listening."

        
        }
        
    }
    
    //7
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.microphoneButton.isEnabled = true
            self.microphoneButton.setTitle("Start Recording", for: [])
        }else {
           self.microphoneButton.isEnabled = false
            self.microphoneButton.setTitle("No Recognition", for: .disabled)
            
        }
    }
    
    func cancelRecording() {
        audioEngine.stop()
        self.recognitionRequest?.endAudio()
        self.microphoneButton.isEnabled = false
    }
    
    //8
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            cancelRecording()
            self.microphoneButton.setTitle("Ending...", for: .disabled)
            
        }else {
            try! startRecording()
            self.microphoneButton.setTitle("Stop Recording", for: .normal)
        }
        
    }

}

