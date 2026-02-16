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
//        let baseUrl = "/Users/miraslau/Music/_For Quiz/__Tuc_21/10. Блиц"
//        
//        for n in 1...10 {
//                        
//            let q = URL(fileURLWithPath: "\(baseUrl)/q\(n).m4a")
//            let siren = n < 10
//            ? URL(fileURLWithPath: "\(baseUrl)/s\(n).m4a")
//            : URL(fileURLWithPath: "\(baseUrl)/Siren_triple.m4a")
//            
//            let outputA = URL(fileURLWithPath: "\(baseUrl)/TucTwentyOne0\(n)Q.m4a")
//            
//            mergeAudios(from: [q,siren],
//                        outputURL: outputA) { _ in
//                print("Saved: q\(n).m4a")
//            }
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
    volumeCoef: Float,
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
    
    let startTime = CMTimeMake(value: Int64(start*100), timescale: 100)
    let endTime = CMTimeMake(value: Int64(end*100), timescale: 100)
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

            // Export
            await exportComposition(composition, to: outputURL, audioMix: audioMix, preset: AVAssetExportPresetHighestQuality, outputFileType: .mp4, shouldOptimizeForNetworkUse: true, completion: completion)

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
