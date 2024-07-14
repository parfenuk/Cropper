//
//  CropViewController.swift
//  Cropper
//
//  Created by Miraslau Parafeniuk on 28.05.24.
//

import Cocoa
import AVFoundation

class CropViewController: NSViewController, NSDraggingDestination {
    
    enum AudioChannel: Int {
        case full = 1
        case cropped = 2
        
        var toggled: AudioChannel {
            switch self {
            case .full: .cropped
            case .cropped: .full
            }
        }
    }
    
    enum Status {
        case ok
        case error(String)
    }
    
    let FM = FileManager.default
    let STEP = 0.05
    
    var audioPlayer = AVAudioPlayer()
    var timer = Timer()

    @IBOutlet weak var underlayView: DragAcceptingView!
    @IBOutlet weak var slFull: NSSlider!
    @IBOutlet weak var slCropped: NSSlider!
    @IBOutlet weak var slVolume: NSSlider!
    @IBOutlet weak var slOutputChannelVolume: NSSlider!
    @IBOutlet weak var btnPlay1: NSButton!
    @IBOutlet weak var btnPlay2: NSButton!
    @IBOutlet weak var cbVolumeIncrease: NSButton!
    @IBOutlet weak var stepperFadeIn: NSStepper!
    @IBOutlet weak var stepperFadeOut: NSStepper!
    @IBOutlet weak var tfDurationTime: NSTextField!
    @IBOutlet weak var tfCurrentTime: NSTextField!
    @IBOutlet weak var tfFrom: NSTextField!
    @IBOutlet weak var tfTo: NSTextField!
    @IBOutlet weak var tfFadeIn: NSTextField!
    @IBOutlet weak var tfFadeOut: NSTextField!
    @IBOutlet weak var tfSaveStatus: NSTextField!
    @IBOutlet weak var tfFolderName: NSTextField! // folder where to save
    @IBOutlet weak var tfFileName: NSTextField! // how to name for saving
    
    var openPanelFolderPath = "" // last successfully chosen from open panel
    var fullFilePath = ""
    var secondPlayerOffset: Double = 0 // in seconds
    var currentChannel = AudioChannel.full// playing first slider or the second one
    
    override func viewDidLoad() {
        super.viewDidLoad()

        underlayView.parent = self
    }
    
    var currentVolumeCoef: Float {
        cbVolumeIncrease.state == .on
        ? Float(1 + slOutputChannelVolume.doubleValue/25)
        : Float(slOutputChannelVolume.doubleValue/100)
    }
    
    private func changeControlStates() {
        btnPlay1.isEnabled = currentChannel == .full
        btnPlay2.isEnabled = currentChannel == .cropped
        slFull.isEnabled = currentChannel == .full
        slCropped.isEnabled = currentChannel == .cropped
    }
    
    func activate(_ channel: AudioChannel) {
        switch channel {
        case .full:
            currentChannel = channel
            changeControlStates()
            slFull.minValue = 0
            slFull.maxValue = audioPlayer.duration
            tfCurrentTime.stringValue = "0.00"
            tfDurationTime.stringValue = slFull.maxValue.roundedDown(precision: 3)
        case .cropped:
            var d1 = tfFrom.doubleValue, d2 = tfTo.doubleValue
            if d1 < 0 { d1 = 0 }
            if d2 == 0 || d2 > audioPlayer.duration { d2 = audioPlayer.duration }
            if d1 >= d2 { return }
            
            currentChannel = channel
            changeControlStates()
            slCropped.minValue = d1
            slCropped.maxValue = d2
            audioPlayer.currentTime = slCropped.minValue
            tfCurrentTime.stringValue = "0.00"
            tfDurationTime.stringValue = (d2-d1).roundedDown(precision: 3)
            tfFrom.stringValue = d1.roundedDown(precision: 2)
            tfTo.stringValue = d2.roundedDown(precision: 2)
        }
    }
    
    func didLoadFile(from path: String) {
        
        // Reset to default parameters
        [stepperFadeIn, stepperFadeOut].forEach { $0?.doubleValue = 0 }
        [tfFadeIn, tfFadeOut].forEach { $0?.stringValue = "0.0" }
        slOutputChannelVolume.doubleValue = 100
        cbVolumeIncrease.state = .off
        cbVolumeIncrease.title = "Vol coef 1.00"

        fullFilePath = path
        guard let slash = fullFilePath.range(of: "/", options: .backwards),
        let dot = fullFilePath.range(of: ".", options: .backwards)
        else { return }
        
        openPanelFolderPath = String(fullFilePath[..<slash.lowerBound])
        let songName = String(fullFilePath[slash.upperBound..<dot.lowerBound])
        tfFolderName.stringValue = songName
        tfFileName.stringValue = songName
        
        loadAudioFile()
    }
    
    func loadAudioFile() {
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: NSURL.fileURL(withPath: fullFilePath) as URL)
        } catch (let error) {
            reportStatus(.error(error.localizedDescription))
            return
        }
        
        audioPlayer.volume = Float(slVolume.doubleValue / 100)
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updatePlaybackInfo), userInfo: nil, repeats: true)
        tfFrom.stringValue = ""
        tfTo.stringValue = ""
        activate(.full)
    }
    
    @objc func updatePlaybackInfo() {
        switch currentChannel {
        case .full:
            slFull.doubleValue = audioPlayer.currentTime
            tfCurrentTime.stringValue = audioPlayer.currentTime.roundedDown(precision: 2)
        case .cropped:
            slCropped.doubleValue = audioPlayer.currentTime
            tfCurrentTime.stringValue = (slCropped.doubleValue - slCropped.minValue).roundedDown(precision: 2)
            if slCropped.doubleValue == slCropped.maxValue { audioPlayer.pause() }
        }
    }
    
    @IBAction func onCheckBoxToggle(_ sender: NSButton) {
        if sender == cbVolumeIncrease {
            cbVolumeIncrease.title = String(format: "Vol coef %.2f", currentVolumeCoef)
        }
    }
    
    @IBAction func valueChanged(_ sender: NSSlider) {
        switch sender {
        case slFull:
            audioPlayer.currentTime = slFull.doubleValue
            tfCurrentTime.stringValue = audioPlayer.currentTime.roundedDown(precision: 2)
        case slCropped:
            audioPlayer.currentTime = slCropped.doubleValue
            tfCurrentTime.stringValue = (slCropped.doubleValue - slCropped.minValue)
                .roundedDown(precision: 2)
            if slCropped.doubleValue == slCropped.maxValue { audioPlayer.pause() }
        case slVolume:
            audioPlayer.volume = Float(slVolume.doubleValue / 100)
        case slOutputChannelVolume:
            if cbVolumeIncrease.state == .off {
                audioPlayer.volume = Float(slOutputChannelVolume.doubleValue / 100)
                slVolume.doubleValue = slOutputChannelVolume.doubleValue
            }
            cbVolumeIncrease.title = String(format: "Vol coef %.2f", currentVolumeCoef)
        default: break
        }
    }
    
    @IBAction func stepperValueChanged(_ sender: NSStepper) {
        switch sender {
        case stepperFadeIn:
            tfFadeIn.stringValue = "\(sender.doubleValue / 2)"
        case stepperFadeOut:
            tfFadeOut.stringValue = "\(sender.doubleValue / 2)"
        default: break
        }
    }
    
    @IBAction func actPlayOrPause(_ sender: NSButton) {
        if audioPlayer.isPlaying { audioPlayer.pause() }
        else { audioPlayer.play() }
    }

    @IBAction func actCrop(_ sender: NSButton) {
        if audioPlayer.isPlaying { audioPlayer.stop() }
        activate(currentChannel.toggled)
    }

    @IBAction func actOpen(_ sender: NSButton) {
        
        let panel = NSOpenPanel()
        let response = panel.runModal()
        
        if response == .OK {
            if panel.url?.absoluteString.hasPrefix("file://") != true {
                reportStatus(.error("Chosen object is not from file system"))
            } else {
                didLoadFile(from: panel.url!.path(percentEncoded: false))
            }
        }
    }

    @IBAction func actSetTime(_ sender: NSButton) {
        switch sender.tag {
        case 1: tfFrom.stringValue = String(format:"%.2f", tfCurrentTime.doubleValue)
        case 2: tfTo.stringValue   = String(format:"%.2f", tfCurrentTime.doubleValue)
        default: break
        }
    }

    @IBAction func actChangeTimeRange(_ sender: NSButton) {
        
        var d1 = tfFrom.doubleValue, d2 = tfTo.doubleValue
        switch sender.tag {
        case 1: d1 += STEP
        case 2: d1 -= STEP
        case 3: d2 += STEP
        case 4: d2 -= STEP
        default: break
        }
        if currentChannel == .cropped { 
            tfDurationTime.stringValue = String(format: "%.2f", d2-d1)
        }
        tfFrom.stringValue = String(format: "%.2f", d1)
        tfTo.stringValue = String(format: "%.2f", d2)
        slCropped.minValue = d1
        slCropped.maxValue = d2
    }
    
    func reportStatus(_ status: Status) {
        switch status {
        case .ok:
            tfSaveStatus.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.tfSaveStatus.isHidden = true
            }
        case .error(let message):
            let alert = NSAlert()
            alert.accessoryView = NSView(frame: NSMakeRect(0, 0, 400, 100))
            alert.messageText = message
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    @IBAction func actSave(_ sender: NSButton) {
        
        let folderPath = "\(openPanelFolderPath)/\(tfFolderName.stringValue)"
        if !FM.fileExists(atPath: folderPath) {
            do {
                try FM.createDirectory(atPath: folderPath, withIntermediateDirectories: false)
            } catch (let error) {
                reportStatus(.error(error.localizedDescription))
                return
            }
        }
        
        let writingPath = sender.tag == 1
        ? "\(folderPath)/\(tfFileName.stringValue).m4a"
        : "\(folderPath)/\(tfFileName.stringValue)_A.m4a"
        
        let inputUrl = NSURL.fileURL(withPath: fullFilePath)
        let outputUrl = NSURL.fileURL(withPath: writingPath)
        if FM.fileExists(atPath: writingPath) {
            try! FM.removeItem(atPath: writingPath)
        }
        
        let asset = AVURLAsset(url: inputUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        guard let track = asset.tracks(withMediaType: .audio).first else { return }
        
        let startTime = CMTimeMake(value: Int64(tfFrom.doubleValue*100), timescale: 100)
        let endTime = CMTimeMake(value: Int64(tfTo.doubleValue*100), timescale: 100)
        let duration = CMTimeSubtract(endTime, startTime)
        
        let volumeParam = AVMutableAudioMixInputParameters(track: track)
        volumeParam.trackID = track.trackID
        volumeParam.setVolume(currentVolumeCoef, at: .zero)
        
        if stepperFadeIn.integerValue > 0 {
            let fadeInDuration = CMTime(seconds: stepperFadeIn.doubleValue / 2, preferredTimescale: 100)
            volumeParam.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: currentVolumeCoef, timeRange: CMTimeRange(start: startTime, duration: fadeInDuration))
        }
        if stepperFadeOut.integerValue > 0 {
            let fadeOutDuration = CMTime(seconds: stepperFadeOut.doubleValue / 2, preferredTimescale: 100)
            volumeParam.setVolumeRamp(fromStartVolume: currentVolumeCoef, toEndVolume: 0.0, timeRange: CMTimeRange(start: CMTimeSubtract(endTime, fadeOutDuration), duration: fadeOutDuration))
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [volumeParam]
        
        let session = AVAssetExportSession(asset: asset, 
                                           presetName: AVAssetExportPresetAppleM4A)
        session?.outputURL = outputUrl
        session?.outputFileType = .m4a
        session?.audioMix = audioMix
        session?.timeRange = CMTimeRange(start: startTime, duration: duration)
        
        session?.exportAsynchronously(completionHandler: {
            switch session?.status {
            case .completed:
                DispatchQueue.main.async { [weak self] in
                    self?.reportStatus(.ok)
                }
            case .failed:
                DispatchQueue.main.async { [weak self] in
                    self?.reportStatus(.error(session?.error?.localizedDescription ?? "Unknown error"))
                }
            default: break
            }
        })
    }
}

