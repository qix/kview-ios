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
            if (file.pathExtension.lowercased() == "webm") {
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

