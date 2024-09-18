//
//  ViewController.swift
//  AVVideoPlayer
//
//  Created by Ateeq Ahmed on 18/09/24.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    @IBOutlet weak var videoPlayer: UIView!
    @IBOutlet weak var videoControls: UIView!
    @IBOutlet weak var videoPlayerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var backward10Sec: UIImageView! {
        didSet {
            self.backward10Sec.isUserInteractionEnabled = true
            self.backward10Sec.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapBackward10Sec)))
        }
    }
    
    @IBOutlet weak var playPause: UIImageView! {
        didSet {
            self.playPause.isUserInteractionEnabled = true
            self.playPause.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapPlayPause)))
        }
    }
    
    @IBOutlet weak var forward10Sec: UIImageView! {
        didSet {
            self.forward10Sec.isUserInteractionEnabled = true
            self.forward10Sec.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapForward10Sec)))
        }
    }
    
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var videoSlider: UISlider! {
        didSet {
            self.videoSlider.addTarget(self, action: #selector(onSliding), for: .valueChanged)
        }
    }
    
    @IBOutlet weak var expandVideo: UIImageView! {
        didSet {
            self.expandVideo.isUserInteractionEnabled = true
            self.expandVideo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapExpand)))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard let url = URL(string: "https://file-examples.com/storage/feaf6fc38466e98369950a4/2017/04/file_example_MP4_1280_10MG.mp4") else { return }
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        videoPlayer.layer.addSublayer(playerLayer!)
        videoPlayer.layer.addSublayer(videoControls.layer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.player?.play()
            self.setTimeObserverToPlayer()
        }
    }
    
//MARK: Called inside willTransition so no need in this
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//        self.playerLayer?.frame = self.videoPlayer.bounds
//    }
    
    private var windowInterface: UIInterfaceOrientation? {
        return view.window?.windowScene?.interfaceOrientation
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        guard let windowInterface = self.windowInterface else { return }
        
        if windowInterface.isPortrait == true {
            self.videoPlayerHeight.constant = 220
        }
        else {
            self.videoPlayerHeight.constant = self.view.layer.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.playerLayer?.frame = self.videoPlayer.bounds
        })
    }
    
    //MARK: VideoPlayer Time Calculate
    
    private var timeObserver: Any?
    
    private func setTimeObserverToPlayer() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsed in
            self.updatePlayerTime()
        })
    }
    
    private func updatePlayerTime() {
        guard let currentTime = self.player?.currentTime() else { return }
        guard let duration = self.player?.currentItem?.duration else { return }
        
        let currentTimeInSec = CMTimeGetSeconds(currentTime)
        let durationInSec = CMTimeGetSeconds(duration)
        
        startTimeLabel.text = "\(Int(currentTimeInSec))"
        durationLabel.text = "\(Int(durationInSec))"
        
        if isSeeking == false {
            self.videoSlider.value = Float(currentTimeInSec / durationInSec)
        }
    }
    
    
    //MARK: On Tap Screen Methods
    
    @objc func onTapBackward10Sec() {
        guard let currentTime = self.player?.currentTime() else {return}
        let seek10SecBack = CMTimeGetSeconds(currentTime).advanced(by: -10)
        let seekTime = CMTime(value: CMTimeValue(seek10SecBack), timescale: 1)
        self.player?.seek(to: seekTime)
    }

    @objc func onTapForward10Sec() {
        guard let currentTime = self.player?.currentTime() else { return }
        let seek10secForward = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(seek10secForward), timescale: 1)
        self.player?.seek(to: seekTime)
    }
    
    @objc func onTapPlayPause() {
        if self.player?.timeControlStatus == .playing {
            self.playPause.image = UIImage(systemName: "pause")
            self.player?.pause()
        }
        else {
            self.playPause.image = UIImage(systemName: "play")
            self.player?.play()
        }
    }
    
    private var isSeeking: Bool = false
    
    @objc func onSliding() {
        self.isSeeking = true
        
        guard let duration = self.player?.currentItem?.duration else { return }
        
        let value = Float64(self.videoSlider.value) * CMTimeGetSeconds(duration)
        
        if value.isNaN == false {
            let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
            self.player?.seek(to: seekTime, completionHandler: { completed in
                if completed {
                    self.isSeeking = false
                }
            })
        }
    }
    
    @objc func onTapExpand() {
        if #available(iOS 16.0, *) {
            guard let windowScene = self.view.window?.windowScene else { return }
            if windowScene.interfaceOrientation == .portrait {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                    print(error.localizedDescription)
                }
            }
            else {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                    print(error.localizedDescription)
                }
            }
        }
        
        else {
            if UIDevice.current.orientation == .portrait {
                let orientation = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(orientation, forKey: "orientation")
            }
            else {
                let orientation = UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(orientation, forKey: "orientation")
            }
        }
    }

}

