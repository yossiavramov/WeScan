//
//  EditScanCornerView.swift
//  WeScan
//
//  Created by Boris Emorine on 3/5/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A UIView used by corners of a quadrilateral that is aware of its position.
public final class EditScanCornerView: UIView {
    
    public let position: CornerPosition
    
    /// The image to display when the corner view is highlighted.
    private var image: UIImage?
    private(set) var isHighlighted = false
    
    lazy private var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1.0
        return layer
    }()
    
    public var circleFillColor: UIColor? {
        get {
            guard let color = circleLayer.fillColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            circleLayer.fillColor = newValue?.cgColor
        }
    }
    
    public var circleStrokeColor: UIColor? {
        get {
            guard let color = circleLayer.strokeColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            circleLayer.strokeColor = newValue?.cgColor
        }
    }
    
    public init(frame: CGRect, position: CornerPosition) {
        self.position = position
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = true
        layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let bezierPath = UIBezierPath(ovalIn: rect.insetBy(dx: circleLayer.lineWidth, dy: circleLayer.lineWidth))
        circleLayer.frame = rect
        circleLayer.path = bezierPath.cgPath
        
        image?.draw(in: rect)
    }
    
    public func highlightWithImage(_ image: UIImage) {
        isHighlighted = true
        self.image = image
        self.setNeedsDisplay()
    }
    
    public func reset() {
        isHighlighted = false
        image = nil
        setNeedsDisplay()
    }
}
