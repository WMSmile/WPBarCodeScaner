//public struct WPBarCodeScanner {
//    public private(set) var text = "Hello, World!"
//
//    public init() {
//    }
//}


//
//  WPBarcodeScanner.swift
//  WPBarcodeScanner
//
//  Created by wumeng on 2022/2/25.
//

import UIKit
import Foundation
import AVFoundation
import Vision


public enum WPCamera {
    case back
    case front
}

public enum WPTorchMode {
    case off
    case on
}

let kFocalPointOfInterestX:CGFloat = 0.5;
let kFocalPointOfInterestY:CGFloat = 0.5;



public class WPBarcodeScanner: NSObject {
    
    public typealias resultCallBack = (_ results:[VNBarcodeObservation]?) -> Void
    
    public static var isRightInit:Bool = false
    
    
    private lazy var privateSessionQueue:DispatchQueue = DispatchQueue.init(label: "com.wumeng.scan.barcodes")
    
    private var captureDevice:AVCaptureDevice!
    private var currentCaptureDeviceInput:AVCaptureDeviceInput!
    
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let captureVideoDataOutput = AVCaptureVideoDataOutput()
    
    private var previewView = UIView()
    
    
    private var initialAutoFocusRangeRestriction:AVCaptureDevice.AutoFocusRangeRestriction = .none
    private var preferredAutoFocusRangeRestriction:AVCaptureDevice.AutoFocusRangeRestriction = .none
    
    private var initialFocusPoint:CGPoint = CGPoint.init(x: kFocalPointOfInterestX, y: kFocalPointOfInterestY);
    
    
    
    var isCameraReady = false
    var scanTimeBetween = 1.0
    var startScan: Bool = true
    var lastScanTime: TimeInterval = 0
    
    
    private var camera:WPCamera = .back{
        didSet{
            self.updateCamera()
        }
    }
    
    var torchMode:WPTorchMode = .off
    {
        didSet{
            self.updateTorchMode(self.torchMode)
        }
    }
    
    //
    var allowTapToFocus:Bool = true
    private var gestureRecognizer:UITapGestureRecognizer? = nil
    
    
    public var didTapToFocusBlock:((_ tapPoint:CGPoint)->Void)? = nil
    public var resultBlock:resultCallBack? = nil
    public var didStartScanningBlock:(() -> Void)? = nil
    
//    var validScanObjectFrame: CGRect?
//    private lazy var scanOutsideCurrectCGRect: CGRect = {
//        return validScanObjectFrame ?? .zero
//    }()
    
    //    lazy var vision = Vision.vision()
    
    //识别类
    lazy var barcodeRequest: VNDetectBarcodesRequest = {
        let barcodeRequest = VNDetectBarcodesRequest()
        return barcodeRequest;
    }()
    private let sequenceHandler = VNSequenceRequestHandler()
    

    
    //mlkit
    //    lazy var barcodeScanner: BarcodeScanner = {
    //        let barcodeScanner = BarcodeScanner.barcodeScanner()
    //        // Or, to change the default settings:
    //        // let barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
    //        return barcodeScanner
    //    }()
    public override init() {
        super.init()
        assert(WPBarcodeScanner.isRightInit,"Please use ‘public convenience init(_ presentView:UIView)’ init")
    }
    
    
    public convenience init(_ presentView:UIView){
        WPBarcodeScanner.isRightInit = true
        self.init();
        self.previewView = presentView
        self.addObservers()
        
        //        self.updateCamera()
        //        self.setQRCodeScanner()
        //        self.configureTapToFocus();
    }
    
    
    
//
//    func setQRCodeScanner() {
//
//        if captureSession.canSetSessionPreset(AVCaptureSession.Preset.high) {
//            captureSession.sessionPreset = .high
//        }
//
//        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        videoPreviewLayer.videoGravity = .resizeAspectFill
//        videoPreviewLayer.connection?.videoOrientation = .portrait
//        /// Limit the camera output to videoPreviewLayer bounds
//        videoPreviewLayer.videoGravity = .resizeAspectFill
//        videoPreviewLayer.frame = previewView.layer.bounds
//        previewView.layer.addSublayer(videoPreviewLayer!)
//        self.previewView.layer.insertSublayer(self.videoPreviewLayer, at: 0);
//
//
//
//
//        /// input
//        //        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
//        //        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
//        //        captureSession.addInput(input)
//
//        guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
//                //                ,let firstAudioDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInMicrophone, for: AVMediaType.audio, position: AVCaptureDevice.Position.unspecified)
//                ,let videoDeviceInput = try? AVCaptureDeviceInput.init(device: videoDevice)
//                //                ,let audio = try? AVCaptureDeviceInput.init(device: firstAudioDevice)
//        else {
//            print("初始化相机失败!!!")
//            return
//        }
//
//        self.captureDevice = videoDevice
//        self.currentCaptureDeviceInput = videoDeviceInput
//        //        let audioInput = audio
//        //添加输入源
//        if captureSession.canAddInput(self.currentCaptureDeviceInput) {
//            captureSession.addInput(self.currentCaptureDeviceInput)
//        }
//        //        if captureSession.canAddInput(audioInput) {
//        //            captureSession.addInput(audioInput)
//        //        }
//
//
//
//
//        /// Video file pixel, providing a null value will be based on the device default
//        //        captureVideoDataOutput.videoSettings = [:]
//        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
//        if captureSession.canAddOutput(captureVideoDataOutput) {
//            captureSession.addOutput(captureVideoDataOutput)
//        }
//
//
//        captureVideoDataOutput.setSampleBufferDelegate(self, queue: .main)
//
//        isCameraReady = true
//
//
//    }
//
//
//    func startCamera(_ resultBlock:(() -> Void)?) {
//        guard isCameraReady else { return }
//        print("run status == \(captureSession.isRunning)")
//        self.resultBlock = resultBlock
//        if !captureSession.isRunning{
//            self.privateSessionQueue.async {
//                self.captureSession.startRunning()
//            }
//        }
//    }
//
//
//    func stopCamera() {
//        self.resultBlock = nil
//
//        if self.torchMode == .on {
//            self.torchMode = .off
//        }
//
//        if captureSession.isRunning {
//            self.privateSessionQueue.async {
//                //                self.torchMode = false
//                self.captureSession.stopRunning()
//            }
//        }
//    }
    
    
    

    
    public func startScanning(_ camera:WPCamera = WPCamera.back, _ resultBlock:resultCallBack? = nil) -> Void {
        
        assert(WPBarcodeScanner.cameraIsPresent(),"Attempted to start scanning on a device with no camera. Check requestCameraPermissionWithSuccess: method before calling startScanningWithResultBlock:")
        assert(WPBarcodeScanner.scanningIsProhibited(),"Scanning is prohibited on this device.Check requestCameraPermissionWithSuccess: method before calling startScanningWithResultBlock:")
        assert(resultBlock != nil,"startScanningWithResultBlock: requires a non-nil resultBlock.")
        

        self.camera = camera;
        
        // Configure the session
        self.captureDevice = self.newCaptureDevice(self.camera)
        let session = self.newCaptureSession(self.captureDevice)
        if session == nil {
            print("Session is nil")
            return
        }
        
        self.captureSession = session!;
        
        
        
        // Configure the preview layer
        self.videoPreviewLayer.cornerRadius = self.previewView.layer.cornerRadius
        self.previewView.layer.insertSublayer(self.videoPreviewLayer, at: 0)
        self.refreshVideoOrientation()
        
        // Configure 'tap to focus' functionality
        self.configureTapToFocus()
        
        self.resultBlock = resultBlock;
        
        self.privateSessionQueue.async{
            
            // Configure the rect of interest
            //            self.captureOutput.rectOfInterest = [self rectOfInterestFromScanRect:self.scanRect];
            
            // Start the session after all configurations:
            // Must be dispatched as it is blocking
            self.captureSession.startRunning();
            
            
            if (self.didStartScanningBlock != nil) {
                // Call that block now that we've started scanning:
                // Dispatch back to main
                DispatchQueue.main.async {
                    self.didStartScanningBlock!();
                }
            }
            
        }
        
        //        return true;
    }
    
    
    public func stopScaning() {
        
        //        guard self.captureSession != nil else {
        //            return
        //        }
        
        // Turn the torch off
        self.torchMode = WPTorchMode.off;
        
        // Remove the preview layer
        if self.videoPreviewLayer != nil {
            self.videoPreviewLayer.removeFromSuperlayer()
        }
        
        
        // Stop recognizing taps for the 'Tap to Focus' feature
        self.stopRecognizingTaps()
        
        self.resultBlock = nil;
        if self.videoPreviewLayer != nil {
            self.videoPreviewLayer.session = nil;
            self.videoPreviewLayer = nil;
        }
        
        let session = self.captureSession;
        let deviceInput = self.currentCaptureDeviceInput;
        //        self.captureSession = nil;
        
        self.privateSessionQueue.async {
            
            // When we're finished scanning, reset the settings for the camera
            // to their original states
            // Must be dispatched as it is blocking
            self.removeDeviceInputAndSession(deviceInput, session)
            
            for output in session.outputs {
                session .removeOutput(output)
            }
            // Must be dispatched as it is blocking
            session.stopRunning();
            
        }
        
    }
    
    
    
    
    deinit{
        print("game over")
        NotificationCenter.default.removeObserver(self);
    }
    
    
}
extension WPBarcodeScanner{
    
    //MARK:- Session Configuration
   private func newCaptureSession(_ captureDevice:AVCaptureDevice) -> AVCaptureSession? {
        
        guard let deviceInput = try? AVCaptureDeviceInput.init(device: captureDevice) else {
            // we rely on deviceInputWithDevice:error: to populate the error
            return nil;
        }
        let newSession = AVCaptureSession()
        
        self.updateDeviceInputAndSession(deviceInput, newSession)
        
        // Set an optimized preset for barcode scanning
        if newSession.canSetSessionPreset(AVCaptureSession.Preset.high) {
            newSession.sessionPreset = .high
        }
        
        // 识别类的初始化
        
        
        newSession.beginConfiguration()
        
        /// Video file pixel, providing a null value will be based on the device default
        //        captureVideoDataOutput.videoSettings = [:]
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        if newSession.canAddOutput(captureVideoDataOutput) {
            newSession.addOutput(captureVideoDataOutput)
        }
        
        
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: .main)
        
        //        self.privateSessionQueue.async {
        //            self.captureVideoDataOutput.metadataOutputRectConverted(fromOutputRect: <#T##CGRect#>)
        //        }
        
        
        
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: newSession)
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        self.videoPreviewLayer.frame = self.previewView.bounds;
        self.previewView.layer.addSublayer(videoPreviewLayer!)
        
        newSession.commitConfiguration()
        
        return newSession;
        
    }
    
    
    
    private func newCaptureDevice(_ camera:WPCamera) -> AVCaptureDevice? {
        
        var newCaptureDevice:AVCaptureDevice? = nil;
        
        // init devcie
        let position = WPBarcodeScanner.devicePosition(camera)
        newCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: position)
        
        // If the front camera is not available, use the back camera
        if newCaptureDevice == nil {
            newCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
        }
        
        do {
            try newCaptureDevice?.lockForConfiguration()
        } catch let error as NSError {
            print("lockForConfiguration error >>> \(error)")
        }
        
        if newCaptureDevice?.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) ?? false{
            newCaptureDevice?.focusMode = AVCaptureDevice.FocusMode.autoFocus;
        }
        newCaptureDevice?.unlockForConfiguration();
        
        return newCaptureDevice;
    }
    
    
   static private func devicePosition(_ camera:WPCamera) -> AVCaptureDevice.Position{
        switch camera {
        case .back:
            return AVCaptureDevice.Position.back
        case .front:
            return AVCaptureDevice.Position.front
        }
    }
    
    private func updateCamera(){
        if let captureDevice = self.newCaptureDevice(self.camera) {
            do {
                let input = try AVCaptureDeviceInput.init(device: captureDevice)
                self.updateDeviceInputAndSession(input, self.captureSession)
            } catch let error as NSError {
                print("error == \(error)")
            }
        }else{
            assert(false,"captureDevice init error!!")
        }
        
    }
    
    
    
    
    
}




extension WPBarcodeScanner{
    
    /// 是否在扫描中
    public func isScanning() -> Bool {
        return self.captureSession.isRunning;
    }
    
    private func updateDeviceInputAndSession(_ deviceInput:AVCaptureDeviceInput?,_ session:AVCaptureSession){
        guard deviceInput != nil else {
            // Nil device inputs cannot be added to instances of AVCaptureSession
            return
        }
        
        
        self.removeDeviceInputAndSession(self.currentCaptureDeviceInput, session)
        
        self.currentCaptureDeviceInput = deviceInput
        self.updateFocusPreferences(deviceInput?.device, false)
        
        if session.canAddInput(deviceInput!) {
            session.addInput(deviceInput!)
        }
        
    }
    
    private func removeDeviceInputAndSession(_ deviceInput:AVCaptureDeviceInput?,_ session:AVCaptureSession){
        guard deviceInput != nil else {
            // No need to remove the device input if it was never set
            return
        }
        // Restore focus settings to the previously saved state
        self.updateFocusPreferences(deviceInput?.device, true)
        
        session.removeInput(deviceInput!)
        self.currentCaptureDeviceInput = nil;
    }
    
    private func updateFocusPreferences(_ inputDevice:AVCaptureDevice?,_ reset:Bool){
        guard inputDevice != nil else {
            return
        }
        
        do {
            try inputDevice?.lockForConfiguration()
        } catch let error as NSError {
            print("updateFocusPreferences >>>> \(error)")
        }
        
        
        // Prioritize the focus on objects near to the device
        if (inputDevice?.isAutoFocusRangeRestrictionSupported ?? false) {
            if (!reset) {
                self.initialAutoFocusRangeRestriction = inputDevice!.autoFocusRangeRestriction;
                inputDevice?.autoFocusRangeRestriction = self.preferredAutoFocusRangeRestriction;
            } else {
                inputDevice?.autoFocusRangeRestriction = self.initialAutoFocusRangeRestriction;
            }
        }
        
        // Focus on the center of the image
        
        if (inputDevice?.isFocusPointOfInterestSupported ?? false) {
            if (!reset) {
                self.initialFocusPoint = inputDevice!.focusPointOfInterest;
                inputDevice?.focusPointOfInterest = CGPoint.init(x: kFocalPointOfInterestX, y: kFocalPointOfInterestY)
            } else {
                inputDevice?.focusPointOfInterest = self.initialFocusPoint;
            }
        }
        
        inputDevice?.unlockForConfiguration()
        
        // this method will acquire its own lock
        self.updateTorchMode(self.torchMode)
        
    }
    
    //MARK:- Capture
    public func freezeCapture() {
        // we must access the layer on the main thread, but manipulating
        // the capture connection is blocking and should be dispatched
        
        let connection = self.videoPreviewLayer.connection
        
        self.privateSessionQueue.async {
            connection?.isEnabled = false
            self.captureSession.stopRunning();
        }
    }
    
    public func unfreezeCapture(){
        //        if self.captureSession == nil {
        //            return;
        //        }
        let connection = self.videoPreviewLayer.connection
        
        self.privateSessionQueue.async {
            self.updateDeviceInputAndSession(self.currentCaptureDeviceInput, self.captureSession)
            
            self.captureSession.startRunning();
            connection?.isEnabled = true
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    //MARK:- Tap to Focus
    private func configureTapToFocus() -> Void {
        if self.allowTapToFocus {
            let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(focusTapped(tapGesture:)))
            self.previewView.addGestureRecognizer(tapGesture)
            self.gestureRecognizer = tapGesture;
            
        }
    }
    
    @objc private func focusTapped(tapGesture: UITapGestureRecognizer) -> Void {
        if let tapPoint = self.gestureRecognizer?.location(in: self.gestureRecognizer?.view){
            let devicePoint = self.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
            let device = self.captureDevice
            do {
                try device?.lockForConfiguration()
                
                if device?.isAutoFocusRangeRestrictionSupported ?? false && ((device?.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus)) != nil) {
                    
                    device?.focusPointOfInterest = devicePoint
                    device?.focusMode = AVCaptureDevice.FocusMode.autoFocus
                    
                }
                device?.unlockForConfiguration()
            } catch let error as NSError {
                print("Failed to acquire lock for focus change: \(error)" )
            }
            
            if (self.didTapToFocusBlock != nil) {
                self.didTapToFocusBlock!(tapPoint);
            }
        }
        
    }
    
    private func stopRecognizingTaps() -> Void {
        if self.gestureRecognizer != nil {
            self.previewView.removeGestureRecognizer(self.gestureRecognizer!);
        }
    }
    
    
    
    //MARK:- Rotation
    @objc private func handleApplicationDidChangeStatusBarNotification(_ notification:Notification) -> Void {
        
        self.refreshVideoOrientation();
    }
    private func refreshVideoOrientation() -> Void {
        let orientation = UIApplication.shared.statusBarOrientation;
        self.videoPreviewLayer.frame = self.previewView.bounds
        if self.videoPreviewLayer.connection?.isVideoOrientationSupported ?? false {
            self.videoPreviewLayer.connection?.videoOrientation = self.captureOrientationForInterfaceOrientation(orientation)
        }
    }
    private func captureOrientationForInterfaceOrientation(_ interfaceOrientation:UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    //MARK:- Torch Control
    
    @objc private func applicationWillEnterForegroundNotification(_ notification:Notification) -> Void{
        self.updateTorchMode(self.torchMode)
    }
    
    private func updateTorchMode(_ preferredTorchMode:WPTorchMode) -> Void {
        
        let backCamera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera , for: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let avTorchMode = self.avTorchModeForMTBTorchMode(preferredTorchMode)
        
        if !(backCamera?.isTorchAvailable ?? false && backCamera?.isTorchModeSupported(avTorchMode) ?? false) {
            return
        }
        
        do {
            try backCamera?.lockForConfiguration()
            backCamera?.torchMode = avTorchMode
            backCamera?.unlockForConfiguration()
        } catch let error as NSError{
            print("lockForConfiguration >>>>>> \(error)")
        }
        
    }
    
    
    private func avTorchModeForMTBTorchMode(_ torchMode:WPTorchMode) -> AVCaptureDevice.TorchMode {
        switch torchMode {
        case .off:
            return AVCaptureDevice.TorchMode.off
        case .on:
            return AVCaptureDevice.TorchMode.on
        }
    }
    
    
   private func hasTorch() -> Bool {
        return  self.currentCaptureDeviceInput.device.hasTorch;
    }
    
    
    //    func rectOfInterestFromScanRect(_ scanRect:CGRect) -> CGRect{
    //        var rect = CGRect.zero
    //        if scanRect.isEmpty {
    //            rect = self.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
    //        }else{
    //            rect = CGRect.init(x: 0, y: 0, width: 1, height: 1)
    //        }
    //
    //        return rect;
    //    }
    
    private func addObservers() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidChangeStatusBarNotification(_:)), name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForegroundNotification(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    
    
    static public func cameraIsPresent() -> Bool{
        return AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front) != nil
    }
    static public func oppositeCamera(_ camera:WPCamera) -> WPCamera{
        switch camera {
        case .back:
            return .front
        case .front:
            return .back
        }
    }
    
    static public func scanningIsProhibited() -> Bool{
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .denied:
            return true
        case .restricted:
            return true
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    
    
    
    
    
    
    
    static public func requestCameraPermission(_ successBlock:@escaping((_ success:Bool)->Void)) -> Void{
        if !self.cameraIsPresent() {
            successBlock(false)
            return;
        }
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case AVAuthorizationStatus.authorized:
            successBlock(true)
            break;
        case AVAuthorizationStatus.denied:
            successBlock(false)
            break;
        case AVAuthorizationStatus.restricted:
            successBlock(false)
            break;
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                DispatchQueue.main.async {
                    successBlock(granted)
                }
            }
            break;
        default:
            break;
        }
        
    }
    
    
}


extension WPBarcodeScanner: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        /// Lens Scanning Control Valve
        //        guard startScan else { return }
        //        startScan = false
        
        //        /// Firebase ML kit meata
        //        let metadata = VisionImageMetadata()
        //        metadata.orientation = imageOrientation()
        //        let image = VisionImage(buffer: sampleBuffer)
        //        image.metadata = metadata
        //
        //
        //
        //        /// 取出數據分析結果
        //        barcodeScanner.detect(in: image) { [weak self]
        //            barcodes, error in
        //            guard let self = self else { return }
        //            /// 如果分析有錯誤，或是 barcodes 不存在，開啟掃瞄器
        //            guard error == nil, let barcodes = barcodes, !barcodes.isEmpty else {
        //                self.startScan = true
        //                return
        //            }
        //
        //            /// 篩選 qrcodes
        //            self.selectBarcodes(barcodes: barcodes, sampleBuffer: sampleBuffer)
        //
        //        }
        
        
        
        //        let visionImage = VisionImage(buffer: sampleBuffer)
        //        visionImage.orientation = imageOrientation(
        //          deviceOrientation: UIDevice.current.orientation,
        //          cameraPosition: .back)
        //
        ////        self.WM_FUNC_print(sampleBuffer)
        //
        //
        //        self.barcodeScanner.process(visionImage) { features, error in
        //          guard error == nil, let features = features, !features.isEmpty else {
        //            // Error handling
        //            return
        //          }
        //            print("results == \(features)")
        //          // Recognized barcodes
        //            for barcode in features {
        //                print("12332barcode = " + (barcode.rawValue ?? "") + "  corners == \(String(describing: barcode.cornerPoints))")
        ////                  let corners = barcode.cornerPoints
        ////                  let displayValue = barcode.displayValue
        ////                  let rawValue = barcode.rawValue
        ////                  let valueType = barcode.valueType
        ////                  switch valueType {
        ////                  case .wiFi:
        ////                    let ssid = barcode.wifi?.ssid
        ////                    let password = barcode.wifi?.password
        ////                    let encryptionType = barcode.wifi?.type
        ////                  case .URL:
        ////                    let title = barcode.url!.title
        ////                    let url = barcode.url!.url
        ////                  default:
        ////                    // See API reference for all supported value types
        ////                    print(barcode.url)
        ////                    print("11223344");
        ////                  }
        //
        //            }
        //
        //            /// filter qrcodes
        ////            self.selectBarcodes(barcodes: features, sampleBuffer: sampleBuffer)
        //
        //        }
        guard self.resultBlock != nil else {
            return
        }
        
        //识别
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        self.extractBarCode(fromFrame: frame)
        
    }
    
    
    private func extractBarCode(fromFrame frame: CVImageBuffer) -> Void {
        
        self.privateSessionQueue.async {
            autoreleasepool {
                let barcodeRequest = VNDetectBarcodesRequest()
                barcodeRequest.symbologies = self.defaultSymbologies()
                
                do {
                    try self.sequenceHandler.perform([barcodeRequest], on: frame)
                } catch let error as NSError {
                    print("error == \(error)")
                }
                print("results == \(String(describing: barcodeRequest.results))")
                if(self.resultBlock != nil){
                    self.resultBlock!(barcodeRequest.results)
                }
            }
        }
        
    }
    
    // all symbologies
    private func defaultSymbologies() -> [VNBarcodeSymbology]{
        return [.Aztec,
                .Code39,
                .Code39Checksum,
                .Code39FullASCII,
                .Code39FullASCIIChecksum,
                .Code93,
                .Code93i,
                .Code128,
                .DataMatrix,
                .EAN8,
                .EAN13,
                .I2of5,
                .I2of5Checksum,
                .ITF14,
                .PDF417,
                .QR,
                .UPCE]
        
    }
    
    
    //    //
    //    func WM_FUNC_print(_ sampleBuffer: CMSampleBuffer) -> Void {
    //        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
    //            startScan = true
    //            return
    //        }
    //        /// 相機讀取到的畫面完整尺寸
    //        let imgSize = sampleBufferSize(imageBuffer)
    //        print("vision == \(imgSize))")
    //    }
    
    
    
    func imageOrientation(deviceOrientation: UIDeviceOrientation,cameraPosition: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            return cameraPosition == .front ? .leftMirrored : .right
        }
    }
    
}

//
//extension WPBarcodeScanner{
//
//    /// 是否為要的發票qrcode
//    /// - Parameter qrcode: qrcode 字串
//    private func isValidInvoiceQRCode(qrcode: String) -> Bool {
//
//        /// 發票規格為 qrcode 77碼以上
//        let limitInt = 77
//
//        //  發票規格如不到77碼就return
//        guard qrcode.count >= limitInt else {
//            return false
//        }
//
//        //  發票右邊 qrcode 為 ** 開頭
//        let rightInvoiceForm = "**"
//
//        //  前兩個字如果為**就 return
//        if qrcode[qrcode.startIndex..<qrcode.index(qrcode.startIndex, offsetBy: 2)] == rightInvoiceForm {
//            return false
//        }
//
//        return true
//    }
//
//
//    func timeExpire() -> Bool {
//
//        if Date().timeIntervalSince1970 - lastScanTime < scanTimeBetween {
//            return false
//        }
//
//        lastScanTime = Date().timeIntervalSince1970
//
//        return true
//    }
//    /// 篩選掃進的 qrcode
//    /// - Parameters:
//    ///   - barcodes: qrcode 元數就
//    ///   - sampleBuffer: 此次畫面媜。用來解析該媜的畫面size
//    private func selectBarcodes(barcodes: [Barcode], sampleBuffer: CMSampleBuffer) {
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            startScan = true
//            return
//        }
//        /// 相機讀取到的畫面完整尺寸
//        let imgSize = sampleBufferSize(imageBuffer)
//
//        /// 判斷Qrcode  是否在限制的掃描框內
//        guard checkObjectBoundsForTwoObjects(barcodes, sampleBufferSize: imgSize) else {
//            self.startScan = true
//            /// 埋點使用，判斷是否非發票
//            self.checkQRCodeIsNotInvoice(barcodes[0], sampleBufferSize: imgSize)
//            return
//        }
//
//
//        // 此區塊確定 metadataObjects 數量為2
//        for index in 0...1 {
//            guard let qrcodeString = barcodes[0].displayValue,
//                  self.isValidInvoiceQRCode(qrcode: qrcodeString)
//            else {
//                // 避免兩個物件都非qr code 物件，造成startScan無法開啟
//                if index == 1 {
//                    self.startScan = true
//                }
//                continue }
//            guard self.timeExpire() else {
//                self.startScan = true
//                return }
//
//            // do something you want
//            break
//        }
//
//    }
//
//
//    /// 檢查QRCode是否在中間方框內
//    /// 必須兩個QRCode都在限制框框內
//    func checkObjectBoundsForTwoObjects(_ barcodes: [Barcode], sampleBufferSize size: CGSize) ->Bool {
//
//        // 超過兩個物件就不是發票
//        guard barcodes.count < 3 else {
//            return false
//        }
//        guard barcodes.indices.contains(1) else { return false }
//        /// 發票左邊QRCode
//        let barcodeLeft = barcodes[0]
//        /// 發票右邊QRCode
//        let barcodesRight = barcodes[1]
//
//
//        // 計算左邊物件的 bounds
//        guard var objectRectLeft = convertedRectOfBarcodeFrame(frame: barcodeLeft.frame, inSampleBufferSize: size) else {
//            return false
//        }
//        // 計算右邊邊物件的 bounds
//        guard var objectRectRight = convertedRectOfBarcodeFrame(frame: barcodesRight.frame, inSampleBufferSize: size) else {
//            return false
//        }
//
//        /// 縮小 bounds 為原本 0.9 倍
//        objectRectLeft = objectRectLeft.insetBy(dx: objectRectLeft.width * 0.90, dy: objectRectLeft.height * 0.90)
//        /// 縮小 bounds 為原本 0.9 倍
//        objectRectRight = objectRectRight.insetBy(dx: objectRectRight.width * 0.90, dy: objectRectRight.height * 0.90)
//
//
//        // 檢查是否包含在掃描框內
//        let leftCheckBool = scanOutsideCurrectCGRect.contains(objectRectLeft)
//
//        let rightCheckBool = scanOutsideCurrectCGRect.contains(objectRectRight)
//
//        return leftCheckBool && rightCheckBool
//    }
//
//    /// 將 sampleBufferSize 轉換為 UIImage Size
//    private func sampleBufferSize(_ imageBuffer: CVImageBuffer)-> CGSize {
//        let imgWidth = CVPixelBufferGetWidth(imageBuffer)
//        let imgHeight = CVPixelBufferGetHeight(imageBuffer)
//        return CGSize(width: imgWidth, height: imgHeight)
//    }
//
//    /// 將qrcode 元數據的frame 轉乘 iphone UIKit 在 videoPreviewLayer 座標
//    private func convertedRectOfBarcodeFrame(frame: CGRect, inSampleBufferSize size: CGSize)-> CGRect? {
//        /// 將 掃到的QRCode.frame 轉為 imgSize 的比例
//        let normalizedRect = CGRect(x: frame.origin.x / size.width, y: frame.origin.y / size.height, width: frame.size.width / size.width, height: frame.size.height / size.height)
//        /// 將比例轉成 UIkit 座標
//        return videoPreviewLayer?.layerRectConverted(fromMetadataOutputRect: normalizedRect)
//    }
//
//
//    /// 判斷是否為發票
//    private func checkQRCodeIsNotInvoice(_ barcode: Barcode, sampleBufferSize size: CGSize) {
//        guard let qrcodeQtring = barcode.displayValue else { return }
//
//        guard let objectRect = convertedRectOfBarcodeFrame(frame: barcode.frame, inSampleBufferSize: size), scanOutsideCurrectCGRect.contains(objectRect) else { return }
//
//        if !isValidInvoiceQRCode(qrcode: qrcodeQtring) {
//            NSLog("It is not invoice")
//        }
//    }
//}
