//
//  ViewController.swift
//  KView
//
//  Created by Josh on 6/28/24.
//

import UIKit
import AVKit

class ViewController: UIViewController, UIDocumentPickerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewDidAppear(_ animated: Bool) {

        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self


        // Set the initial directory.
        //documentPicker.directoryURL = startingDirectory


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
        if (groupedDictionary[number] != nil) {
            return groupedDictionary[number]!.randomElement()!
        } else {
            return groupedDictionary["ERR"]!.randomElement()!
        }
    }




    /********************* 
    VIDEO PICKER SAMPLE
    *********************/
    let filenames: [URL] = [
        URL(string:"https://localhost/1_NEXT_METAL1.mp4")!, 
        URL(string:"https://localhost/2_NEXT_METAL2.mp4")!, 
        URL(string:"https://localhost/MENDELEYEV_the%20voice.mp4")!,
        URL(string:"https://localhost/RICK_ROLL_RICKROLL.mp4")!,
        URL(string:"https://localhost/LOST_Lost%20and%20found%20short.mp4")!,
        URL(string:"https://localhost/3_NEXT_crayons.mp4")!,
        URL(string:"https://localhost/ERR_BANANAPHONE.mp4")!
    ]

    let groupedDictionary = splitFilenames(filenames)
    for (key, value) in groupedDictionary {
        print("\(key): \(value.map { $0.lastPathComponent }.joined(separator: ", "))")
    }
    print("==================")
    print("Next video: " + pickVideo("NEXT").lastPathComponent)
    print("User dialed 7655: " + pickVideo("7655").lastPathComponent)
    print("User dialed 7656: " + pickVideo("7656").lastPathComponent)
    /********************* 
    END VIDEO PICKER SAMPLE
    *********************/

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
        let pickedFolderURL = urls[0]
        let shouldStopAccessing = pickedFolderURL.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    pickedFolderURL.stopAccessingSecurityScopedResource()
                }
            }
        
        
        let keys : [URLResourceKey] = [.nameKey, .isDirectoryKey]
        let fileList = FileManager.default.enumerator(at: pickedFolderURL, includingPropertiesForKeys: keys)!
        
        
        var groupedURLs: [String: [URL]] = [:]
        var randomURLs: [URL] = []

        for case let file as URL in fileList {
            print("Found: ", file)
            print(file.pathExtension)
            if (file.pathExtension.lowercased() == "mp4") {
                randomURLs.append(file)
            }
            /*
            
            let newFile = file.path.replacingOccurrences(of: pickedFolderURL.path, with: "")
            if(newFile.hasPrefix("/.") == false){ //exclude hidden
                print(file)
                logString += "\n\(file)"
            }*/
        }
        
        if let videoURL: URL = randomURLs.randomElement() {
            print("Chose: ", videoURL)
            let player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            present(playerViewController, animated: true) {
                player.play()
            }
        }
        
    }

}

