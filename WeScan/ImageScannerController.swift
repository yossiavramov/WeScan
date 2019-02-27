//
//  ImageScannerController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

/// A set of methods that your delegate object must implement to interact with the image scanner interface.
public protocol ImageScannerControllerDelegate: NSObjectProtocol {
    
    /// Tells the delegate that the user scanned a document.
    ///
    /// - Parameters:
    ///   - scanner: The scanner controller object managing the scanning interface.
    ///   - results: The results of the user scanning with the camera.
    /// - Discussion: Your delegate's implementation of this method should dismiss the image scanner controller.
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults)
    
    /// Tells the delegate that the user cancelled the scan operation.
    ///
    /// - Parameters:
    ///   - scanner: The scanner controller object managing the scanning interface.
    /// - Discussion: Your delegate's implementation of this method should dismiss the image scanner controller.
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController)
    
    /// Tells the delegate that an error occured during the user's scanning experience.
    ///
    /// - Parameters:
    ///   - scanner: The scanner controller object managing the scanning interface.
    ///   - error: The error that occured.
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error)
}

/// A view controller that manages the full flow for scanning documents.
/// The `ImageScannerController` class is meant to be presented. It consists of a series of 3 different screens which guide the user:
/// 1. Uses the camera to capture an image with a rectangle that has been detected.
/// 2. Edit the detected rectangle.
/// 3. Review the cropped down version of the rectangle.
public final class ImageScannerController: UINavigationController, ScannerViewControllerDelegate, EditScanViewControllerDelegate, ReviewViewControllerDelegate {
    
    /// The object that acts as the delegate of the `ImageScannerController`.
    public weak var imageScannerDelegate: ImageScannerControllerDelegate?
    
    public var allowsEditing: Bool = true
    
    // MARK: - Life Cycle
    public required init(image: UIImage? = nil, delegate: ImageScannerControllerDelegate? = nil) {
        let scannerVC = ScannerViewController()
        super.init(rootViewController: scannerVC)
        scannerVC.delegate = self
        
        setNavigationBarHidden(true, animated: false)
        self.imageScannerDelegate = delegate
        
        // If an image was passed in by the host app (e.g. picked from the photo library), use it instead of the document scanner.
        if let image = image?.rotateToImageOrientationUp() {
            
            var detectedQuad: Quadrilateral?
            
            guard let ciImage = CIImage(image: image) else {
                let editViewController = EditScanViewController(image: image, quad: nil, rotateImage: false)
                editViewController.delegate = self
                setViewControllers([editViewController], animated: false)
                return
            }
            
            if #available(iOS 11.0, *) {
                let vc = UIViewController(nibName: nil, bundle: nil)
                vc.view.backgroundColor = UIColor.black
                let activity = UIActivityIndicatorView(style: .whiteLarge)
                activity.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
                vc.view.addSubview(activity)
                activity.center = CGPoint(x: vc.view.bounds.midX, y: vc.view.bounds.midY)
                setViewControllers([vc], animated: false)
                activity.startAnimating()
                
                // Use the VisionRectangleDetector on iOS 11 to attempt to find a rectangle from the initial image.
                VisionRectangleDetector.rectangle(forImage: ciImage) { (quad) in
                    detectedQuad = quad
                    detectedQuad?.reorganize()

                    let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
                    editViewController.delegate = self
                    self.setViewControllers([editViewController], animated: true)
                }
            } else {
                // Use the CIRectangleDetector on iOS 10 to attempt to find a rectangle from the initial image.
                var detectedQuad = CIRectangleDetector.rectangle(forImage: ciImage)
                detectedQuad?.reorganize()
                
                let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
                editViewController.delegate = self
                setViewControllers([editViewController], animated: false)
            }
        }
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    //MARK: - ScannerViewControllerDelegate
    func scannerViewControllerDidSelectToCancel(_ vc: ScannerViewController) {
        guard let _ = imageScannerDelegate?.imageScannerControllerDidCancel(self) else { return }
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func scannerViewController(_ vc: ScannerViewController, didFailWithError error: Error) {
        imageScannerDelegate?.imageScannerController(self, didFailWithError: error)
    }
    
    func scannerViewController(_ vc: ScannerViewController, didCaptureImage image: UIImage, detectedRectangle: Quadrilateral?, quadrilateralViewBounds: CGSize) {
        if allowsEditing {
            let editVC = EditScanViewController(image: image, quad: detectedRectangle)
            editVC.delegate = self
            pushViewController(editVC, animated: false)
        } else {
            let imageResults = ImageScannerResults(picture: image, detectedRectangle: detectedRectangle, quadrilateralViewBounds: quadrilateralViewBounds)
            imageScannerDelegate?.imageScannerController(self, didFinishScanningWithResults: imageResults)
        }
    }
    
    //MARK: - EditScanViewControllerDelegate
    func editScanViewController(_ vc: EditScanViewController, didFailWithError error: Error) {
        imageScannerDelegate?.imageScannerController(self, didFailWithError: error)
    }
    
    func editScanViewController(_ vc: EditScanViewController, finishEditingWith results: ImageScannerResults) {
        let reviewViewController = ReviewViewController(results: results)
        reviewViewController.delegate = self
        self.pushViewController(reviewViewController, animated: true)
    }
    
    //MARK: - ReviewViewControllerDelegate
    func reviewViewController(_ vc: ReviewViewController, didEndReviewWith results: ImageScannerResults) {
        imageScannerDelegate?.imageScannerController(self, didFinishScanningWithResults: results)
    }
}

/// Data structure containing information about a scan.
public struct ImageScannerResults {
    
    /// The original image taken by the user, prior to the cropping applied by WeScan.
    public var originalImage: UIImage
    
    /// The deskewed and cropped orignal image using the detected rectangle, without any filters.
    public var scannedImage: UIImage?
    
    /// The enhanced image, passed through an Adaptive Thresholding function. This image will always be grayscale and may not always be available.
    public var enhancedImage: UIImage?
    
    /// Whether the user wants to use the enhanced image or not. The `enhancedImage`, for use with OCR or similar uses, may still be available even if it has not been selected by the user.
    public var doesUserPreferEnhancedImage: Bool
    
    /// The detected rectangle which was used to generate the `scannedImage`.
    public var detectedRectangle: Quadrilateral?
    
    init(originalImage: UIImage, scannedImage: UIImage?, enhancedImage: UIImage?, doesUserPreferEnhancedImage: Bool, detectedRectangle: Quadrilateral?) {
        self.originalImage = originalImage
        self.scannedImage = scannedImage
        self.enhancedImage = enhancedImage
        self.doesUserPreferEnhancedImage = doesUserPreferEnhancedImage
        self.detectedRectangle = detectedRectangle
    }
    
    init(picture: UIImage, detectedRectangle: Quadrilateral?, quadrilateralViewBounds: CGSize) {
        let finalImage: UIImage?
        let enhancedImage: UIImage?
        let scaledQuad = detectedRectangle?.scale(quadrilateralViewBounds, picture.size)
        if let scaledQuad = scaledQuad,
            let ciImage = CIImage(image: picture) {
            
            var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: picture.size.height)
            cartesianScaledQuad.reorganize()
            
            let filteredImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
                "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
                "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
                ])
            
            enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
            
            var uiImage: UIImage!
            
            // Let's try to generate the CGImage from the CIImage before creating a UIImage.
            if let cgImage = CIContext(options: nil).createCGImage(filteredImage, from: filteredImage.extent) {
                uiImage = UIImage(cgImage: cgImage)
            } else {
                uiImage = UIImage(ciImage: filteredImage, scale: 1.0, orientation: .up)
            }
            
            finalImage = uiImage.withFixedOrientation()
        } else {
            finalImage = nil
            enhancedImage = nil
        }
        
        self.originalImage = picture
        self.scannedImage = finalImage
        self.enhancedImage = enhancedImage
        self.doesUserPreferEnhancedImage = false
        self.detectedRectangle = scaledQuad
    }
}
