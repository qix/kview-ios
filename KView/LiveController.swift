//
//  ViewController.swift
//  KView
//
//  Created by Josh on 6/28/24.
//

import AVKit
import MediaPlayer
import UIKit

let superUserVolumeZero = "424100"
let superUserVolumeFull = "424101"
let superUserCodes = [
    superUserVolumeZero,
    superUserVolumeFull
]

enum MyError: Error {
    case runtimeError(String)
}

enum LiveMode {
    case videoDialing, videoSequential, cameraOnly
}

class LiveController: UIViewController, UIDocumentPickerDelegate {
    var nextOrderedIndex = 0
    var orderedURLS: [URL] = []
    var groupedURLS: [String: [URL]] = [:]
    var mode: LiveMode = .cameraOnly
    var liveVideo = false
    var active = false
    var videoFolderEnabled = true
    var resumeTimer: Timer? = nil
    
    var fileName = ""
    var pausedAt: [String.Index] = []
    let playerViewController = AVPlayerViewController()
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        captureDevice = availableDevices.first
        
        if let captureDevice = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(input)
            } catch {
                print("Failed to capture camera")
                return
            }
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.frame
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoRotationAngle = 0
        }
    }
        
    func prepareAudio() {
        guard let _ = try? AVAudioSession.sharedInstance().setCategory(
            AVAudioSession.Category.playback,
            mode: AVAudioSession.Mode.default,
            options: []
        ) else { return }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareCamera()
        prepareAudio()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playNextVideo),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil
        )
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] _ in
            if self.active == true {
                print("Re-entering forground")
                
                if self.liveVideo {
                    print("Not restarting anything for live video")
                } else {
                    print("Trying to resume video player")
                    if let player = playerViewController.player {
                        player.play()
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let timer = resumeTimer {
            timer.invalidate()
            resumeTimer = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIAccessibility.requestGuidedAccessSession(enabled: true) {
            success in
            print("Request guided access success: \(success)")
        }
        
        if mode == .videoDialing || mode == .videoSequential {
            let documentPicker =
                UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
            documentPicker.delegate = self
                
            // Present the document picker.
            present(documentPicker, animated: false, completion: nil)
        } else if (mode == .cameraOnly) {
            self.active = true
            playVideo("LIVE")
        } else {
            print("Error: Unknown mode")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        // Something keeps going wrong, just check every five seconds and try restart if there are issues
        if let timer = resumeTimer {
            timer.invalidate()
        }
        resumeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [unowned self] _ in
            if self.liveVideo == false {
                if let player = playerViewController.player {
                    if player.currentItem?.error != nil {
                        print("Something went wrong! Next video playing...")
                        playNextVideo()
                    } else {
                        print("Forcing resume of video, just in case")
                        player.play()
                    }
                }
            }
        }
    }
    
    func letterToNumber(_ letter: Character) -> String {
        let letter = letter.lowercased()
        switch letter {
        case "0":
            return "0"
        case "1":
            return "1"
        case "2", "a", "b", "c":
            return "2"
        case "3", "d", "e", "f":
            return "3"
        case "4", "g", "h", "i":
            return "4"
        case "5", "j", "k", "l":
            return "5"
        case "6", "m", "n", "o":
            return "6"
        case "7", "p", "q", "r", "s":
            return "7"
        case "8", "t", "u", "v":
            return "8"
        case "9", "w", "x", "y", "z":
            return "9"
        default:
            return "?"
        }
    }

    func splitFilenames(_ urls: [URL]) -> [String: [URL]] {
        var result: [String: [URL]] = [:]

        for url in urls {
            let filename = url.deletingPathExtension().lastPathComponent
            let components = filename.components(separatedBy: "_")
            for component in components {
                if component == "" {
                    break
                }
                let numbers: String = component.map(letterToNumber).joined(separator: "")

                for key in [numbers, component.uppercased()] {
                    if result[key] != nil {
                        result[key]?.append(url)
                    } else {
                        result[key] = [url]
                    }
                }
            }
        }

        return result
    }

    func hasVideo(_ number: String) -> Bool {
        if number == "LIVE" || number == "5483" {
            return true
        } else if superUserCodes.contains(number) {
            return true
        }
        return groupedURLS[number] != nil
    }

    func pickVideo(_ number: String) -> URL? {
        if number == "LIVE" || number == "5483" {
            return nil
        }
        if mode == .videoSequential {
            let playIndex = nextOrderedIndex
            nextOrderedIndex = (nextOrderedIndex +  1) % orderedURLS.count
            return orderedURLS[playIndex]
        }
        if groupedURLS[number] != nil {
            return groupedURLS[number]!.randomElement()!
        } else {
            if number == "NEXT" {
                if mode == .videoSequential {
                    return groupedURLS.randomElement()!.value.randomElement()!
                }
                return nil
            }
            return groupedURLS["ERR"]!.randomElement()!
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let pickedFolderURL = urls[0]
        let shouldStopAccessing = pickedFolderURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                // pickedFolderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let keys: [URLResourceKey] = [.nameKey, .isDirectoryKey]
        let fileList = FileManager.default.enumerator(at: pickedFolderURL, includingPropertiesForKeys: keys)!
        
        orderedURLS = []
        for case let file as URL in fileList {
            if file.pathExtension.lowercased() == "mp4" {
                orderedURLS.append(file)
            }
        }
        nextOrderedIndex = 0
        
        groupedURLS = splitFilenames(orderedURLS)
        print("Filenames grouped:")
        for (key, urls) in groupedURLS {
            print(" \(key):")
            for url in urls {
                print("  - \(url.lastPathComponent)")
            }
        }

        self.active = true
        playVideo("NEXT")
    }
        
    @objc func playNextVideo() {
        playVideo("NEXT")
    }
    
    func resetKeyTimer() {
        buffer?.cancel()
        guard !fileName.isEmpty else {
            return
        }
        buffer = Task.detached { [weak self] in
            // Wait 1.5 seconds, and note a pause
            // (three seconds to safely dial again)
            try? await Task.sleep(nanoseconds: UInt64(1_500_000_000))
            do {
                try Task.checkCancellation()
            } catch {
                return
            }
            guard let self else { return }
            await self.notePause()
            
            // Another second, and we can start playing
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000))
            do {
                try Task.checkCancellation()
            } catch {
                return
            }
            await self.playDialed()

            try? await Task.sleep(nanoseconds: UInt64(5_000_000_000))
            do {
                try Task.checkCancellation()
            } catch {
                return
            }
            await self.clearDialNumber()
        }
    }
    
    var buffer: Task<Void, Never>?
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        switch key.keyCode.rawValue {
        case (UIKeyboardHIDUsage.keyboardA.rawValue)...(UIKeyboardHIDUsage.keyboardZ.rawValue):
            fallthrough
        case (UIKeyboardHIDUsage.keyboard1.rawValue)...(UIKeyboardHIDUsage.keyboard0.rawValue):
            fileName.append(key.characters.map(letterToNumber).joined(separator: ""))
            print("Updated fileName to: " + fileName)
            resetKeyTimer()
        case UIKeyboardHIDUsage.keyboardPeriod.rawValue:
            print("Timer reset...")
            resetKeyTimer()
        default:
            super.pressesEnded(presses, with: event)
        }
    }
    
    func notePause() {
        print("Paused after:", fileName)
        pausedAt.append(fileName.endIndex)
    }
    
    func playDialed() {
        print("Dialed: " + fileName)
        
        // Whenever we paused, take a substring from there
        let tryStrings = ([fileName.startIndex] + pausedAt).map { index in
            String(fileName[index...])
        }
        
        // Try all of the substrings where we had a longer pause
        print("Trying to play: " + tryStrings.joined(separator: " / "))
        for str in tryStrings {
            if hasVideo(str) {
                playVideo(str)
                return
            }
        }
        playVideo(fileName)
    }

    func clearDialNumber() {
        print("Clearing dialed code")
        fileName = ""
        pausedAt = []
    }
    
    func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }

    func playVideo(_ input: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if superUserCodes.contains(input) {
                print("Superuser code: " + input)
                if input == superUserVolumeZero {
                    print("Setting volume to zero")
                    setVolume(0)
                } else if input == superUserVolumeFull {
                    print("Setting volume to full")
                    setVolume(1)
                }
                return
            }
            
            if let videoURL: URL = pickVideo(input) {
                print("Playing " + input + ": " + videoURL.absoluteString)
                self.liveVideo = false
                let player = AVPlayer(url: videoURL)
                player.preventsDisplaySleepDuringVideoPlayback = true
                if let old = playerViewController.player {
                    old.pause()
                }
                playerViewController.player = player
                playerViewController.showsPlaybackControls = false
                playerViewController.videoGravity = .resizeAspectFill
                player.play()
                
                if captureSession.isRunning {
                    captureSession.stopRunning()
                }
                if previewLayer != nil {
                    previewLayer.removeFromSuperlayer()
                }
                if playerViewController.presentingViewController == nil {
                    present(playerViewController, animated: false)
                }
            } else if captureDevice != nil {
                print("Playing live video")
                self.liveVideo = true
                do {
                    try captureDevice.lockForConfiguration()
                    captureDevice.videoZoomFactor = 1.0
                    captureDevice.unlockForConfiguration()
                } catch {
                    print("Error setting capture device zoom")
                }
                
                view.layer.addSublayer(previewLayer)
                playerViewController.dismiss(animated: false)
                if let player = playerViewController.player {
                    player.pause()
                }

                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self else { return }
                    if !captureSession.isRunning {
                        captureSession.startRunning()
                    }
                }
            }
        }
    }
}
