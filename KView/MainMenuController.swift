//
//  MainViewController.swift
//  KView
//
//  Created by Josh Y on 8/18/24.
//

import UIKit
class MainMenuController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        UIView.setAnimationsEnabled(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CameraOnly" {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .cameraOnly
            viewController.timelapseEnabled = false
        } else if (segue.identifier == "VideoSequence") {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .videoSequential
            viewController.timelapseEnabled = false
        } else if (segue.identifier == "VideoDialing") {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .videoDialing
            viewController.timelapseEnabled = false
        } else if (segue.identifier == "BurningMan") {
            let viewController:LiveController = segue.destination as! LiveController
            viewController.mode = .videoDialing
            viewController.timelapseEnabled = true
        } else {
            print("Unknown segue identifier: ", segue.identifier ?? "nil")
        }
    }

}
