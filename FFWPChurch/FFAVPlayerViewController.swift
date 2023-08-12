//
//  FFAVPlayerViewController.swift
//  FFWPChurch
//
//  Created by JooYoung Kim on 2023/08/09.
//

import Foundation
import AVKit

class FFAVPlayerViewController: AVPlayerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
