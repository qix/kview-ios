//
//  MainViewController.swift
//  KView
//
//  Created by Josh Y on 8/18/24.
//

import UIKit
class MainMenuController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UIView.setAnimationsEnabled(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CameraOnly" {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .cameraOnly
        } else if (segue.identifier == "VideoSequence") {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .videoSequential
        } else if (segue.identifier == "VideoDialing") {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .videoDialing
        } else {
            print("Unknown segue identifier: ", segue.identifier!)
        }
    }

}
