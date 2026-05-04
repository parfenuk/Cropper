//
//  Tools.swift
//  Cropper
//
//  Created by Miraslau Parafeniuk on 27.07.25.
//

import Foundation
import AVFoundation

extension CropViewController {
    
    func customHardcodedActions() {
        
//        func save(code: String, volume: Float, isVideo: Bool) {
//            //let baseUrl = "/Users/miraslau/Music/_For Quiz/__Tuc10s/8. Клипы (Done)/"
//            let baseUrl = "/Users/miraslau/Documents/Projects/MzgbEngine/MzgbEngine/Question Sets/Set TucTwentyTwo/" + (isVideo ? "Videos/" : "Sounds/")
//            let file = "TucTwentyTwo\(code)." + (isVideo ? "mp4" : "m4a")
//                        
//            saveVideo(inputPath: baseUrl + file,
//                      folderPath: baseUrl + "_Volumed",
//                      fileName: file,
//                      start: 0,
//                      end: 2026,
//                      volumeCoef: volume,
//                      completion: { result in
//                switch result {
//                case .success:
//                    print("Saved \(code)")
//                case .failure(let error):
//                    print("Error \(code): \(error.localizedDescription)")
//                }
//            })
//        }

        // For Blitz
//        for n in 1...10 {
//            
//            let audio = URL(fileURLWithPath: baseUrl + "/q\(n).m4a")
//            let siren = URL(fileURLWithPath: baseUrl + "/Sirens/s\(n).m4a")
//            let output = URL(fileURLWithPath: baseUrl + "/TucTwentyTwo0\(n)Q.m4a")
//            
//            mergeAudios(from: [audio, siren],
//                        outputURL: output,
//                        completion: { _ in
//                print("\(n) saved")
//            })
//            
//            saveAudio(inputPath: baseUrl + "/Sirens/Siren_1.m4a",
//                      folderPath: baseUrl + "/Sirens",
//                      fileName: "s\(n).m4a",
//                      start: 0.0,
//                      end: 0.46 + Double(10-n)*0.04,
//                      volumeCoef: 1.2,
//                      completion: { result in
//                print("Saved: s\(n).m4a")
//            })
//        }
    }
}

// MARK: - Main Functions

func saveAudio(
    inputPath: String,
    folderPath: String,
    fileName: String,
    start: Double,
    end: Double,
    volumeCoef: Float = 1.0,
    fadeIn: Double = 0.0,
    fadeOut: Double = 0.0,
    completion: @escaping (Result<Bool, Error>) -> Void
) {
    if !FM.fileExists(atPath: folderPath) {
        do {
            try FM.createDirectory(atPath: folderPath, withIntermediateDirectories: false)
        } catch (let error) {
            completion(.failure(error))
            return
        }
    }
    
    let writingPath = "\(folderPath)/\(fileName)"
    
    let inputUrl = NSURL.fileURL(withPath: inputPath)
    let outputUrl = NSURL.fileURL(withPath: writingPath)
    if FM.fileExists(atPath: writingPath) {
        try! FM.removeItem(atPath: writingPath)
    }
    
    let asset = AVURLAsset(url: inputUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    guard let track = asset.tracks(withMediaType: .audio).first else { return }
    
    // Get asset duration and clamp start/end to valid bounds
    let assetDuration = asset.duration.seconds
    let clampedStart = max(0, min(start, assetDuration))
    let clampedEnd = max(clampedStart, min(end, assetDuration))
    
    let startTime = CMTime(seconds: clampedStart, preferredTimescale: 600)
    let endTime = CMTime(seconds: clampedEnd, preferredTimescale: 600)
    let duration = CMTimeSubtract(endTime, startTime)
    
    let audioParam = AVMutableAudioMixInputParameters(track: track)
    audioParam.trackID = track.trackID
    audioParam.setVolume(volumeCoef, at: .zero)
    
    if fadeIn > 0 {
        let fadeInDuration = CMTime(seconds: fadeIn, preferredTimescale: 100)
        audioParam.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: volumeCoef, timeRange: CMTimeRange(start: startTime, duration: fadeInDuration))
    }
    if fadeOut > 0 {
        let fadeOutDuration = CMTime(seconds: fadeOut, preferredTimescale: 100)
        audioParam.setVolumeRamp(fromStartVolume: volumeCoef, toEndVolume: 0.0, timeRange: CMTimeRange(start: CMTimeSubtract(endTime, fadeOutDuration), duration: fadeOutDuration))
    }
    
    let audioMix = AVMutableAudioMix()
    audioMix.inputParameters = [audioParam]
    
    let session = AVAssetExportSession(asset: asset,
                                       presetName: AVAssetExportPresetAppleM4A)
    session?.outputURL = outputUrl
    session?.outputFileType = .m4a
    session?.audioMix = audioMix
    session?.timeRange = CMTimeRange(start: startTime, duration: duration)
    
    session?.exportAsynchronously(completionHandler: {
        switch session?.status {
        case .completed:
            DispatchQueue.main.async {
                completion(.success(true))
            }
        case .failed:
            DispatchQueue.main.async {
                completion(.failure(session?.error ?? NSError(domain: "Unknown error", code: -1)))
            }
        default: break
        }
    })
}

func saveVideo(
    inputPath: String,
    folderPath: String,
    fileName: String,
    start: Double,
    end: Double,
    volumeCoef: Float = 1.0,
    fadeInAudio: Double = 0.0,
    fadeOutAudio: Double = 0.0,
    fadeInVideo: Double = 0.0,
    fadeOutVideo: Double = 0.0,
    completion: @escaping (Result<Bool, Error>) -> Void
) {
    if !FM.fileExists(atPath: folderPath) {
        do {
            try FM.createDirectory(atPath: folderPath, withIntermediateDirectories: false)
        } catch (let error) {
            completion(.failure(error))
            return
        }
    }
    
    let writingPath = "\(folderPath)/\(fileName)"
    
    let inputUrl = NSURL.fileURL(withPath: inputPath)
    let outputUrl = NSURL.fileURL(withPath: writingPath)
    if FM.fileExists(atPath: writingPath) {
        try! FM.removeItem(atPath: writingPath)
    }
    
    let asset = AVURLAsset(url: inputUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    
    // Get asset duration and clamp start/end to valid bounds
    let assetDuration = asset.duration.seconds
    let clampedStart = max(0, min(start, assetDuration))
    let clampedEnd = max(clampedStart, min(end, assetDuration))
    
    let startTime = CMTime(seconds: clampedStart, preferredTimescale: 600)
    let endTime = CMTime(seconds: clampedEnd, preferredTimescale: 600)
    let duration = CMTimeSubtract(endTime, startTime)
    
    // Setup audio mix
    var audioMixParams: [AVMutableAudioMixInputParameters] = []
    if let audioTrack = asset.tracks(withMediaType: .audio).first {
        let audioParam = AVMutableAudioMixInputParameters(track: audioTrack)
        audioParam.trackID = audioTrack.trackID
        audioParam.setVolume(volumeCoef, at: .zero)
        
        if fadeInAudio > 0 {
            let fadeInDuration = CMTime(seconds: fadeInAudio, preferredTimescale: 100)
            audioParam.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: volumeCoef, timeRange: CMTimeRange(start: startTime, duration: fadeInDuration))
        }
        if fadeOutAudio > 0 {
            let fadeOutDuration = CMTime(seconds: fadeOutAudio, preferredTimescale: 100)
            audioParam.setVolumeRamp(fromStartVolume: volumeCoef, toEndVolume: 0.0, timeRange: CMTimeRange(start: CMTimeSubtract(endTime, fadeOutDuration), duration: fadeOutDuration))
        }
        
        audioMixParams.append(audioParam)
    }
    
    let audioMix = AVMutableAudioMix()
    audioMix.inputParameters = audioMixParams
    
    // Setup video composition (always created to ensure proper time range mapping)
    var videoComposition: AVMutableVideoComposition? = nil
    if let videoTrack = asset.tracks(withMediaType: .video).first {
        let composition = AVMutableVideoComposition()
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        composition.renderSize = videoTrack.naturalSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: startTime, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // Apply opacity fades only if requested
        if fadeInVideo > 0 {
            let fadeInDuration = CMTime(seconds: fadeInVideo, preferredTimescale: 100)
            layerInstruction.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: CMTimeRange(start: startTime, duration: fadeInDuration))
        }
        if fadeOutVideo > 0 {
            let fadeOutDuration = CMTime(seconds: fadeOutVideo, preferredTimescale: 100)
            layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange(start: CMTimeSubtract(endTime, fadeOutDuration), duration: fadeOutDuration))
        }
        
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        videoComposition = composition
    }
    
    let session = AVAssetExportSession(asset: asset,
                                       presetName: AVAssetExportPresetHighestQuality)
    session?.outputURL = outputUrl
    session?.outputFileType = .mp4
    session?.audioMix = audioMix
    session?.videoComposition = videoComposition
    session?.timeRange = CMTimeRange(start: startTime, duration: duration)
    
    session?.exportAsynchronously(completionHandler: {
        switch session?.status {
        case .completed:
            DispatchQueue.main.async {
                completion(.success(true))
            }
        case .failed:
            DispatchQueue.main.async {
                completion(.failure(session?.error ?? NSError(domain: "Unknown error", code: -1)))
            }
        default: break
        }
    })
}

func mergeAudios(
    from audioURLs: [URL],
    outputURL: URL,
    fadeIn: Double = 0.0,
    fadeOut: Double = 0.0,
    completion: @escaping (Result<URL, Error>) -> Void
) {
    Task {
        do {
            guard !audioURLs.isEmpty else {
                completion(.failure(NSError(domain: "No audio URLs provided", code: -1)))
                return
            }
            
            // Create composition
            let composition = AVMutableComposition()
            
            guard let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                completion(.failure(NSError(domain: "Failed to create audio track", code: -2)))
                return
            }
            
            // Insert each audio file sequentially
            var currentTime = CMTime.zero
            
            for audioURL in audioURLs {
                let audioAsset = AVURLAsset(url: audioURL)
                let audioDuration = try await audioAsset.load(.duration)
                
                guard let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first else {
                    completion(.failure(NSError(domain: "Audio track not found in \(audioURL.lastPathComponent)", code: -3)))
                    return
                }
                
                // Insert audio at current position
                try compAudio.insertTimeRange(
                    CMTimeRange(start: .zero, duration: audioDuration),
                    of: audioTrack,
                    at: currentTime
                )
                
                // Move current time forward
                currentTime = CMTimeAdd(currentTime, audioDuration)
            }
            
            let totalDuration = currentTime
            
            // Create audio mix for fade effects
            let audioMix = createAudioMixWithFades(for: compAudio, totalDuration: totalDuration, fadeIn: fadeIn, fadeOut: fadeOut)
            
            // Export
            await exportComposition(composition, to: outputURL, audioMix: audioMix, preset: AVAssetExportPresetAppleM4A, outputFileType: .m4a, completion: completion)
            
        } catch {
            completion(.failure(error))
        }
    }
}

func mergeVideos(
    from videoURLs: [URL],
    outputURL: URL,
    fadeInAudio: Double = 0.0,
    fadeOutAudio: Double = 0.0,
    fadeInVideo: Double = 0.0,
    fadeOutVideo: Double = 0.0,
    completion: @escaping (Result<URL, Error>) -> Void
) {
    Task {
        do {
            guard !videoURLs.isEmpty else {
                completion(.failure(NSError(domain: "No video URLs provided", code: -1)))
                return
            }
            
            // Create composition
            let composition = AVMutableComposition()
            
            guard let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                completion(.failure(NSError(domain: "Failed to create video track", code: -2)))
                return
            }
            
            guard let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                completion(.failure(NSError(domain: "Failed to create audio track", code: -3)))
                return
            }
            
            // Insert each video file sequentially
            var currentTime = CMTime.zero
            var videoSize: CGSize = .zero
            var preferredTransform: CGAffineTransform = .identity
            
            for videoURL in videoURLs {
                let videoAsset = AVURLAsset(url: videoURL)
                let videoDuration = try await videoAsset.load(.duration)
                
                guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {
                    completion(.failure(NSError(domain: "Video track not found in \(videoURL.lastPathComponent)", code: -4)))
                    return
                }
                
                // Store first video's size and transform for composition
                if currentTime == .zero {
                    videoSize = videoTrack.naturalSize
                    preferredTransform = try await videoTrack.load(.preferredTransform)
                }
                
                // Insert video at current position
                try compVideo.insertTimeRange(
                    CMTimeRange(start: .zero, duration: videoDuration),
                    of: videoTrack,
                    at: currentTime
                )
                
                // Insert audio if available
                if let audioTrack = try await videoAsset.loadTracks(withMediaType: .audio).first {
                    try compAudio.insertTimeRange(
                        CMTimeRange(start: .zero, duration: videoDuration),
                        of: audioTrack,
                        at: currentTime
                    )
                }
                
                // Move current time forward
                currentTime = CMTimeAdd(currentTime, videoDuration)
            }
            
            let totalDuration = currentTime
            print("DUR: \(totalDuration.seconds)")
            
            // Create audio mix for fade effects
            let audioMix = createAudioMixWithFades(for: compAudio, totalDuration: totalDuration, fadeIn: fadeInAudio, fadeOut: fadeOutAudio)
            
            // Create video composition (always, to ensure proper time mapping)
            let videoComposition = AVMutableVideoComposition()
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = videoSize
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: totalDuration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideo)
            layerInstruction.setTransform(preferredTransform, at: .zero)
            
            // Apply video opacity fades only if requested
            if fadeInVideo > 0 {
                let fadeInDuration = CMTime(seconds: fadeInVideo / 2, preferredTimescale: 100)
                layerInstruction.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: CMTimeRange(start: .zero, duration: fadeInDuration))
            }
            if fadeOutVideo > 0 {
                let fadeOutDuration = CMTime(seconds: fadeOutVideo / 2, preferredTimescale: 100)
                layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange(start: CMTimeSubtract(totalDuration, fadeOutDuration), duration: fadeOutDuration))
            }
            
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]
            
            // Export
            try? FileManager.default.removeItem(at: outputURL)
            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                completion(.failure(NSError(domain: "Exporter init failed", code: -5)))
                return
            }
            
            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            exporter.audioMix = audioMix
            exporter.videoComposition = videoComposition
            exporter.shouldOptimizeForNetworkUse = true
            
            await exporter.export()
            DispatchQueue.main.async {
                switch exporter.status {
                case .completed: completion(.success(outputURL))
                default:
                    completion(.failure(exporter.error ?? NSError(domain: "Export failed", code: -6)))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }
}

func changeAudioSpeed(
    at audioURL: URL,
    rate: Float,
    outputURL: URL,
    fadeIn: Double = 0.0,
    fadeOut: Double = 0.0,
    completion: @escaping (Result<URL, Error>) -> Void
) {
    Task {
        do {
            let audioAsset = AVURLAsset(url: audioURL)
            
            // Load duration asynchronously
            let audioDuration = try await audioAsset.load(.duration)
            
            // Create composition
            let composition = AVMutableComposition()
            
            // Add audio track to composition
            guard
                let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
                let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            else {
                completion(.failure(NSError(domain: "Audio track not found", code: -1)))
                return
            }
            
            // Insert the audio track
            try compAudio.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                of: audioTrack,
                at: .zero
            )
            
            // Apply time scaling to slow down the audio
            // rate < 1.0 slows down, rate > 1.0 speeds up
            let scaledDuration = CMTimeMultiplyByFloat64(audioDuration, multiplier: Float64(1.0 / rate))
            compAudio.scaleTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                toDuration: scaledDuration
            )
            
            // Create audio mix for fade effects
            let audioMix = createAudioMixWithFades(for: compAudio, totalDuration: scaledDuration, fadeIn: fadeIn, fadeOut: fadeOut)
            
            // Export
            await exportComposition(composition, to: outputURL, audioMix: audioMix, preset: AVAssetExportPresetAppleM4A, outputFileType: .m4a, completion: completion)
            
        } catch {
            completion(.failure(error))
        }
    }
}

func changeAudioPitch(
    at audioURL: URL,
    rate: Float,
    outputURL: URL,
    fadeIn: Double = 0.0,
    fadeOut: Double = 0.0,
    completion: @escaping (Result<URL, Error>) -> Void
) {
    class PitchShiftContext {
        let rate: Float
        var audioUnit: AudioUnit?
        
        init(rate: Float) {
            self.rate = rate
        }
    }
    
    func tapInit(tap: MTAudioProcessingTap, clientInfo: UnsafeMutableRawPointer?, tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>) {
        tapStorageOut.pointee = clientInfo
    }
    
    func tapFinalize(tap: MTAudioProcessingTap) {
        let context = Unmanaged<PitchShiftContext>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeRetainedValue()
        if let audioUnit = context.audioUnit {
            AudioUnitUninitialize(audioUnit)
            AudioComponentInstanceDispose(audioUnit)
        }
    }
    
    func tapPrepare(tap: MTAudioProcessingTap, maxFrames: CMItemCount, processingFormat: UnsafePointer<AudioStreamBasicDescription>) {
        let context = Unmanaged<PitchShiftContext>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
        
        var description = AudioComponentDescription(
            componentType: kAudioUnitType_FormatConverter,
            componentSubType: kAudioUnitSubType_TimePitch,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        guard let component = AudioComponentFindNext(nil, &description) else { return }
        
        var audioUnit: AudioUnit?
        AudioComponentInstanceNew(component, &audioUnit)
        
        if let audioUnit = audioUnit {
            AudioUnitInitialize(audioUnit)
            
            // Set pitch in cents (100 cents = 1 semitone)
            let pitchInCents = Float(1200.0 * log2(Double(context.rate)))
            AudioUnitSetParameter(audioUnit, kTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitchInCents, 0)
            
            // Keep playback rate at 1.0 to maintain duration
            AudioUnitSetParameter(audioUnit, kTimePitchParam_Rate, kAudioUnitScope_Global, 0, 1.0, 0)
            
            context.audioUnit = audioUnit
        }
    }
    
    func tapUnprepare(tap: MTAudioProcessingTap) {
        // Cleanup handled in finalize
    }
    
    func tapProcess(tap: MTAudioProcessingTap, numberFrames: CMItemCount, flags: MTAudioProcessingTapFlags, bufferListInOut: UnsafeMutablePointer<AudioBufferList>, numberFramesOut: UnsafeMutablePointer<CMItemCount>, flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>) {
        let context = Unmanaged<PitchShiftContext>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
        
        var timeRange = CMTimeRange.zero
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, &timeRange, numberFramesOut)
        
        guard status == noErr, let audioUnit = context.audioUnit else { return }
        
        var ioActionFlags = AudioUnitRenderActionFlags(rawValue: 0)
        var timeStamp = AudioTimeStamp()
        
        AudioUnitRender(audioUnit, &ioActionFlags, &timeStamp, 0, UInt32(numberFrames), bufferListInOut)
    }
    
    func createPitchShiftTap(rate: Float, processingFormat: Any?) throws -> MTAudioProcessingTap {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(PitchShiftContext(rate: rate)).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: tapUnprepare,
            process: tapProcess
        )
        
        var tap: MTAudioProcessingTap?
        let err = MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PostEffects,
            &tap
        )
        
        guard err == noErr, let tap = tap else {
            throw NSError(domain: "Failed to create audio processing tap", code: Int(err))
        }
        
        return tap
    }
    
    Task {
        do {
            let audioAsset = AVURLAsset(url: audioURL)
            
            // Load duration and tracks
            let audioDuration = try await audioAsset.load(.duration)
            guard let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first else {
                completion(.failure(NSError(domain: "Audio track not found", code: -1)))
                return
            }
            
            // Create composition
            let composition = AVMutableComposition()
            guard let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                completion(.failure(NSError(domain: "Failed to create audio track", code: -2)))
                return
            }
            
            try compAudio.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                of: audioTrack,
                at: .zero
            )
            
            // Create audio mix to apply pitch shift
            let audioMix = AVMutableAudioMix()
            let audioMixParam = AVMutableAudioMixInputParameters(track: compAudio)
            
            // Create audio processing tap to change pitch
            let processingFormat = try await audioTrack.load(.formatDescriptions).first
            let audioProcessingTap = try createPitchShiftTap(
                rate: rate,
                processingFormat: processingFormat
            )
            
            audioMixParam.audioTapProcessor = audioProcessingTap
            
            // Apply fade effects
            applyFades(to: audioMixParam, totalDuration: audioDuration, fadeIn: fadeIn, fadeOut: fadeOut)
            
            audioMix.inputParameters = [audioMixParam]
            
            // Export
            await exportComposition(composition, to: outputURL, audioMix: audioMix, preset: AVAssetExportPresetAppleM4A, outputFileType: .m4a, completion: completion)
            
        } catch {
            completion(.failure(error))
        }
    }
}

func replaceAudio(
    in videoURL: URL,
    with newAudioURL: URL,
    outputURL: URL,
    fadeIn: Double = 0.0,
    fadeOut: Double = 0.0,
    completion: @escaping (Result<URL, Error>) -> Void
) {
    Task {
        do {
            let videoAsset = AVURLAsset(url: videoURL)
            let newAudioAsset = AVURLAsset(url: newAudioURL)

            // Load durations asynchronously
            let (videoDuration, newAudioDuration) = try await (
                videoAsset.load(.duration),
                newAudioAsset.load(.duration)
            )

            let T: CMTimeScale = 60000
            func toCommon(_ t: CMTime) -> CMTime { CMTimeConvertScale(t, timescale: T, method: .default) }

            let videoDurationScaled = toCommon(videoDuration)
            let newAudioDurationScaled = toCommon(newAudioDuration)

            let composition = AVMutableComposition()

            // Video track
            guard
                let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
                let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            else {
                completion(.failure(NSError(domain: "Video track not found", code: -1)))
                return
            }

            try compVideo.insertTimeRange(CMTimeRange(start: .zero, duration: videoDurationScaled),
                                          of: videoTrack,
                                          at: .zero)
            compVideo.preferredTransform = try await videoTrack.load(.preferredTransform)

            // Audio track
            let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

            let originalAudioTrack = try await videoAsset.loadTracks(withMediaType: .audio).first
            let newAudioTrack = try await newAudioAsset.loadTracks(withMediaType: .audio).first

            if let newAudioTrack {
                let durationToUse = CMTimeMinimum(videoDurationScaled, newAudioDurationScaled)
                try compAudio.insertTimeRange(CMTimeRange(start: .zero, duration: durationToUse),
                                              of: newAudioTrack,
                                              at: .zero)

                if newAudioDurationScaled < videoDurationScaled, let original = originalAudioTrack {
                    let remaining = CMTimeSubtract(videoDurationScaled, newAudioDurationScaled)
                    let sourceStart = newAudioDurationScaled
                    try compAudio.insertTimeRange(CMTimeRange(start: sourceStart, duration: remaining),
                                                  of: original,
                                                  at: sourceStart)
                }
            } else if let original = originalAudioTrack {
                try compAudio.insertTimeRange(CMTimeRange(start: .zero, duration: videoDurationScaled),
                                              of: original,
                                              at: .zero)
            }

            // Create audio mix for fade effects
            let audioMix = createAudioMixWithFades(for: compAudio, totalDuration: videoDurationScaled, fadeIn: fadeIn, fadeOut: fadeOut)

            // Create video composition (always, to ensure proper time mapping)
            let videoComposition = AVMutableVideoComposition()
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = videoTrack.naturalSize
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: videoDurationScaled)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideo)
            layerInstruction.setTransform(try await videoTrack.load(.preferredTransform), at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

            // Export
            try? FileManager.default.removeItem(at: outputURL)
            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                completion(.failure(NSError(domain: "Exporter init failed", code: -4)))
                return
            }
            
            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            exporter.audioMix = audioMix
            exporter.videoComposition = videoComposition
            exporter.shouldOptimizeForNetworkUse = true
            
            await exporter.export()
            DispatchQueue.main.async {
                switch exporter.status {
                case .completed: completion(.success(outputURL))
                default:
                    completion(.failure(exporter.error ?? NSError(domain: "Export failed", code: -2)))
                }
            }

        } catch {
            completion(.failure(error))
        }
    }
}

func replaceTailOfVideoAWithVideoB(
    videoAURL: URL,
    videoBURL: URL,
    outputURL: URL,
    fadeIn: Double = 0.0,
    fadeOut: Double = 0.0,
    completion: @escaping (URL?) -> Void
) {
    let composition = AVMutableComposition()
    let videoAAsset = AVAsset(url: videoAURL)
    let videoBAsset = AVAsset(url: videoBURL)

    guard
        let videoATrack = videoAAsset.tracks(withMediaType: .video).first,
        let audioATrack = videoAAsset.tracks(withMediaType: .audio).first,
        let videoBTrack = videoBAsset.tracks(withMediaType: .video).first
    else {
        print("Failed to get tracks")
        completion(nil)
        return
    }

    let durationA = videoAAsset.duration
    let durationB = videoBAsset.duration

    // Safety check
    guard durationA > durationB else {
        print("Video A must be longer than Video B")
        completion(nil)
        return
    }

    let replaceStartTime = CMTimeSubtract(durationA, durationB)

    // Create composition tracks
    guard
        let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
        let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    else {
        print("Failed to create composition tracks")
        completion(nil)
        return
    }

    do {
        // Video: part 1 — from start to (durationA - durationB)
        try compVideo.insertTimeRange(
            CMTimeRange(start: .zero, duration: replaceStartTime),
            of: videoATrack,
            at: .zero
        )

        // Video: part 2 — full video B, inserted at (durationA - durationB)
        try compVideo.insertTimeRange(
            CMTimeRange(start: .zero, duration: durationB),
            of: videoBTrack,
            at: replaceStartTime
        )

        // Audio: full audio from Video A
        try compAudio.insertTimeRange(
            CMTimeRange(start: .zero, duration: durationA),
            of: audioATrack,
            at: .zero
        )
    } catch {
        print("Error inserting tracks: \(error)")
        completion(nil)
        return
    }

    // Create audio mix for fade effects
    let audioMix = createAudioMixWithFades(for: compAudio, totalDuration: durationA, fadeIn: fadeIn, fadeOut: fadeOut)

    // Create video composition (always, to ensure proper time mapping)
    let videoComposition = AVMutableVideoComposition()
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.renderSize = videoATrack.naturalSize
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: durationA)
    
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideo)
    layerInstruction.setTransform(videoATrack.preferredTransform, at: .zero)
    
    instruction.layerInstructions = [layerInstruction]
    videoComposition.instructions = [instruction]

    // Export result
    try? FileManager.default.removeItem(at: outputURL)

    guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
        completion(nil)
        return
    }

    exporter.outputURL = outputURL
    exporter.outputFileType = .mp4
    exporter.shouldOptimizeForNetworkUse = true
    exporter.audioMix = audioMix
    exporter.videoComposition = videoComposition

    exporter.exportAsynchronously {
        DispatchQueue.main.async {
            if exporter.status == .completed {
                completion(outputURL)
            } else {
                print("Export failed: \(exporter.error?.localizedDescription ?? "unknown error")")
                completion(nil)
            }
        }
    }
}

// MARK: - Helper Functions

func applyFades(
    to audioParam: AVMutableAudioMixInputParameters,
    totalDuration: CMTime,
    fadeIn: Double,
    fadeOut: Double
) {
    if fadeIn > 0.0 {
        let fadeInDuration = CMTime(seconds: fadeIn, preferredTimescale: 100)
        audioParam.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0, timeRange: CMTimeRange(start: .zero, duration: fadeInDuration))
    }
    
    if fadeOut > 0.0 {
        let fadeOutDuration = CMTime(seconds: fadeOut, preferredTimescale: 100)
        audioParam.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: CMTimeRange(start: CMTimeSubtract(totalDuration, fadeOutDuration), duration: fadeOutDuration))
    }
}

func createAudioMixWithFades(
    for track: AVMutableCompositionTrack,
    totalDuration: CMTime,
    fadeIn: Double,
    fadeOut: Double
) -> AVMutableAudioMix? {
    guard fadeIn > 0.0 || fadeOut > 0.0 else { return nil }
    
    let audioParam = AVMutableAudioMixInputParameters(track: track)
    audioParam.trackID = track.trackID
    
    applyFades(to: audioParam, totalDuration: totalDuration, fadeIn: fadeIn, fadeOut: fadeOut)
    
    let mix = AVMutableAudioMix()
    mix.inputParameters = [audioParam]
    return mix
}

func exportComposition(
    _ composition: AVMutableComposition,
    to outputURL: URL,
    audioMix: AVMutableAudioMix?,
    preset: String,
    outputFileType: AVFileType,
    shouldOptimizeForNetworkUse: Bool = false,
    completion: @escaping (Result<URL, Error>) -> Void
) async {
    try? FileManager.default.removeItem(at: outputURL)
    
    guard let exporter = AVAssetExportSession(asset: composition, presetName: preset) else {
        completion(.failure(NSError(domain: "Exporter init failed", code: -4)))
        return
    }
    
    exporter.outputURL = outputURL
    exporter.outputFileType = outputFileType
    exporter.audioMix = audioMix
    exporter.shouldOptimizeForNetworkUse = shouldOptimizeForNetworkUse
    
    await exporter.export()
    DispatchQueue.main.async {
        switch exporter.status {
        case .completed: completion(.success(outputURL))
        default:
            completion(.failure(exporter.error ?? NSError(domain: "Export failed", code: -5)))
        }
    }
}

/// Offline “old player” effect:
/// - Speed wobble via AVAudioUnitVarispeed (changes tempo + pitch together, like tape).
/// - Extra independent pitch wobble via AVAudioUnitTimePitch (pitch in cents, without tempo change).
///
/// Note: Output is easiest as .m4a/.wav/.caf. Writing MP3 is not supported directly by AVAudioFile in a simple way.
func applyWowFlutter(
    inputURL: URL,
    outputURL: URL,
    minSpeed: Float,
    maxSpeed: Float,
    minPitchCents: Float,
    maxPitchCents: Float,
    waveLengthSeconds: Double,
    flutterAmount: Float = 0.0,          // 0...1 (adds faster small jitter mainly to pitch)
    maxFrameCount: AVAudioFrameCount = 4096,
    progress: ((Double) -> Void)? = nil  // 0...1
) {

    guard waveLengthSeconds > 0 else {
        print("WOWERR: waveLengthSeconds must be > 0")
        return
    }
    guard minSpeed > 0, maxSpeed > 0 else {
        print("WOWERR: minSpeed/maxSpeed must be > 0")
        return
    }
    
    guard let inputFile = try? AVAudioFile(forReading: inputURL) else {
        print("WOWERR: can't open input")
        return
    }

    let inputFormat = inputFile.processingFormat
    let sampleRate = inputFormat.sampleRate
    let channelCount = Int(inputFormat.channelCount)

    let totalFrames = AVAudioFramePosition(inputFile.length)
    guard totalFrames > 0 else {
        print("WOWERR: Input file has zero length.")
        return
    }

    // Output settings based on extension
    let ext = outputURL.pathExtension.lowercased()
    let outputSettings: [String: Any]
    outputSettings = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: channelCount,
        AVEncoderBitRateKey: 192_000
    ]

    // Remove existing output if any
    try? FileManager.default.removeItem(at: outputURL)

    guard let outputFile = try? AVAudioFile(forWriting: outputURL, settings: outputSettings) else {
        print("WOWERR: Can't create output")
        return
    }

    // Build engine: player -> varispeed -> timePitch -> mainMixer
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let varispeed = AVAudioUnitVarispeed()
    let timePitch = AVAudioUnitTimePitch()

    engine.attach(player)
    engine.attach(varispeed)
    engine.attach(timePitch)

    engine.connect(player, to: varispeed, format: inputFormat)
    engine.connect(varispeed, to: timePitch, format: inputFormat)
    engine.connect(timePitch, to: engine.mainMixerNode, format: inputFormat)

    let renderFormat = engine.mainMixerNode.outputFormat(forBus: 0)

    // Manual rendering
    try? engine.enableManualRenderingMode(.offline, format: renderFormat, maximumFrameCount: maxFrameCount)
    try? engine.start()

    player.scheduleFile(inputFile, at: nil)
    player.play()

    // Helpers
    @inline(__always) func clamp(_ x: Float, _ a: Float, _ b: Float) -> Float { max(a, min(b, x)) }
    @inline(__always) func lerp(_ a: Float, _ b: Float, _ t01: Float) -> Float { a + (b - a) * t01 }
    @inline(__always) func sine01(_ phase: Double) -> Float { Float((sin(phase) + 1.0) * 0.5) }

    // Safe clamps
    let minSpeedC = clamp(minSpeed, 0.25, 4.0)
    let maxSpeedC = clamp(maxSpeed, 0.25, 4.0)
    let minPitchC = clamp(minPitchCents, -2400, 2400)
    let maxPitchC = clamp(maxPitchCents, -2400, 2400)
    let flutterC = clamp(flutterAmount, 0, 1)

    // LFO
    let wowOmega = 2.0 * Double.pi / waveLengthSeconds
    let flutterHz = 8.0
    let flutterOmega = 2.0 * Double.pi * flutterHz

    let buffer = AVAudioPCMBuffer(
        pcmFormat: engine.manualRenderingFormat,
        frameCapacity: engine.manualRenderingMaximumFrameCount
    )!

    var writtenFrames: AVAudioFramePosition = 0

    while engine.manualRenderingSampleTime < totalFrames {
        let tSeconds = Double(engine.manualRenderingSampleTime) / sampleRate

        // speed LFO (0..1)
        let wowT = sine01(wowOmega * tSeconds)
        let speed = lerp(minSpeedC, maxSpeedC, wowT)

        // pitch LFO (0..1) with phase offset
        let pitchT = sine01(wowOmega * tSeconds + Double.pi * 0.35)
        var pitch = lerp(minPitchC, maxPitchC, pitchT)

        // Optional flutter adds small fast jitter to pitch
        if flutterC > 0 {
            let fl = Float(sin(flutterOmega * tSeconds)) // -1..1
            let pitchSpan = abs(maxPitchC - minPitchC)
            let flutterDepth = max(2, pitchSpan * 0.15) * flutterC
            pitch += fl * flutterDepth
        }

        varispeed.rate = speed
        timePitch.pitch = pitch

        let framesToRender = min(
            maxFrameCount,
            AVAudioFrameCount(totalFrames - engine.manualRenderingSampleTime)
        )

        guard let status = try? engine.renderOffline(framesToRender, to: buffer) else {
            print("WOWERR: failed to render offline")
            return
        }

        switch status {
        case .success:
            try? outputFile.write(from: buffer)
            writtenFrames += AVAudioFramePosition(buffer.frameLength)
            progress?(min(1.0, Double(writtenFrames) / Double(totalFrames)))

        case .insufficientDataFromInputNode, .cannotDoInCurrentContext:
            // Try again next iteration
            continue

        case .error:
            print("WOWERR: renderOffline returned .error")

        @unknown default:
            print("WOWERR: renderOffline returned unknown status")
        }
    }

    player.stop()
    engine.stop()
    engine.disableManualRenderingMode()
}
