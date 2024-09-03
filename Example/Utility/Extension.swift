//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2024/1/1.
//

import AVFoundation
import UIKit

// MARK: - Date (function)
extension Date {
    
    /// 將UTC時間 => 該時區的時間
    /// - 2020-07-07 16:08:50 +0800
    /// - Parameters:
    ///   - dateFormat: 時間格式
    ///   - timeZone: 時區
    /// - Returns: String?
    func _localTime(with dateFormat: Constant.DateFormat = .full, timeZone: TimeZone) -> String? {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = timeZone
        
        switch dateFormat {
        case .meridiem(formatLocale: let locale): dateFormatter.locale = locale
        default: break
        }
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - FileManager (function)
extension FileManager {
    
    /// User的「暫存」資料夾
    /// - => ~/tmp/
    /// - Returns: URL
    func _temporaryDirectory() -> URL { return self.temporaryDirectory }
    
    /// [取得User的資料夾](https://cdfq152313.github.io/post/2016-10-11/)
    /// - UIFileSharingEnabled = YES => iOS設置iTunes文件共享
    /// - Parameter directory: User的資料夾名稱
    /// - Returns: [URL]
    func _userDirectory(for directory: FileManager.SearchPathDirectory) -> [URL] { return Self.default.urls(for: directory, in: .userDomainMask) }
    
    /// User的「文件」資料夾URL
    /// - => ~/Documents/ (UIFileSharingEnabled)
    /// - Returns: URL?
    func _documentDirectory() -> URL? { return self._userDirectory(for: .documentDirectory).first }
}

// MARK: - AVCaptureDevice (static function)
extension AVCaptureDevice {
    
    /// 取得預設影音裝置 (NSCameraUsageDescription / NSMicrophoneUsageDescription)
    static func _default(for type: AVMediaType) -> AVCaptureDevice? { return AVCaptureDevice.default(for: type) }
}

// MARK: - AVCaptureDevice (function)
extension AVCaptureDevice {
    
    /// 取得裝置的Input => NSCameraUsageDescription / NSMicrophoneUsageDescription
    func _captureInput() -> Result<AVCaptureDeviceInput, Error> {
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: self)
            return .success(deviceInput)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - AVCaptureSession (static function)
extension AVCaptureSession {
    
    /// 建立AVCaptureSession
    /// - Parameter preset: [AVCaptureSession.Preset](https://blog.csdn.net/xx352890098/article/details/77886061)
    /// - Returns: AVCaptureSession
    static func _build(preset: AVCaptureSession.Preset) -> AVCaptureSession {
        
        let session = AVCaptureSession()
        session.sessionPreset = preset
        
        return session
    }
}

// MARK: - AVCaptureSession (function)
extension AVCaptureSession {
    
    /// 將影音的Input加入Session
    /// - Parameter input: AVCaptureInput
    /// - Returns: Bool
    func _canAddInput(_ input: AVCaptureInput?) -> Bool {
        
        guard let input = input,
              canAddInput(input)
        else {
            return false
        }
        
        addInput(input)
        return true
    }
    
    /// 將影音的Output加入Session
    /// - Parameter input: AVCaptureOutput
    /// - Returns: Bool
    func _canAddOutput(_ output: AVCaptureOutput?) -> Bool {
        
        guard let output = output,
              canAddOutput(output)
        else {
            return false
        }
        
        addOutput(output)
        return true
    }
    
    /// [產生、設定AVCaptureVideoPreviewLayer](https://www.jianshu.com/p/95f2cd87ad83)
    /// - Parameters:
    ///   - frame: CGRect
    ///   - videoGravity: AVLayerVideoGravity => .resizeAspectFill
    /// - Returns: AVCaptureVideoPreviewLayer
    func _previewLayer(with frame: CGRect, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> AVCaptureVideoPreviewLayer {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self)
        
        previewLayer.frame = frame
        previewLayer.videoGravity = videoGravity
        
        return previewLayer
    }
}

// MARK: - AVCaptureAudioDataOutput (static function)
extension AVCaptureAudioDataOutput {
    
    /// AVCaptureAudioDataOutput (聲音)
    /// - Parameters:
    ///   - delegate: AVCaptureAudioDataOutputSampleBufferDelegate?
    ///   - queue: DispatchQueue?
    /// - Returns: AVCaptureAudioDataOutput
    static func _build(delegate: AVCaptureAudioDataOutputSampleBufferDelegate?, queue: DispatchQueue?) -> AVCaptureAudioDataOutput {
        
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(delegate, queue: queue)
        
        return output
    }
}

// MARK: - AVCaptureVideoDataOutput (static function)
extension AVCaptureVideoDataOutput {
    
    /// 建立AVCaptureVideoDataOutput (影像)
    /// - Parameters:
    ///   - delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    ///   - videoSettings: [String : Any]?
    ///   - queue: DispatchQueue?
    /// - Returns: AVCaptureVideoDataOutput
    static func _build(delegate: AVCaptureVideoDataOutputSampleBufferDelegate?, videoSettings: [String : Any] = [:], queue: DispatchQueue?) -> AVCaptureVideoDataOutput {
        
        let output = AVCaptureVideoDataOutput()
        
        output.videoSettings = videoSettings
        output.setSampleBufferDelegate(delegate, queue: queue)
        
        return output
    }
}

// MARK: - AVCaptureVideoDataOutput (function)
extension AVCaptureVideoDataOutput {
    
    /// [設定影片的輸出方向](https://www.codenong.com/3823461/)
    /// - Parameter orientation: [AVCaptureVideoOrientation](https://medium.com/onfido-tech/live-face-tracking-on-ios-using-vision-framework-adf8a1799233)
    /// - Returns: Bool
    func _videoOrientation(_ orientation: AVCaptureVideoOrientation = .portrait) -> Bool {
        
        guard let connection = connection(with: .video),
              connection.isVideoOrientationSupported
        else {
            return false
        }

        connection.videoOrientation = orientation
        return true
    }
}

// MARK: - AVAssetWriter (function)
extension AVAssetWriter {
    
    /// [建立AVAssetWriter](https://juejin.cn/post/7159531544413995044)
    /// - Parameters:
    ///   - outputURL: [URL?](https://juejin.cn/post/7159149701143461896)
    ///   - fileType: AVFileType
    /// - Returns: Result<AVAssetWriter, Error>
    static func _build(outputURL: URL?, fileType: AVFileType) -> Result<AVAssetWriter, Error> {
        
        guard let outputURL = outputURL else { return .failure(Constant.MyError.isEmpty) }
        
        do {
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: fileType)
            return .success(writer)
        } catch  {
            return .failure(error)
        }
    }
}

// MARK: - AVAssetWriterInput (function)
extension AVAssetWriter {
    
    func _startSession(at startTime: CMTime, action: () -> Void) {
        startSession(atSourceTime: startTime)
        action()
    }
    
    /// 加入Input
    /// - Parameter input: AVAssetWriterInput?
    /// - Returns: Bool
    func _canAdd(input: AVAssetWriterInput?) -> Bool {
        
        guard let input = input,
              canAdd(input)
        else {
            return false
        }
        
        add(input)
        return true
    }
}

// MARK: - AVAssetWriterInput (static function)
extension AVAssetWriterInput {
    
    /// [建立AVAssetWriterInput](https://www.cnblogs.com/zoule/p/14913203.html)
    /// - Parameters:
    ///   - mediaType: AVMediaType
    ///   - outputSettings: outputSettings
    ///   - sourceFormatHint: sourceFormatHint
    ///   - isExpectsMediaDataInRealTime: Bool
    /// - Returns: AVAssetWriterInput
    static func _build(mediaType: AVMediaType, outputSettings: [String: Any]?, sourceFormatHint: CMFormatDescription?, isExpectsMediaDataInRealTime: Bool) -> AVAssetWriterInput {
        
        let input = AVAssetWriterInput(mediaType: mediaType, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint)
        input.expectsMediaDataInRealTime = isExpectsMediaDataInRealTime
        
        return input
    }
    
    /// [建立影片AVAssetWriterInput](https://juejin.cn/post/6844903929252151304)
    /// - Parameters:
    ///   - size: 影片尺寸大小
    ///   - codec: 影片編碼格式
    ///   - sourceFormatHint: CMFormatDescription?
    ///   - isExpectsMediaDataInRealTime: 針對即時性進行最佳化
    /// - Returns: AVAssetWriterInput
    static func _buildVedio(size: Constant.VedioSize, codec: AVVideoCodecType = .h264, sourceFormatHint: CMFormatDescription? = nil, isExpectsMediaDataInRealTime: Bool = true) -> AVAssetWriterInput {
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        
        return Self._build(mediaType: .video, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint, isExpectsMediaDataInRealTime: isExpectsMediaDataInRealTime)
    }
    
    /// 建立聲音AVAssetWriterInput
    /// - Parameters:
    ///   - format: 音頻格式 (kAudioFormatMPEG4AAC / kAudioFormatMPEGLayer3)
    ///   - channels: 通道數 (單聲道 / 雙聲道)
    ///   - sampleRate: 頻率取樣 (Hz)
    ///   - bitRate: 比特率 / 取樣率 (bps)
    ///   - sourceFormatHint: CMFormatDescription?
    ///   - isExpectsMediaDataInRealTime: 針對即時性進行最佳化
    /// - Returns: AVAssetWriterInput
    static func _buildAudio(format: AudioFormatID = kAudioFormatMPEG4AAC, channels: Int = 2, sampleRate: Int = 44100, bitRate: Int = 64000, sourceFormatHint: CMFormatDescription? = nil, isExpectsMediaDataInRealTime: Bool = true) -> AVAssetWriterInput {
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: format,
            AVNumberOfChannelsKey: channels,
            AVSampleRateKey: sampleRate,
            AVEncoderBitRateKey: bitRate
        ]
        
        return Self._build(mediaType: .audio, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint, isExpectsMediaDataInRealTime: isExpectsMediaDataInRealTime)
    }
}

// MARK: - AVAssetWriterInputPixelBufferAdaptor (function)
extension AVAssetWriterInputPixelBufferAdaptor {
    
    /// 建立AVAssetWriterInputPixelBufferAdaptor
    /// - Parameters:
    ///   - videoWriterInput: AVAssetWriterInput?
    ///   - vedioSize: 影片尺寸
    ///   - pixelFormat: 像素格式
    static func _build(videoWriterInput: AVAssetWriterInput?, vedioSize: Constant.VedioSize, pixelFormat: OSType = kCVPixelFormatType_32BGRA) -> AVAssetWriterInputPixelBufferAdaptor? {
        
        guard let videoWriterInput = videoWriterInput else { return nil }
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat),
                kCVPixelBufferWidthKey as String: vedioSize.width,
                kCVPixelBufferHeightKey as String: vedioSize.height
            ]
        )
        
        return adaptor
    }
}
