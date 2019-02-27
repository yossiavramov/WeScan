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
public final class ImageScannerController: UINavigationController {
    
    /// The object that acts as the delegate of the `ImageScannerController`.
    public weak var imageScannerDelegate: ImageScannerControllerDelegate?
    
    public var allowsEditing: Bool = true
    
    // MARK: - Life Cycle
    public required init(image: UIImage? = nil, delegate: ImageScannerControllerDelegate? = nil) {
        super.init(rootViewController: ScannerViewController())
        
        setNavigationBarHidden(true, animated: false)
        self.imageScannerDelegate = delegate
        
        // If an image was passed in by the host app (e.g. picked from the photo library), use it instead of the document scanner.
        if let image = image?.rotateToImageOrientationUp() {
            
            var detectedQuad: Quadrilateral?
            
            // Whether or not we detect a quad, present the edit view controller after attempting to detect a quad.
            // *** Vision *requires* a completion block to detect rectangles, but it's instant.
            // *** When using Vision, we'll present the normal edit view controller first, then present the updated edit view controller later.
            defer {
                let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
                setViewControllers([editViewController], animated: false)
            }
            
            guard let ciImage = CIImage(image: image) else { return }
            
            if #available(iOS 11.0, *) {
                // Use the VisionRectangleDetector on iOS 11 to attempt to find a rectangle from the initial image.
                VisionRectangleDetector.rectangle(forImage: ciImage) { (quad) in
                    detectedQuad = quad
                    detectedQuad?.reorganize()

                    let editViewController = EditScanViewController(image: image, quad: detectedQuad, rotateImage: false)
                    self.setViewControllers([editViewController], animated: true)
                }
            } else {
                // Use the CIRectangleDetector on iOS 10 to attempt to find a rectangle from the initial image.
                detectedQuad = CIRectangleDetector.rectangle(forImage: ciImage)
                detectedQuad?.reorganize()
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
    
}
