//
//  DefaultScannerOverlayView.swift
//  WeScan
//
//  Created by Yossi Avramov on 27/02/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

import UIKit

internal final class DefaultScannerOverlayView : ScannerOverlayView {
    private var topBar: UIView!
    
    lazy private var shutterButton: ShutterButton = {
        let button = ShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy private var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("wescan.scanning.cancel", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Cancel", comment: "The cancel button"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelImageScannerController), for: .touchUpInside)
        return button
    }()
    
    lazy private var autoScanButton: UIButton = {
        let title = NSLocalizedString("wescan.scanning.auto", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Auto", comment: "The auto button state")
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(toggleAutoScan), for: .touchUpInside)
        return button
    }()
    
    lazy private var flashButton: UIButton = {
        let image = UIImage(named: "flash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        return button
    }()
    
    lazy private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    /// The view that shows the focus rectangle (when the user taps to focus, similar to the Camera app)
    private var focusRectangle: FocusRectangleView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willStartCapturingPicture() {
        super.willStartCapturingPicture()
        activityIndicator.startAnimating()
        shutterButton.isUserInteractionEnabled = false
    }
    
    override func didCapturePicture(picture: UIImage, withQuad quad: Quadrilateral?) {
        super.didCapturePicture(picture: picture, withQuad: quad)
        
        activityIndicator.stopAnimating()
        shutterButton.isUserInteractionEnabled = true
    }
    
    override func didFailedToCapturePicture(with error: Error) {
        super.didFailedToCapturePicture(with: error)
        activityIndicator.stopAnimating()
        shutterButton.isUserInteractionEnabled = true
    }
    
    //MARK: - Actions
    @objc private func captureImage(_ sender: UIButton) {
        shutterButton.isUserInteractionEnabled = false
        scannerController?.takePicture()
    }
    
    @objc private func cancelImageScannerController() {
        scannerController?.dismissImagePicker(cancelledByUser: true)
    }
    
    @objc private func toggleAutoScan() {
        guard let scannerController = scannerController else { return }
        
        scannerController.isAutoScanEnabled = !scannerController.isAutoScanEnabled
        let title: String
        if scannerController.isAutoScanEnabled {
            title = NSLocalizedString("wescan.scanning.auto", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Auto", comment: "The auto button state")
        } else {
            title = NSLocalizedString("wescan.scanning.manual", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Manual", comment: "The manual button state")
        }
        
        autoScanButton.setTitle(title, for: .normal)
    }
    
    @objc private func toggleFlash() {
        guard let scannerController = scannerController else { return }
        
        scannerController.toggleFlash()
        guard let flashMode = scannerController.flashMode else {
            flashButton.setImage(UIImage(named: "flashUnavailable", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
            flashButton.tintColor = UIColor.lightGray
            return
        }
        
        flashButton.setImage(UIImage(named: "flash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        switch flashMode {
        case .auto:
            flashButton.tintColor = UIColor.white
        case .on:
            flashButton.tintColor = UIColor.yellow
        case .off:
            flashButton.tintColor = UIColor.gray
        }
    }
    
    override func startFocusingOnSubjectArea(in point: CGPoint) {
        removeFocusRectangleIfNeeded(animated: false)
        
        focusRectangle = FocusRectangleView(touchPoint: point)
        insertSubview(focusRectangle, at: 0)
    }
    
    override func stopFocusingOnSubjectArea() {
        removeFocusRectangleIfNeeded(animated: true)
    }
    
    @available(iOS, introduced: 10.0, deprecated: 11.0)
    override func prepareForPresenting(topLayoutGuide: UILayoutSupport, bottomLayoutGuide: UILayoutSupport, navigationItem: UINavigationItem) {
        super.prepareForPresenting(topLayoutGuide: topLayoutGuide, bottomLayoutGuide: bottomLayoutGuide, navigationItem: navigationItem)
        
        topBar.bottomAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 44).isActive = true
    }
    
    //MARK: - Private
    private func setupUI() {
        guard shutterButton.superview == nil else { return }
        
        backgroundColor = UIColor.clear
        
        let topBar = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        topBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 44)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        
        let topBarActionsLayoutView = UIView(frame: CGRect(x: 0, y: topBar.bounds.height - 44, width: topBar.bounds.width, height: 44))
        topBarActionsLayoutView.isHidden = true
        topBarActionsLayoutView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        topBar.contentView.addSubview(topBarActionsLayoutView)
        topBar.contentView.addSubview(flashButton)
        topBar.contentView.addSubview(autoScanButton)
        
        addSubview(topBar)
        addSubview(cancelButton)
        addSubview(shutterButton)
        addSubview(activityIndicator)
        self.topBar = topBar
        
        topBar.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        topBar.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        topBar.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        flashButton.centerYAnchor.constraint(equalTo: topBarActionsLayoutView.centerYAnchor).isActive = true
        autoScanButton.centerYAnchor.constraint(equalTo: topBarActionsLayoutView.centerYAnchor).isActive = true
        if #available(iOS 11.0, *) {
            topBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 44).isActive = true
            flashButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: autoScanButton.trailingAnchor, constant: 16).isActive = true
            cancelButton.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor, constant: 24.0).isActive = true
            self.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: (65.0 / 2) - 10.0).isActive = true
            self.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0).isActive = true
        } else {
            flashButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
            self.trailingAnchor.constraint(equalTo: autoScanButton.trailingAnchor, constant: 16).isActive = true
            
            cancelButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 24.0).isActive = true
            self.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: (65.0 / 2) - 10.0).isActive = true
            self.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0).isActive = true
        }
        
        shutterButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: 65.0).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: 65.0).isActive = true
        
        activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if let _ = newWindow {
            viewController?.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    private func removeFocusRectangleIfNeeded(animated: Bool) {
        guard let focusRectangle = focusRectangle else { return }
        
        self.focusRectangle = nil
        if animated && self.window != nil {
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
                focusRectangle.alpha = 0.0
            }, completion: { (_) in
                focusRectangle.removeFromSuperview()
            })
        } else {
            focusRectangle.removeFromSuperview()
        }
    }
}

extension UIView {
    fileprivate var viewController: UIViewController? {
        var next = self.next
        while next != nil && !(next is UIViewController) {
            next = next!.next
        }
        
        return next as? UIViewController
    }
}
