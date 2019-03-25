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
    
    func takePicture()
    
    func dismissImagePicker(cancelledByUser: Bool)
    
    var videoFrame: CGRect { get set }
}

open class ScannerOverlayView : UIView {
    
    public typealias FlashMode = AVCaptureDevice.TorchMode
    
    open internal(set) weak var scannerController: ScannerController?
    
    //MARK: - Overrides
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView === self ? nil : hitView
    }
    
    //MARK: - Prepare for presenting
    @available(iOS, introduced: 10.0, deprecated: 11.0, message: "Use prepareForPresenting() instead of prepareForPresenting(topLayoutGuide:bottomLayoutGuide)")
    open func prepareForPresenting(topLayoutGuide: UILayoutSupport, bottomLayoutGuide: UILayoutSupport, navigationItem: UINavigationItem) { }
    
    @available(iOS 11.0, *)
    open func prepareForPresenting(navigationItem: UINavigationItem) { }
    
    //MARK: - Focusing on subject area
    open func startFocusingOnSubjectArea(in point: CGPoint) { }
    open func stopFocusingOnSubjectArea() { }
    
    //MARK: - Capturing picture
    open var canHandleTakeImageAnimation: Bool { return false }
    
    open func willStartCapturingPicture() { }
    
    open func didCapturePicture(picture: UIImage, withQuad quad: Quadrilateral?) { }
    
    open func didFailedToCapturePicture(with error: Error) { }
}
