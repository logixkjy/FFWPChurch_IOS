//
//  ViewController.swift
//  FFWPChurch
//
//  Created by JooYoung Kim on 2023/08/04.
//

import UIKit
import WebKit
import SnapKit
import Then
import JavaScriptCore
import AVFoundation
import MediaPlayer
import AVKit
import objcModule

class ViewController: UIViewController {

    var webView: WKWebView!
    var jsContext: JSContext!
    var _webConfig: WKWebViewConfiguration?
    var synthesizer: AVSpeechSynthesizer!
    
    var ttsRate: Float = 0.0
    
    var jsonText: String!
    
    var audioTitle: String!
    var audioDesc: String!
    
    var isPlaying = true
    
    var timer: Timer?
    
    var mainDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
        synthesizer = AVSpeechSynthesizer.init()
        synthesizer.delegate = self
        ttsRate = AVSpeechUtteranceDefaultSpeechRate
        
        //이걸 지우면 전화걸때... 꺼짐
        //백그라운드에서 재생
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.playback)
        try! session.setActive(true)
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
        
        let commonProcessPool: WKProcessPool = WKProcessPool.init()
        let config: WKWebViewConfiguration = WKWebViewConfiguration.init()
        config.processPool = commonProcessPool
        config.allowsInlineMediaPlayback = true
        
        let contentController = WKUserContentController()
        
        // Swift에 JavaScript 인터페이스 연결
        contentController.add(self, name: "FFWPChurch") // delegate 할당
        config.userContentController = contentController
        
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: config).then {
            $0.uiDelegate = self
            $0.navigationDelegate = self
        }
        self.view.addSubview(self.webView)
        self.webView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.width.equalTo(self.view)
            make.height.equalTo(self.view)
        }
        
        
//        if (getDataCenter.schemeData != nil) {
//            [self moveDirectURL:getDataCenter.schemeData];
//            getDataCenter.schemeData = nil;
//        } else {
        let URL = URL(string: MAIN_URL)
        self.webView.load(URLRequest(url: URL!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TIME_OUT_INTERVAL))
//        }
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        return nil
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let URLString = (navigationAction.request.url?.absoluteString)! as NSString // 목적지 url
        print(URLString)
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webView(_ webView: WKWebView, didCommit navigation: WKNavigation!)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)")
    }
    
    func play(audioPath: String) {
        print("\(String(describing: mainDelegate.avAudioPlayer?.state))")
        if mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.stopped ||
            mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.paused ||
            mainDelegate.avAudioPlayer?.state == nil {
            
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  mainDelegate.avAudioPlayer?.progress
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1

            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            self.playingAudio(audioPath: audioPath)
        } else {
            mainDelegate.avAudioPlayer?.pause()

            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = mainDelegate.avAudioPlayer?.progress
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0

            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func playingAudio(audioPath: String) {
        if mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.stopped ||
        mainDelegate.avAudioPlayer?.state == nil {
            mainDelegate.avAudioPlayer = STKAudioPlayer.init()
            mainDelegate.avAudioPlayer?.delegate = self
            mainDelegate.avAudioPlayer?.volume = 1;
            
            if let url = URL(string: audioPath) {
                
                let dataSource = STKAudioPlayer.dataSource(from: url)
                
                mainDelegate.avAudioPlayer?.setDataSource(dataSource, withQueueItemId: SampleQueueId.init(url: url, andCount: 0))
                
                isPlaying = false
                timer = Timer(timeInterval: 1, repeats: true, block: { _timer in
                    self.updatePlaybackProgressFromTimer(timer: _timer)
                })
            }

        } else if mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.paused {
            mainDelegate.avAudioPlayer?.resume()
        }
    }
    
    func AudiosSetPlay(index: String, title: String, desc: String, audioPath: String, type: String) {
        var param = [String:String]()
        param.updateValue(index, forKey: "playKey") // 고유키
        param.updateValue(title, forKey: "playTitle")  // 제목
        param.updateValue(desc, forKey: "playSubTitle")  // 부제목
        param.updateValue(audioPath, forKey: "playURL")  // 스트리밍 주소
        param.updateValue(type, forKey: "playType")  // 스트리밍 타입(노래, 경음악)
        
        jsonText = (JsonUtil.jsonWriter(param) as! String)
        print(jsonText as Any)

        audioTitle = title
        audioDesc = desc
        mainDelegate.avAudioPlayer?.stop()

        synthesizer.stopSpeaking(at: .immediate)

        self.play(audioPath: audioPath)
    }
    
    func AudioPlay() {
        mainDelegate.avAudioPlayer?.resume()
    }

    func AudioPause() {
        mainDelegate.avAudioPlayer?.pause()
    }

    func AudioStop() {
        mainDelegate.avAudioPlayer?.stop()
    }

    // TODO:: 반환 값 처리 필요
    func AudioIsPlay(function: String) {
        let isPlaying = mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.playing
        let exec = "\(function)(\(isPlaying));"
        
        self.webView.evaluateJavaScript(exec) { result, error in
            if let anError = error {
                print("[Error Message] : \(anError)")
            }
        }
    }
    
    // TODO:: 반환 값 처리 필요
    func AudioGetInfo(function: String) {
        let exec = "\(function)(\"" + ((jsonText ?? "") as NSString).replacingOccurrences(of: "\"", with: "") + "\");"
        
        self.webView.evaluateJavaScript(exec) { result, error in
            if let anError = error {
                print("[Error Message] : \(anError)")
            }
        }
    }

    func VideoSetPlay(vimeoID: String) {
//        [self requestVimeoUrl:vimeoID Completion:^(BOOL success, NSString *vimeoUrl) {
//            if (success) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self->mainDelegate.avAudioPlayer stop];
//                    self->mainDelegate.avVideoPlayer = [[FFAVPlayerViewController alloc] init];
//                    AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:vimeoUrl]];
//                    self->mainDelegate.avVideoPlayer.player = player;
//                    self->mainDelegate.avVideoPlayer.modalPresentationStyle = UIModalPresentationFullScreen;
//                    self->mainDelegate.avVideoPlayer.view.frame = self.view.bounds;
//
//                    [[NSNotificationCenter defaultCenter] addObserver:self
//                                                             selector:@selector(AVPlayerItemDidPlayToEndTimeNotification)
//                                                                 name:AVPlayerItemDidPlayToEndTimeNotification
//                                                               object:self->mainDelegate.avVideoPlayer.player.currentItem];
//
//                    [self->mainDelegate.avVideoPlayer.player play];
//
//                    [self->mainDelegate.avVideoPlayer.view setFrame:self.view.frame];
//
//                    [self presentViewController:self->mainDelegate.avVideoPlayer animated:NO completion:nil];
//                });
//            }
//        }];
    }
//    - (void)requestVimeoUrl:(NSString*)vimeoID Completion:(void (^)(BOOL success, NSString* vimeoUrl))completion
//    {
//        NSString *str_url = [NSString stringWithFormat:VimeoBase, vimeoID];
//        NSMutableURLRequest *URLRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET"
//                                                                                        URLString:str_url
//                                                                                       parameters:nil
//                                                                                            error:nil];
//        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:URLRequest];
//        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
//            NSDictionary *jsonData = [self jsonParserWithData:responseObject];
//            NSString *vimeoUrl = jsonData[@"request"][@"files"][@"hls"][@"cdns"][@"akfire_interconnect_quic"][@"url"];
//            if (completion) {
//                completion(YES, vimeoUrl);
//            }
//        } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
//            if (completion) {
//                completion(NO, @"");
//            }
//        }];
//        self.requestOperation = op;
//        [[NSOperationQueue mainQueue] addOperation:op];
//    }

    func ShareLink(url: String) {
//        NSURL *shareUrl = [NSURL URLWithString:url];
//        NSArray *postItems = @[@"훈독가정교회", shareUrl];
//        UIActivityViewController *activityVC = [[UIActivityViewController alloc]
//                                                initWithActivityItems:postItems
//                                                applicationActivities:nil];
//
//        activityVC.excludedActivityTypes = @[];
//
//        [self presentViewController:activityVC animated:YES completion:nil];
    }

    func TTSRead(ttsValue: String) {
//        [mainDelegate.avAudioPlayer stop];
        
        let utterance = AVSpeechUtterance(string: ttsValue)
        
        utterance.rate = self.ttsRate
        
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        
        synthesizer.speak(utterance)
    }

    func TTSStop() {
//        isTTSPlay = NO;
//        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    
    // TODO:: 반환 값 처리 필요
    func TTSIsPlay() -> Bool {
        return false
        
//        BOOL isSpeaking = self->synthesizer.speaking
//        return isSpeaking
    }

    func TTSSpeechRate(rate: String) {
//        ttsRate = rate.floatValue / 2;
    }

    func SNSLogin(_ site: String) {
        switch site {
        case "google":
            googleLogin()
            break
        case "facebook":
            facebookLogin()
            break
        case "kakao":
            kakaoLogin()
            break
        default:
            break
        }
    }
    
    func googleLogin() {
        print("google login")
    }
    
    func facebookLogin() {
        print("facebook login")
    }
    
    func kakaoLogin() {
        print("kakao login")
    }

    func openBrowser(url: String) {
        if UIApplication.shared.canOpenURL(URL(string: url)!) {
            UIApplication.shared.open(URL(string: url)!)
        }
    }

    // TODO:: 반환 값 처리 필요
    func AppVersion() -> String {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String
        else { return "" }
            
        return version
    }
    
    func updatePlaybackProgressFromTimer(timer : Timer) {
//        if (!isPlaying) {
//            if ([mainDelegate.avAudioPlayer duration] > 0) {
//                isPlaying = YES;
//                Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
//                MPMediaItemArtwork *albumArt = nil;
//                if (playingInfoCenter) {
//                    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
//                    UIImage *img_albumArt = [UIImage imageNamed:@"appicon.png"];
//                    albumArt = [[MPMediaItemArtwork alloc] initWithImage:img_albumArt];
//                    [songInfo setObject:@"훈독가정교회" forKey:MPMediaItemPropertyArtist];
//                    [songInfo setObject:_audioTitle forKey:MPMediaItemPropertyTitle];
//                    [songInfo setObject:[NSString stringWithFormat:@"%f",[mainDelegate.avAudioPlayer duration]] forKey:MPMediaItemPropertyPlaybackDuration];
//                    [songInfo setObject:[NSNumber numberWithDouble:mainDelegate.avAudioPlayer.progress] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
//                    [songInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
//                    if (albumArt != nil) {
//                        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
//                    }
//                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
//                }
//            }
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (([UIApplication sharedApplication].applicationState == UIApplicationStateActive) &&
//                (self->mainDelegate.avAudioPlayer.state == STKAudioPlayerStatePlaying)) {
//            }
//        });
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "FFWPChurch",
              let messages = message.body as? [String: Any],
              let command = messages["command"] as? String else { return }
        
        print("command \(command)" )
        switch command {
        case "AudiosSetPlay":
            guard let index = messages["index"] as? String,
                  let title = messages["title"] as? String,
                  let desc = messages["desc"] as? String,
                  let audioPath = messages["audioPath"] as? String,
                  let type = messages["type"] as? String
            else { return }
            
            AudiosSetPlay(index: index, title: title, desc: desc, audioPath: audioPath, type: type)
            
            break
            
        case "AudioPlay":
            
            AudioPlay()
            break
            
        case "AudioPause":
            
            AudioPause()
            break
            
        case "AudioStop":
            
            AudioStop()
            break
            
        case "AudioIsPlay":
            guard let function = messages["function"] as? String
            else { return }
            
            AudioIsPlay(function: function)
            break
            
        case "AudioGetInfo":
            guard let function = messages["function"] as? String
            else { return }
            
            AudioGetInfo(function: function)
            break
            
        case "VideoSetPlay":
            guard let vimeoID = messages["vimeoID"] as? String
            else { return }
            
            VideoSetPlay(vimeoID: vimeoID)
            break
            
        case "ShareLink":
            guard let url = messages["url"] as? String
            else { return }
            
            ShareLink(url: url)
            break
            
        case "TTSRead":
            guard let text = messages["text"] as? String else { return }
            
            TTSRead(ttsValue: text)
            break
            
        case "TTSStop":
            
            TTSStop()
            break
            
        case "TTSIsPlay":
            
            let _ = TTSIsPlay()
            break
            
        case "TTSSpeechRate":
            guard let rate = messages["rate"] as? String else { return }
            
            TTSSpeechRate(rate: rate)
            break
            
        case "SNSLogin":
            guard let vimeoID = messages["vimeoID"] as? String
            else { return }
            
            VideoSetPlay(vimeoID: vimeoID)
            guard let name = messages["name"] as? String else { return }
            
            SNSLogin(name)
            break
            
        case "openBrowser":
            guard let url = messages["url"] as? String else { return }
            
            openBrowser(url: url)
            break
            
        case "AppVersion":
            
            let _ = AppVersion()
            break
        
        default:
            break
        }
        
    }
}

extension ViewController: AVSpeechSynthesizerDelegate {
    
}

extension ViewController: STKAudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
    }
}
