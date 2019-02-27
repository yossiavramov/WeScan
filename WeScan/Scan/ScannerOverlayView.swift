//
//  ScannerOverlayView.swift
//  WeScan
//
//  Created by Yossi Avramov on 27/02/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

public protocol ScannerController : NSObjectProtocol {
    
    var isAutoScanEnabled: Bool { get set }
    
    var isFlashEnabled: Bool { get }
    var flashMode: ScannerOverlayView.FlashMode? { get }
    
    @discardableResult
    func toggleFlash() -> Bool
    
    @discardableResult
    func setFlashMode(_ flashMode: ScannerOverlayView.FlashMode) -> Bool
    
    func setCustomScanRectangleView(_ view: UIView)
    func useDefaultScanRectangleView(withColor backgroundColor: UIColor?, cornerRadius: CGFloat, borderColor: UIColor?, borderWidth: CGFloat)
    
    func takePicture()
    
    func dismissImagePicker(cancelledByUser: Bool)
    
    var videoFrame: CGRect { get set }
}

public class ScannerOverlayView : UIView {
    
    public typealias FlashMode = AVCaptureDevice.TorchMode
    
    public internal(set) weak var scannerController: ScannerController?
    
    //MARK: - Overrides
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView === self ? nil : hitView
    }
    
    
    
    //MARK: - Prepare for presenting
    @available(iOS, introduced: 10.0, deprecated: 11.0, message: "Use prepareForPresenting() instead of prepareForPresenting(topLayoutGuide:bottomLayoutGuide)")
    public func prepareForPresenting(topLayoutGuide: UILayoutSupport, bottomLayoutGuide: UILayoutSupport) { }
    
    @available(iOS 11.0, *)
    public func prepareForPresenting() { }
    
    //MARK: - Focusing on subject area
    public func startFocusingOnSubjectArea(in point: CGPoint) { }
    public func stopFocusingOnSubjectArea() { }
    
    //MARK: - Capturing picture
    public var canHandleTakeImageAnimation: Bool { return false }
    
    public func willStartCapturingPicture() { }
    
    public func didCapturePicture(picture: UIImage, withQuad quad: Quadrilateral?) { }
    
    public func didFailedToCapturePicture(with error: Error) { }
}
