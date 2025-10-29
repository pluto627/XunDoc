//
//  AudioPlayerManager.swift
//  XunDoc
//
//  音频播放管理器
//

import Foundation
import AVFoundation

class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var currentAudioId: UUID?
    
    // 公开初始化器，允许每个视图创建独立的实例
    public override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            // 设置为playback类别,并使用扬声器输出
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ 音频会话已设置为扬声器输出模式")
        } catch {
            print("❌ 音频会话设置失败: \(error)")
        }
    }
    
    // MARK: - 播放控制
    
    func loadAudio(_ audioData: Data) {
        // 验证音频数据
        guard !audioData.isEmpty else {
            print("❌ 音频数据为空，无法加载")
            return
        }
        
        print("🎵 音频数据大小: \(audioData.count) 字节")
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            print("✅ 音频加载成功，时长: \(duration)秒")
        } catch let error as NSError {
            print("❌ 音频加载失败:")
            print("   错误域: \(error.domain)")
            print("   错误代码: \(error.code)")
            print("   错误描述: \(error.localizedDescription)")
            
            if error.code == -39 {
                print("   提示: 错误代码 -39 通常表示音频数据格式无效或文件损坏")
                print("   请确保音频数据是有效的音频格式 (如 .m4a, .mp3, .wav 等)")
            }
        }
    }
    
    func play(audioData: Data, audioId: UUID) {
        // 如果正在播放同一个音频，暂停
        if currentAudioId == audioId && isPlaying {
            pause()
            return
        }
        
        // 验证音频数据
        guard !audioData.isEmpty else {
            print("❌ 音频数据为空，无法播放")
            return
        }
        
        // 停止当前播放
        stop()
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentAudioId = audioId
            
            audioPlayer?.play()
            isPlaying = true
            
            startTimer()
            print("▶️ 开始播放音频，时长: \(duration)秒")
        } catch let error as NSError {
            print("❌ 音频播放失败:")
            print("   错误域: \(error.domain)")
            print("   错误代码: \(error.code)")
            print("   错误描述: \(error.localizedDescription)")
            
            if error.code == -39 {
                print("   提示: 音频数据格式无效，请检查音频文件")
            }
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    private func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
        print("⏸️ 暂停播放")
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        currentAudioId = nil
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateProgress()
    }
    
    func seek(toProgress newProgress: Double) {
        let time = duration * newProgress
        seek(to: time)
    }
    
    func skip(seconds: TimeInterval) {
        let newTime = max(0, min(currentTime + seconds, duration))
        seek(to: newTime)
    }
    
    // MARK: - 定时器
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0
        
        if currentTime >= duration && duration > 0 {
            stop()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        currentAudioId = nil
        stopTimer()
        print("✅ 音频播放完成")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ 音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        stop()
    }
}

