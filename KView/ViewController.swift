//
//  ViewController.swift
//  KView
//
//  Created by Josh on 6/28/24.
//

import UIKit
import AVKit

class ViewController: UIViewController, UIDocumentPickerDelegate {
    var groupedURLS: [String: [URL]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        playerViewController.showsPlaybackControls = false
        playerViewController.videoGravity = .resizeAspectFill
        
        NotificationCenter.default.addObserver(self, selector: #selector(playNextVideo), name:
NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
    }
    
    let playerViewController = AVPlayerViewController()

    override func viewDidAppear(_ animated: Bool) {
        
        let documentPicker =
        UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self
        
        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
        
    }
    
    func letterToNumber(_ letter: Character) -> Character {
        let letter = letter.lowercased()
        switch letter {
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
                let numbers = String(component.map(letterToNumber))

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
                pickedFolderURL.stopAccessingSecurityScopedResource()
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
        playVideo("NEXT")
        present(playerViewController, animated: true)
    }
        
    @objc func playNextVideo() {
        playVideo("NEXT")
    }
    var fileName = "" {
        didSet {
            buffer?.cancel()
            guard !fileName.isEmpty else {
                return
            }
            buffer = Task.detached{ [weak self] in
                let duration = UInt64(2_000_000_000)
                try? await Task.sleep(nanoseconds: duration)
                do {
                    try Task.checkCancellation()
                } catch {
                    return
                }
                guard let self else { return }
                
                await self.playChosenVideo()
            }
        }
    }
    
    
    var buffer: Task<(), Never>?
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        switch key.keyCode.rawValue {
        case (UIKeyboardHIDUsage.keyboard1.rawValue)...(UIKeyboardHIDUsage.keyboard0.rawValue):
            self.fileName.append(key.characters)
            print("Updated fileName to: " + self.fileName)
        default:
            super.pressesEnded(presses, with: event)
        }
    }
    
    
    func playChosenVideo() {
        print("Chose: " + fileName)
        self.playVideo(fileName)
        fileName = ""
    }
    
    func playVideo(_ input: String) {
        /*DispatchQueue.main.async { [weak self] in
            guard let self else { return }*/
            let videoURL: URL = pickVideo(input)
            print("Playing " + input + ": " + videoURL.lastPathComponent)
            let player = AVPlayer(url: videoURL)
            player.preventsDisplaySleepDuringVideoPlayback = true
            playerViewController.player = player
            player.play()
        //}
    }
}

