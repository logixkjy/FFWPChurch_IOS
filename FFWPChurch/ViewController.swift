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
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser
import FacebookLogin
import AuthenticationServices
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class ViewController: UIViewController {
    
    var webView: WKWebView!
    var topImage: UIImageView!
    var botImage: UIImageView!
    var jsContext: JSContext!
    var _webConfig: WKWebViewConfiguration?
    var synthesizer: AVSpeechSynthesizer!
    
    var ttsRate: Float = 0.0
    
    var jsonText: String!
    var playList: [Dictionary<String, String>] = []
    var playIndex = 0
    
    var audioTitle: String!
    var audioDesc: String!
    
    var isPlaying = true
    var isTTSPlay = true
    var isMultiPlay = false
    
    var isStopClick = false
    
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
        
        self.topImage = UIImageView().then {
            $0.image = UIImage(named: "statusBG")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), resizingMode: .stretch)
        }
        self.view.addSubview(self.topImage)
        self.topImage.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.width.equalTo(self.view)
            make.height.equalTo(DataCenter.getStatusBarHeight())
        }
        
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: config).then {
            $0.uiDelegate = self
            $0.navigationDelegate = self
        }
        self.view.addSubview(self.webView)
        self.webView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(DataCenter.getStatusBarHeight())
            make.bottom.equalTo(self.view).offset(DataCenter.getSafeAreaBottom())
            make.width.equalTo(self.view)
            make.height.equalTo(self.view).offset(-(DataCenter.getStatusBarHeight() + DataCenter.getSafeAreaBottom()))
        }
        
        self.botImage = UIImageView().then {
            $0.image = UIImage(named: "statusBG")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), resizingMode: .stretch)
        }
        self.view.addSubview(self.botImage)
        self.botImage.snp.makeConstraints { make in
            make.bottom.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.width.equalTo(self.view)
            make.height.equalTo(DataCenter.getSafeAreaBottom())
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPushAcionNotification(noti:)), name: NSNotification.Name(rawValue: "cmdDidPushAcionNotification"), object:nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPushAcionNotificationForeground(noti:)), name: NSNotification.Name(rawValue: "cmdDidPushAcionNotificationForeground"), object:nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didOpenURLNotification(noti:)), name: NSNotification.Name(rawValue: "cmdDicOpenURLNotification"), object:nil)
        
        if let schemeData = DataCenter.shared.schemeData {
            self.moveDirectURL(dic: schemeData)
            DataCenter.shared.schemeData = nil
        } else {
            let URL = URL(string: MAIN_URL)
            self.webView.load(URLRequest(url: URL!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TIME_OUT_INTERVAL))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //let value = UIInterfaceOrientation.landscapeLeft.rawValue
        //UIDevice.current.setValue(value, forKey: "orientation")


        AppDelegate.AppUtility.lockOrientation(.portrait)

    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func moveDirectURL(dic: Dictionary<String, String>) {
        var str_url = DIRECT_URL
        if let appParam1 = dic["appParam1"] {
            str_url = str_url + "?appParam1=\(appParam1)"
        }
        if let appParam2 = dic["appParam2"] {
            str_url = str_url + "&appParam2=\(appParam2)"
        }
        if let appParam3 = dic["appParam3"] {
            str_url = str_url + "&appParam3=\(appParam3)"
        }
        if let appParam4 = dic["appParam4"] {
            str_url = str_url + "&appParam4=\(appParam4)"
        }
        print(str_url)
        
        let URL = URL(string: str_url)
        self.webView.load(URLRequest(url: URL!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TIME_OUT_INTERVAL))
    }
    
    @objc func didPushAcionNotification(noti: Notification) {
//        [self onPushAction:noti.userInfo];
    }


    @objc func didPushAcionNotificationForeground(noti: Notification) {
        if let aps = noti.userInfo!["aps"] as? [String : Any] {
            guard let alert = aps["alert"] as? [String : Any],
                  let title = alert["title"] as? String,
                  let msg = alert["body"] as? String else { return }
                
            let alertController = UIAlertController.init(title: title, message: msg, preferredStyle: .alert)
            
            let okAction = UIAlertAction.init(title: "확인", style: .default) { action in
                self.onPushAction(userInfo: noti.userInfo!)
            }
            
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true)
        }
    }

    func onPushAction(userInfo: Dictionary<AnyHashable, Any>) {
        if userInfo["type"] as! String == "url" {
            if let url = userInfo["info"] {
                let URL = URL(string: url as! String)
                self.webView.load(URLRequest(url: URL!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TIME_OUT_INTERVAL))
            }
        } else if userInfo["type"] as! String == "vimeo" {
            let arr = (userInfo["info"] as! String).components(separatedBy: "=")
            self.VideoSetPlay(vimeoID: arr.count > 1 ? arr[1] : arr[0])
        }
        DataCenter.shared.userInfo = nil
    }
    
    @objc func didOpenURLNotification(noti: Notification) {
        guard let dic = (noti.userInfo ?? [:]) as? [String:String] else { return }
        self.moveDirectURL(dic: dic)
    }
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert);
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) {
            _ in
            completionHandler()
        }
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert);
        let cancelAction = UIAlertAction(title: "아니요", style: .cancel) {
            _ in
            completionHandler(false)
            
        }
        let okAction = UIAlertAction(title: "예", style: .default) {
            _ in
            completionHandler(true)
            
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
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
                
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updatePlaybackProgressFromTimer(timer:)), userInfo: nil, repeats: true)
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
    
    func AudiosSetMultPlay(jsonParam: String) {
        self.playList = JsonUtil.jsonParser(jsonParam) as! [Dictionary<String, String>]
        self.playIndex = 0;
        self.isMultiPlay = true
        
        let playItem = self.playList[self.playIndex]
        AudiosSetPlay(index: playItem["key"]!, title: playItem["title"]!, desc: playItem["subTitle"] ?? "", audioPath: playItem["audioUrl"]!, type: playItem["audioType"] ?? "")
    }
    
    func AudioPlay() {
        mainDelegate.avAudioPlayer?.resume()
    }
    
    func AudioPause() {
        mainDelegate.avAudioPlayer?.pause()
    }
    
    func AudioStop() {
        self.jsonText = ""
        self.isMultiPlay = false // 오디오 정지가 되면 멀티플레이도 정지 되어야 함,
        self.isStopClick = true
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
        requestVimeoUrl(vimeoID: vimeoID) { [self] success, vimeoUrl in
            if success == true {
                if !vimeoUrl.isEmpty {
                    DispatchQueue.main.async {
                        self.mainDelegate.avAudioPlayer?.stop()
                        
                        self.mainDelegate.avVideoPlayer = FFAVPlayerViewController()
                        let player = AVPlayer(url: URL(string: vimeoUrl)!)
                        self.mainDelegate.avVideoPlayer?.player = player
                        self.mainDelegate.avVideoPlayer?.modalPresentationStyle = .fullScreen
                        self.mainDelegate.avVideoPlayer?.view.frame = self.view.bounds
                        
                        NotificationCenter.default.addObserver(self, selector: #selector(self.AVPlayerItemDidPlayToEndTimeNotification), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.mainDelegate.avVideoPlayer?.player?.currentItem)
                        
                        self.mainDelegate.avVideoPlayer?.player?.play()
                        
                        //                    self.mainDelegate.avVideoPlayer?.view.setFrame:self.view.frame];
                        
                        self.present(self.mainDelegate.avVideoPlayer!, animated: false)
                    }
                }
            }
        }
    }
    
    func requestVimeoUrl(vimeoID: String, closure: @escaping (_ success: Bool, _ vimeoUrl: String) -> Void) {
        let str_url = String.init(format: VimeoBase, vimeoID)
        let URLRequest = URLRequest(url: URL(string: str_url)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TIME_OUT_INTERVAL)
        
        URLSession.shared.dataTask(with: URLRequest) { data, response, error in
            if let result = data {
                let jsonData = JsonUtil.jsonParser(with: result) as! Dictionary<String, Any>
                if let req = jsonData["request"] as? Dictionary<String, Any> {
                    if let files = req["files"] as? Dictionary<String, Any> {
                        if let hls =  files["hls"] as? Dictionary<String, Any> {
                            if let cdns = hls["cdns"] as? Dictionary<String, Any> {
                                if let akfire = cdns["akfire_interconnect_quic"] as? Dictionary<String, Any> {
                                    if let url = akfire["url"] as? String {
                                        closure(true, url)
                                        return
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            closure(false, "")
        }.resume()
    }
    
    @objc func AVPlayerItemDidPlayToEndTimeNotification() {
        mainDelegate.avVideoPlayer?.player?.pause()
        mainDelegate.avVideoPlayer?.dismiss(animated: false)
    }
    
    func ShareLink(url: String, title: String, subTile: String) {
        let shareUrl = URL(string: url)
        let postItems = [title.isEmpty ? "천보가정교회" : "", subTile.isEmpty ? "" : subTile,  shareUrl!] as [Any]
        let activityVC = UIActivityViewController.init(activityItems: postItems, applicationActivities: nil)
        
        activityVC.excludedActivityTypes = []
        
        self.present(activityVC, animated: true)
    }
    
    func TTSRead(ttsValue: String) {
        self.mainDelegate.avAudioPlayer?.stop()
        
        let utterance = AVSpeechUtterance(string: ttsValue)
        
        utterance.rate = self.ttsRate
        
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        
        synthesizer.speak(utterance)
    }
    
    func TTSStop() {
        isTTSPlay = false
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // TODO:: 반환 값 처리 필요
    func TTSIsPlay(function: String) {
        let isSpeaking = self.synthesizer.isSpeaking
        let exec = "\(function)(\(isSpeaking));"
        
        self.webView.evaluateJavaScript(exec) { result, error in
            if let anError = error {
                print("[Error Message] : \(anError)")
            }
        }
    }
    
    func TTSSpeechRate(rate: String) {
        ttsRate = (rate as NSString).floatValue / 2;
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
        case "apple":
            appleLogin()
            break
        default:
            break
        }
    }
    
    func googleLogin() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                
                var userId: String = ""
                if let id =  (authResult?.additionalUserInfo?.profile!["id"] as? String) {
                    userId = id
                } else {
                    if let sub = (authResult?.additionalUserInfo?.profile!["sub"] as? String) {
                        userId = sub
                    }
                }
                
                let user = authResult?.user
                
                let szSite = "google"
                let szUserId = userId.count > 0 ? userId : ""
                let szName = user?.displayName != nil && (user?.displayName!.count)! > 0 ? user?.displayName : ""
                let szEmail = user?.email != nil && (user?.email!.count)! > 0 ? user?.email : ""
                
                if szUserId.count > 0 {
                    let userInfo = ["site": szSite as String, "id": szUserId as String, "name": szName! as String, "email": szEmail! as String]
                    
                    self.snsLoginApp(userInfo: userInfo)
                } else {
                    MNMToast.show(withText: "로그인에 실패했습니다. 잠시후 다시 시도해 주세요.", completionHandler: nil, tapHandler: nil)
                }
            }
        }
    }
    
    func facebookLogin() {
        if (AccessToken.current != nil) {
            self.getFacebookInfo()
        } else {
            let manager = LoginManager()
            manager.logIn(permissions: ["public_profile", "email"], from: self) { result, error in
                if let error = error {
                    print("Process error: \(error)")
                    return
                }
                guard let result = result else {
                    print("No Result")
                    return
                }
                if result.isCancelled {
                    print("Login Cancelled")
                    return
                }
                
                if (AccessToken.current != nil) {
                    self.getFacebookInfo()
                }
            }
        }
    }
    
    func getFacebookInfo() {
        print("Token is available : \(AccessToken.current?.tokenString ?? "")")
        
        GraphRequest.init(graphPath: "me", parameters: ["fields": "id, name, email"]).start { connection, result, error in
            if (error == nil) {
                var bError = false
                let szSite = "facebook"
                
                guard let item = result as? Dictionary<String, String> else {
                    return
                }
                var szUserId: String = ""
                if let userId = item["id"] {
                    szUserId = userId
                } else {
                    bError = false
                }
                
                var szName: String = ""
                if let name = item["name"] {
                    szName = name
                }
                
                var szEmail: String = ""
                if let email = item["email"] {
                    szEmail = email
                }
                
                let userInfo = ["site": szSite, "id": szUserId, "name": szName, "email": szEmail]
                
                if bError {
                    MNMToast.show(withText: "로그인에 실패했습니다. 잠시후 다시 시도해 주세요.", completionHandler: nil, tapHandler: nil)
                } else {
                    self.snsLoginApp(userInfo: userInfo)
                }
            }
            else
            {
                MNMToast.show(withText: "로그인에 실패했습니다. 잠시후 다시 시도해 주세요.", completionHandler: nil, tapHandler: nil)
            }
        }
    }
    
    func kakaoLogin() {
        // 카카오톡 실행 가능 여부 확인
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                }
                else {
                    print("loginWithKakaoTalk() success.")
                    
                    //do something
                    _ = oauthToken
                    
                    UserApi.shared.me() {(user, error) in
                        if let error = error {
                            print(error)
                        }
                        else {
                            print("me() success.")
                            
                            let szSite = "kakaotalk"
                            
                            var szUserId: String = ""
                            if let userId = user?.id {
                                szUserId = "\(userId)"
                            }
                            
                            var szName: String = ""
                            if let name = user?.kakaoAccount?.profile?.nickname {
                                szName = name
                            }
                            
                            var szEmail: String = ""
                            if let email = user?.kakaoAccount?.email {
                                szEmail = email
                            }
                            
                            if szUserId.count > 0 {
                                let userInfo = ["site": szSite, "id": szUserId, "name": szName, "email": szEmail]
                                
                                self.snsLoginApp(userInfo: userInfo)
                            } else {
                                MNMToast.show(withText: "로그인에 실패했습니다. 잠시후 다시 시도해 주세요.", completionHandler: nil, tapHandler: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func appleLogin() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email] //유저로 부터 알 수 있는 정보들(name, email)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    
    func snsLoginApp(userInfo: Dictionary<String, String>) {
        print("\(userInfo)")
        
        let exec = "snsLoginApp(\"\(userInfo["site"] ?? "")\",\"\(userInfo["id"] ?? "")\",\"\(userInfo["name"] ?? "")\",\"\(userInfo["email"] ?? "")\");"
        
        self.webView.evaluateJavaScript(exec) { result, error in
            if let anError = error {
                print("[Error Message] : \(anError)")
            }
        }
    }
    
    func openBrowser(url: String) {
        if UIApplication.shared.canOpenURL(URL(string: url)!) {
            UIApplication.shared.open(URL(string: url)!)
        }
    }
    
    // TODO:: 반환 값 처리 필요
    func AppVersion(function: String) {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String
        else { return }
        
        let exec = String.init(format: "%@(\"%@\");", function, version)
        
        self.webView.evaluateJavaScript(exec) { result, error in
            if let anError = error {
                print("[Error Message] : \(anError)")
            }
        }
    }
    
    @objc func updatePlaybackProgressFromTimer(timer : Timer) {
        if !isPlaying {
            if self.mainDelegate.avAudioPlayer!.duration > 0 {
                isPlaying = true
                let playingInfoCenter: AnyClass? = NSClassFromString("MPNowPlayingInfoCenter")
                var albumArt: MPMediaItemArtwork? = nil
                if (playingInfoCenter != nil) {
                    var songInfo = [String: Any]()
                    if let img_albumArt = UIImage(named: "appicon") {
                        albumArt = MPMediaItemArtwork.init(image: img_albumArt)
                    }
                    songInfo.updateValue("천보가정교회", forKey: MPMediaItemPropertyArtist)
                    songInfo.updateValue(self.audioTitle!, forKey: MPMediaItemPropertyTitle)
                    songInfo.updateValue(String.init(format: "%f", self.mainDelegate.avAudioPlayer!.duration), forKey: MPMediaItemPropertyPlaybackDuration)
                    songInfo.updateValue(NSNumber(value: self.mainDelegate.avAudioPlayer!.progress), forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
                    songInfo.updateValue(NSNumber(1), forKey: MPNowPlayingInfoPropertyPlaybackRate)
                    if albumArt != nil {
                        songInfo.updateValue(albumArt!, forKey: MPMediaItemPropertyArtwork)
                    }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
                }
            }
        }
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active &&
                self.mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.playing {
                
            }
        }
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent) {
        if event.type == UIEvent.EventType.remoteControl {
            switch event.subtype {
            case .remoteControlTogglePlayPause:
                if self.mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.playing {
                    self.mainDelegate.avAudioPlayer?.pause()
                    
                    let exec = "audioPauseClick();"
                    self.webView.evaluateJavaScript(exec) { result, error in
                        if let anError = error {
                            print("[Error Message] : \(anError)")
                        }
                    }
                    
                    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  mainDelegate.avAudioPlayer?.progress
                    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    
                } else if self.mainDelegate.avAudioPlayer?.state == STKAudioPlayerState.paused {
                    self.mainDelegate.avAudioPlayer?.resume()
                    
                    let exec = "audioPlayClick();"
                    self.webView.evaluateJavaScript(exec) { result, error in
                        if let anError = error {
                            print("[Error Message] : \(anError)")
                        }
                    }
                    
                    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  mainDelegate.avAudioPlayer?.progress
                    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
                    
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    
                }
                print("UIEventSubtypeRemoteControlTogglePlayPause")
                break
            case .remoteControlPlay:
                print("UIEventSubtypeRemoteControlPlay")
                self.mainDelegate.avAudioPlayer?.resume()
                
                let exec = "audioPlayClick();"
                self.webView.evaluateJavaScript(exec) { result, error in
                    if let anError = error {
                        print("[Error Message] : \(anError)")
                    }
                }
                
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  mainDelegate.avAudioPlayer?.progress
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                break
            case .remoteControlPause:
                print("UIEventSubtypeRemoteControlPause")
                self.mainDelegate.avAudioPlayer?.pause()
                
                let exec = "audioPauseClick();"
                self.webView.evaluateJavaScript(exec) { result, error in
                    if let anError = error {
                        print("[Error Message] : \(anError)")
                    }
                }
                
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  mainDelegate.avAudioPlayer?.progress
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                break
                
            case .remoteControlStop:
                print("UIEventSubtypeRemoteControlStop")
                self.mainDelegate.avAudioPlayer?.stop()
                
//                let exec = "audioStopClick();"
//                self.webView.evaluateJavaScript(exec) { result, error in
//                    if let anError = error {
//                        print("[Error Message] : \(anError)")
//                    }
//                }
                
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  mainDelegate.avAudioPlayer?.progress
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                break
            case .remoteControlNextTrack:
                print("UIEventSubtypeRemoteControlNextTrack")
                // 전곡 듣기시에만 동작
                break
            case .remoteControlPreviousTrack:
                print("UIEventSubtypeRemoteControlPreviousTrack")
                // 전곡 듣기시에만 동작
                break
            case .remoteControlBeginSeekingBackward:
                print("UIEventSubtypeRemoteControlBeginSeekingBackward")
                break
            case .remoteControlEndSeekingBackward:
                print("UIEventSubtypeRemoteControlEndSeekingBackward")
                break
            case .remoteControlBeginSeekingForward:
                print("UIEventSubtypeRemoteControlBeginSeekingForward")
                break
            case .remoteControlEndSeekingForward:
                print("UIEventSubtypeRemoteControlEndSeekingForward")
                break
                
            default:
                break;
            }
        }
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
            guard let url = messages["targetUrl"] as? String
            else { return }
            
            let title = messages["title"] as? String
            let subtitle = messages["subtitle"] as? String
            
            ShareLink(url: url, title: title ?? "", subTile: subtitle ?? "")
            break
            
        case "TTSRead":
            guard let text = messages["text"] as? String else { return }
            
            TTSRead(ttsValue: text)
            break
            
        case "TTSStop":
            
            TTSStop()
            break
            
        case "TTSIsPlay":
            guard let function = messages["function"] as? String
            else { return }
            
            TTSIsPlay(function: function)
            break
            
        case "TTSSpeechRate":
            guard let rate = messages["rate"] as? String else { return }
            
            TTSSpeechRate(rate: rate)
            break
            
        case "SNSLogin":
            guard let site = messages["site"] as? String
            else { return }
            
            SNSLogin(site)
            break
            
        case "openBrowser":
            guard let url = messages["url"] as? String else { return }
            
            openBrowser(url: url)
            break
            
        case "AppVersion":
            guard let function = messages["function"] as? String
            else { return }
            
            AppVersion(function: function)
            break
            
        case "AudiosSetMultPlay":
            guard let jsonParam = messages["jsonParam"] as? String
            else { return }
            
            AudiosSetMultPlay(jsonParam: jsonParam)
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
        
        if self.isMultiPlay {
            // 마지막 곡이라면 정지 처리 해주어야 한다.
            if self.playIndex == self.playList.count - 1 {
                self.isMultiPlay = false
                self.playIndex = 0
            } else {
                self.playIndex += 1
                
                let playItem = self.playList[self.playIndex]
                AudiosSetPlay(index: playItem["key"]!, title: playItem["title"]! , desc: playItem["subTitle"] ?? "", audioPath: playItem["audioUrl"]!, type: playItem["audioType"] ?? "")
                
                return
            }
        }
        
        if stopReason != .userAction {
            self.isStopClick = true
        }
        
        self.jsonText = ""
        if self.isStopClick {
            self.isStopClick = false
            let exec = "audioStopClick();"
            self.webView.evaluateJavaScript(exec) { result, error in
                if let anError = error {
                    print("[Error Message] : \(anError)")
                }
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        //로그인 성공
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            // You can create an account in your system.
            let userIdentifier = appleIDCredential.user
            var szName: String = ""
            if let fullName = appleIDCredential.fullName {
                let givenName = appleIDCredential.fullName?.givenName
                let familyName = appleIDCredential.fullName?.familyName
                szName = (familyName ?? "") + (givenName ?? "")
            }
            
            var szEmail: String = ""
            if let email = appleIDCredential.email {
                szEmail = email
            }
            
            // 애플로그인은 최초 한번만 사용자 정보를 제공하고 다음부턴 정보를 주지 않아 추가된 코드
            var result = DataCenter.readObjectFromDefault(userIdentifier) as? Dictionary<String, String>
            if result == nil && szName.count > 0 && szEmail.count > 0 {
                result = ["id": userIdentifier, "name": szName , "email": szEmail]
                
                DataCenter.writeObjectToDefault(result as Any, userIdentifier)
            }
            
            if  let authorizationCode = appleIDCredential.authorizationCode,
                let identityToken = appleIDCredential.identityToken,
                let authCodeString = String(data: authorizationCode, encoding: .utf8),
                let identifyTokenString = String(data: identityToken, encoding: .utf8) {
                print("authorizationCode: \(authorizationCode)")
                print("identityToken: \(identityToken)")
                print("authCodeString: \(authCodeString)")
                print("identifyTokenString: \(identifyTokenString)")
            }
            
            if result != nil && ( szName.count <= 0 || szEmail.count <= 0 ) {
                if let name = result!["name"] {
                    szName = name
                }
                if let email = result?["email"] {
                    szEmail = email
                }
            }
            let szSite = "apple"
            result?.updateValue(szSite, forKey: "site")
            
            self.snsLoginApp(userInfo: result!)
            //Move to MainPage
            //let validVC = SignValidViewController()
            //validVC.modalPresentationStyle = .fullScreen
            //present(validVC, animated: true, completion: nil)
            
        case let passwordCredential as ASPasswordCredential:
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            print("username: \(username)")
            print("password: \(password)")
            
        default:
            break
        }
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // 로그인 실패(유저의 취소도 포함)
        print("login failed - \(error.localizedDescription)")
    }
}

extension ViewController: ASAuthorizationControllerDelegate  {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
