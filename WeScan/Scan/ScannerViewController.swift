//
//  ScannerViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

protocol ScannerViewControllerDelegate : NSObjectProtocol {
    func scannerViewControllerDidSelectToCancel(_ vc: ScannerViewController)
    func scannerViewController(_ vc: ScannerViewController, didFailWithError error: Error)
    func scannerViewController(_ vc: ScannerViewController, didCaptureImage image: UIImage, detectedRectangle: Quadrilateral?, quadrilateralViewBounds: CGSize)
}

/// The `ScannerViewController` offers an interface to give feedback to the user regarding quadrilaterals that are detected. It also gives the user the opportunity to capture an image with a detected rectangle.
final class ScannerViewController: UIViewController {
    
    private var captureSessionManager: CaptureSessionManager?
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// The view that draws the detected rectangles.
    private let quadView = QuadrilateralView()

    private lazy var blinkerView: UIView = {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        view.isHidden = true
        view.autoresizingMask = []
        return view
    }()
    
    weak var delegate: ScannerViewControllerDelegate?
    
    public var overlayView: ScannerOverlayView? {
        didSet {
            guard self.overlayView !== oldValue else { return }
            
            if let old = oldValue {
                old.scannerController = nil
                old.removeFromSuperview()
            }
            
            if self.overlayView == nil {
                self.overlayView = DefaultScannerOverlayView(frame: view.bounds)
            }
            
            let overlayView = self.overlayView!
            if overlayView.superview !== self {
                overlayView.frame = view.bounds
                overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                overlayView.translatesAutoresizingMaskIntoConstraints = true
                overlayView.removeFromSuperview()
                view.addSubview(overlayView)
                if #available(iOS 11.0, *) {
                    overlayView.prepareForPresenting()
                } else {
                    overlayView.prepareForPresenting(topLayoutGuide: self.topLayoutGuide, bottomLayoutGuide: self.bottomLayoutGuide)
                }
                
                view.layoutIfNeeded()
            }
            
            overlayView.scannerController = self
        }
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        title = nil
        
        setupViews()
        
        //Setup overtlay view
        let overlayView = self.overlayView ?? DefaultScannerOverlayView(frame: view.bounds)
        self.overlayView = overlayView
        
        captureSessionManager = CaptureSessionManager(videoPreviewLayer: videoPreviewLayer)
        captureSessionManager?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        CaptureSession.current.isEditing = false
        quadView.removeQuadrilateral()
        captureSessionManager?.start()
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer.frame = view.layer.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        
        setFlashMode(.off)
    }
    
    // MARK: - Setups
    private func setupViews() {
        view.layer.addSublayer(videoPreviewLayer)
        quadView.translatesAutoresizingMaskIntoConstraints = false
        quadView.editable = false
        view.addSubview(quadView)
        
        quadView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: quadView.bottomAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: quadView.trailingAnchor).isActive = true
        quadView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }
    
    // MARK: - Tap to Focus
    
    /// Called when the AVCaptureDevice detects that the subject area has changed significantly. When it's called, we reset the focus so the camera is no longer out of focus.
    @objc private func subjectAreaDidChange() {
        /// Reset the focus and exposure back to automatic
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
        
        overlayView?.stopFocusingOnSubjectArea()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard  let touch = touches.first else { return }
        let touchPoint = touch.location(in: view)
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        if let overlay = overlayView {
            let pointInOverlay = view.convert(touchPoint, to: overlay)
            overlay.startFocusingOnSubjectArea(in: pointInOverlay)
        }
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
        }
    }
}

extension ScannerViewController : ScannerController {
    var isAutoScanEnabled: Bool {
        get { return CaptureSession.current.isAutoScanEnabled }
        set { CaptureSession.current.isAutoScanEnabled = newValue }
    }
    
    var isFlashEnabled: Bool { return UIImagePickerController.isFlashAvailable(for: .rear) }
    var flashMode: ScannerOverlayView.FlashMode? { return CaptureSession.current.flashMode }
    
    @discardableResult
    func toggleFlash() -> Bool {
        return CaptureSession.current.toggleFlash() != nil
    }
    
    @discardableResult
    func setFlashMode(_ flashMode: ScannerOverlayView.FlashMode) -> Bool {
        let currentFlashMode = CaptureSession.current.flashMode
        let newFlashMode = CaptureSession.current.setFlashMode(flashMode)
        return currentFlashMode == newFlashMode
    }
    
    func setCustomScanRectangleView(_ view: UIView) {
        //TODO:
    }
    
    func useDefaultScanRectangleView(withColor backgroundColor: UIColor?, cornerRadius: CGFloat, borderColor: UIColor?, borderWidth: CGFloat) {
        //TODO:
    }
    
    func takePicture() {
        if !(overlayView?.canHandleTakeImageAnimation ?? false) {
            blinkerView.isHidden = false
            view.addSubview(blinkerView)
            let flashDuration = DispatchTime.now() + 0.05
            DispatchQueue.main.asyncAfter(deadline: flashDuration) {
                self.blinkerView.isHidden = true
                self.blinkerView.removeFromSuperview()
            }
        }
        
        captureSessionManager?.capturePhoto()
    }
    
    func dismissImagePicker(cancelledByUser: Bool) {
        if cancelledByUser {
            delegate?.scannerViewControllerDidSelectToCancel(self)
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    var videoFrame: CGRect {
        get { return videoPreviewLayer.frame }
        set { videoPreviewLayer.frame = newValue }
    }
}

extension ScannerViewController: RectangleDetectionDelegateProtocol {
    func captureSessionManagerDidStartCapturingPicture(_ captureSessionManager: CaptureSessionManager) {
        overlayView?.willStartCapturingPicture()
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didFailWithError error: Error) {
        
        overlayView?.didFailedToCapturePicture(with: error)
        
        delegate?.scannerViewController(self, didFailWithError: error)
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didCapturePicture picture: UIImage, withQuad quad: Quadrilateral?) {
        overlayView?.didCapturePicture(picture: picture, withQuad: quad)
        delegate?.scannerViewController(self, didCaptureImage: picture, detectedRectangle: quad, quadrilateralViewBounds: quadView.bounds.size)
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didDetectQuad quad: Quadrilateral?, _ imageSize: CGSize) {
        guard let quad = quad else {
            // If no quad has been detected, we remove the currently displayed on on the quadView.
            quadView.removeQuadrilateral()
            return
        }
        
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize, aspectFillInSize: quadView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)

        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)

        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds, toCenterOfRect: quadView.bounds)
        
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
    }
}
