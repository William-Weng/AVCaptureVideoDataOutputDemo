import AVFoundation
import UIKit
import WWPrint

// MARK: - ViewController
final class ViewController: UIViewController {
    
    private var isRecording = false
    private var isSessionStarted = false
    
    private var captureSession: AVCaptureSession!
    private var cameraOutput: AVCaptureVideoDataOutput!
    private var audioOutput: AVCaptureAudioDataOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var currentSampleTime: CMTime?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    @IBAction func record(_ sender: UIBarButtonItem) {
        recordAction(sender: sender)
    }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate
extension ViewController: AVCaptureAudioDataOutputSampleBufferDelegate {}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if (output == cameraOutput) { captureVideoAction(output: output, didOutput: sampleBuffer, from: connection); return }
        if (output == audioOutput) { captureAudioAction(output: output, didOutput: sampleBuffer, from: connection); return }
    }
}

// MARK: - 主工具
private extension ViewController {
    
    /// 初始化設定 (Info.plist => NSCameraUsageDescription / NSMicrophoneUsageDescription)
    func initSetting() {
        cameraSessionSetting()
        previewLayerSetting()
    }
    
    /// 錄影開關的動作處理
    /// - Parameter sender: UIBarButtonItem
    func recordAction(sender: UIBarButtonItem) {
        
        var title: String = "Start"
        
        defer { sender.title = title }
        
        if isRecording { stopRecording(); return }
        
        startRecording()
        title = "Stop"
    }
    
    /// 處理取到的聲音Buffer
    /// - Parameters:
    ///   - output: AVCaptureOutput
    ///   - sampleBuffer: CMSampleBuffer
    ///   - connection: AVCaptureConnection
    func captureAudioAction(output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let assetWriter = assetWriter,
              isRecording,
              assetWriter.status == .writing
        else {
            return
        }
        
        if (isSessionStarted) { appendAudioBuffer(sampleBuffer) }
    }
    
    /// 處理取到的影片Buffer
    /// - Parameters:
    ///   - output: AVCaptureOutput
    ///   - sampleBuffer: CMSampleBuffer
    ///   - connection: AVCaptureConnection
    func captureVideoAction(output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let assetWriter = assetWriter,
              isRecording,
              assetWriter.status == .writing
        else {
            return
        }
        
        if !isSessionStarted {
            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            assetWriter._startSession(at: startTime) { isSessionStarted = true }
        }
        
        if (isSessionStarted) { appendPixelBuffer(sampleBuffer) }
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 設置AVCaptureSession + 執行
    func cameraSessionSetting() {
        
        let videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        let queueVideo = DispatchQueue(label: "idv.william.Example.video")
        let queueAudio = DispatchQueue(label: "idv.william.Example.audio")
        
        captureSession = AVCaptureSession._build(preset: .high)
        cameraOutput = AVCaptureVideoDataOutput._build(delegate: self, videoSettings: videoSettings, queue: queueVideo)
        audioOutput = AVCaptureAudioDataOutput._build(delegate: self, queue: queueAudio)
        
        guard let camera = AVCaptureDevice._default(for: .video),
              let audio = AVCaptureDevice._default(for: .audio),
              let cameraInput = try? camera._captureInput().get(),
              let audioInput = try? audio._captureInput().get(),
              captureSession._canAddInput(cameraInput),
              captureSession._canAddInput(audioInput),
              captureSession._canAddOutput(cameraOutput),
              captureSession._canAddOutput(audioOutput),
              cameraOutput._videoOrientation(.portrait)
        else {
            return
        }
        
        DispatchQueue.global(qos: .background).async { [unowned self] in
            captureSession.startRunning()
        }
    }
    
    /// 設置預覽圖層
    func previewLayerSetting() {
        previewLayer = captureSession._previewLayer(with: view.bounds, videoGravity: .resizeAspectFill)
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    /// 開始錄影
    func startRecording() {
        
        let outputURL = FileManager.default._documentDirectory()?.appendingPathComponent("\(Date()._localTime(timeZone: .current) ?? "").mov")
        let vedioSize: Constant.VedioSize = (720, 1280)
        let result = AVAssetWriter._build(outputURL: outputURL, fileType: .mov)
        
        switch result {
        case .failure(let error): wwPrint(error)
        case .success(let assetWriter):
            
            let videoWriterInput = AVAssetWriterInput._buildVedio(size: vedioSize)
            let audioWriterInput = AVAssetWriterInput._buildAudio()
            
            self.assetWriter = assetWriter
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor._build(videoWriterInput: videoWriterInput, vedioSize: vedioSize)
            
            if assetWriter._canAdd(input: videoWriterInput) { self.videoWriterInput = videoWriterInput }
            if assetWriter._canAdd(input: audioWriterInput) { self.audioWriterInput = audioWriterInput }
            
            assetWriter.startWriting()
            
            isRecording = true
            isSessionStarted = false  // 尚未開始寫入會話
        }
    }
    
    /// 停止錄影
    func stopRecording() {
        
        isRecording = false
        videoWriterInput?.markAsFinished()
        
        assetWriter?.finishWriting { [unowned self] in
            
            if let outputURL = assetWriter?.outputURL {
                wwPrint("Video saved to: \(outputURL)")
            }
            
            assetWriter = nil
            videoWriterInput = nil
            audioWriterInput = nil
            pixelBufferAdaptor = nil
            isSessionStarted = false
        }
    }
    
    /// 加入sampleBuffer到audioWriterInput中 <=> assetWriter
    /// - Parameter sampleBuffer: CMSampleBuffer
    func appendAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        
        guard let audioWriterInput = audioWriterInput,
              audioWriterInput.isReadyForMoreMediaData
        else {
            return
        }
        
        audioWriterInput.append(sampleBuffer)
    }
    
    /// 加入sampleBuffer到pixelBufferAdaptor中 <=> assetWriter
    /// - Parameter sampleBuffer: CMSampleBuffer
    func appendPixelBuffer(_ sampleBuffer: CMSampleBuffer) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let videoWriterInput = videoWriterInput,
              videoWriterInput.isReadyForMoreMediaData
        else {
            return
        }
        
        currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        pixelBufferAdaptor?.append(pixelBuffer, withPresentationTime: currentSampleTime!)
    }
}
