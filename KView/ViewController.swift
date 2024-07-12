//
//  ViewController.swift
//  KView
//
//  Created by Josh on 6/28/24.
//

import UIKit
import AVKit
import MediaPlayer

class ViewController: UIViewController, UIDocumentPickerDelegate {
    var groupedURLS: [String: [URL]] = [:]
    var active = false;
    let playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(playNextVideo), name:
NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            if (self.active) {
                print("Re-entering forground")
                if let player = playerViewController.player {
                    player.play()
                }
            }
        }
        
        // Something keeps going wrong, just check every five seconds and try restart if there are issues
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [unowned self] timer in
            if let player = playerViewController.player {
                if (player.currentItem?.error != nil) {
                    playNextVideo()
                } else {
                    player.play()
                }
            }
        }
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        let documentPicker =
        UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self
        
        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
        
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
        case "3","d", "e", "f":
            return "3"
        case "4","g", "h", "i":
            return "4"
        case "5","j", "k", "l":
            return "5"
        case "6","m", "n", "o":
            return "6"
        case "7","p", "q", "r", "s":
            return "7"
        case "8","t", "u", "v":
            return "8"
        case "9","w", "x", "y", "z":
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
    func pickVideo(_ number: String) -> URL {
        if (self.groupedURLS[number] != nil) {
            return self.groupedURLS[number]!.randomElement()!
        } else {
            return self.groupedURLS["ERR"]!.randomElement()!
        }
    }


    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let pickedFolderURL = urls[0]
        let shouldStopAccessing = pickedFolderURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
               // pickedFolderURL.stopAccessingSecurityScopedResource()
            }
        }
        
        
        let keys : [URLResourceKey] = [.nameKey, .isDirectoryKey]
        let fileList = FileManager.default.enumerator(at: pickedFolderURL, includingPropertiesForKeys: keys)!
        
        var allURLS: [URL] = [];
        
        for case let file as URL in fileList {
            if (file.pathExtension.lowercased() == "mp4") {
                allURLS.append(file)
            }
        }
        
        self.groupedURLS = splitFilenames(allURLS)
        if (self.active == false) {
            self.active = true;
            present(playerViewController, animated: true)
        }
        playVideo("NEXT")
    }
        
    @objc func playNextVideo() {
        playVideo("NEXT")
    }
    
    var fileName = ""
    
    
    func resetKeyTimer() {
        buffer?.cancel()
        guard !fileName.isEmpty else {
            return
        }
        buffer = Task.detached{ [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(2500_000_000))
            do {
                try Task.checkCancellation()
            } catch {
                return
            }
            guard let self else { return }
            await self.playDialed()

            try? await Task.sleep(nanoseconds: UInt64(1250_000_000))
            do {
                try Task.checkCancellation()
            } catch {
                return
            }
            await self.clearDialNumber()
        }
    }
    
    
    var buffer: Task<(), Never>?
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        switch key.keyCode.rawValue {
        case (UIKeyboardHIDUsage.keyboardA.rawValue)...(UIKeyboardHIDUsage.keyboardZ.rawValue):
            fallthrough
        case (UIKeyboardHIDUsage.keyboard1.rawValue)...(UIKeyboardHIDUsage.keyboard0.rawValue):
            self.fileName.append(key.characters.map(letterToNumber).joined(separator: ""))
            print("Updated fileName to: " + self.fileName)
            self.resetKeyTimer()
        case UIKeyboardHIDUsage.keyboardPeriod.rawValue:
            print("Timer reset...")
            self.resetKeyTimer()
        default:
            super.pressesEnded(presses, with: event)
        }
    }
    
    
    func playDialed() {
        print("Dialed: " + fileName)
        self.playVideo(fileName)
    }

    func clearDialNumber() {
        print("Clearing dialed code")
        fileName = ""
    }
    
    func playVideo(_ input: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if (input == "100") {
                print("Setting volume to zero")
                (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(0, animated: false)
                return
            } else if (input == "101")   {
                print("Setting volume to full")
                (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(1, animated: false)
                return
            }
            
            let videoURL: URL = pickVideo(input)
            
            print("Playing " + input + ": " + videoURL.absoluteString)
            let player = AVPlayer(url: videoURL)
            player.preventsDisplaySleepDuringVideoPlayback = true
            if let old = playerViewController.player {
                old.pause()
            }
            playerViewController.player = player
            playerViewController.showsPlaybackControls = false
            playerViewController.videoGravity = .resizeAspectFill
            player.play()
            /*
            Task.detached {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let error = player.error {
                    print("AVError \(error)")
                }
                if let error = player.currentItem?.error {
                    print("currentItem \(error)")
                }
            }*/
            
        }
    }
}

