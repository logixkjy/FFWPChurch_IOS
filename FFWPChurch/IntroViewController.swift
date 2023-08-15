//
//  IntroViewController.swift
//  FFWPChurch
//
//  Created by JooYoung Kim on 2023/08/12.
//

import Foundation
import UIKit
import AVKit


class IntroViewController: UIViewController {
    
    var playerController: AVPlayerViewController?
    override func viewDidLoad() {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 비디오 파일명을 사용하여 비디오가 저장된 앱 내부의 파일 경로를 받아옴
        let filePath:String? = Bundle.main.path(forResource: "intro", ofType: "mp4")
        // 앱 내부의 파일명을 NSURL 형식으로 변경
        let url = NSURL(fileURLWithPath: filePath!)

        // AVPlayerController의 인스턴스 생성
        playerController = AVPlayerViewController()
        // 비디오 URL로 초기화된 AVPlayer의 인스턴스 생성
        let player = AVPlayer(url: url as URL)
        // AVPlayerViewController의 player 속성에 위에서 생성한 AVPlayer 인스턴스를 할당
        playerController?.player = player
        playerController?.videoGravity = .resizeAspectFill
        playerController?.showsPlaybackControls = false

        let w = self.view.frame.width
        let h = 720 * w / 335

        playerController?.view.frame = CGRect(x: 0, y: (h - self.view.frame.height) / 2, width: w, height: h)

        NotificationCenter.default.addObserver(self, selector: #selector(self.AVPlayerItemDidPlayToEndTimeNotification), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerController?.player?.currentItem)

        self.present(playerController!, animated: false){
            player.play() // 비디오 재생
        }
    }
    
    @objc func AVPlayerItemDidPlayToEndTimeNotification() {
        playerController?.player?.pause()
        playerController?.dismiss(animated: false)
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
//    open var fillMode: ScalingMode = .resizeAspectFill {
//        didSet {
//            switch fillMode {
//            case .resize:
//                moviePlayer.videoGravity = convertToAVLayerVideoGravity(AVLayerVideoGravity.resize.rawValue)
//            case .resizeAspect:
//                moviePlayer.videoGravity = convertToAVLayerVideoGravity(AVLayerVideoGravity.resizeAspect.rawValue)
//            case .resizeAspectFill:
//                moviePlayer.videoGravity = convertToAVLayerVideoGravity(AVLayerVideoGravity.resizeAspectFill.rawValue)
//            }
//        }
//    }
}
