//
//  CaptureSession+Flash.swift
//  WeScan
//
//  Created by Julian Schiavo on 28/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation

/// Extension to CaptureSession to manage the device flashlight
extension CaptureSession {
    
    public typealias FlashMode = AVCaptureDevice.TorchMode
    
    public var flashMode: FlashMode? {
        guard let device = device, device.isTorchAvailable else { return nil }
        
        switch device.torchMode {
        case .auto: return .auto
        case .on: return .on
        case .off: return .off
        }
    }
    
    /// Toggles the current device's flashlight on or off.
    @discardableResult
    public func toggleFlash() -> FlashMode? {
        guard let device = device, device.isTorchAvailable else { return nil }
        
        do {
            try device.lockForConfiguration()
        } catch {
            switch device.torchMode {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }
        
        defer {
            device.unlockForConfiguration()
        }
        
        switch device.torchMode {
        case .auto:
            device.torchMode = .on
            return .on
        case .on:
            device.torchMode = .off
            return .off
        case .off:
            device.torchMode = .on
            return .on
        }
    }
    
    @discardableResult
    public func setFlashMode(_ flashMode: FlashMode) -> FlashMode? {
        guard let device = device, device.isTorchAvailable else { return nil }
        
        do {
            try device.lockForConfiguration()
        } catch {
            switch device.torchMode {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }
        
        defer {
            device.unlockForConfiguration()
        }
        
        device.torchMode = flashMode
        return flashMode
    }
}
