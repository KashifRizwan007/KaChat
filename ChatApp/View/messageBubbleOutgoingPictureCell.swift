//
//  messageBubbleOutgoingPictureCell.swift
//  ChatBubbleAdvanced
//
//  Created by Kashif Rizwan on 8/20/19.
//  Copyright © 2019 Dima Nikolaev. All rights reserved.
//

import UIKit

class messageBubbleOutgoingPictureCell: UITableViewCell {

    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var message: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bubbleLayerView: UIView!
    
    var outgoingMessageLayer = CAShapeLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.arrangedSubviews.last?.isHidden = true
        stackView.arrangedSubviews.first?.isHidden = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: .showHideTransitionViews,
                       animations: { () -> Void in
                        self.stackView.arrangedSubviews.last?.isHidden = !selected
                        self.stackView.arrangedSubviews.first?.isHidden = !selected
        },
                       completion: nil)
    }
    
    func showIncomingMessage(cellWidth: CGFloat) {
        let width: CGFloat = message.bounds.width
        let height: CGFloat = message.bounds.height
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 22, y: height))
        bezierPath.addLine(to: CGPoint(x: width - 17, y: height))
        bezierPath.addCurve(to: CGPoint(x: width, y: height - 17), controlPoint1: CGPoint(x: width - 7.61, y: height), controlPoint2: CGPoint(x: width, y: height - 7.61))
        bezierPath.addLine(to: CGPoint(x: width, y: 17))
        bezierPath.addCurve(to: CGPoint(x: width - 17, y: 0), controlPoint1: CGPoint(x: width, y: 7.61), controlPoint2: CGPoint(x: width - 7.61, y: 0))
        bezierPath.addLine(to: CGPoint(x: 21, y: 0))
        bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
        bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
        bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 4, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
        bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
        bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04), controlPoint1: CGPoint(x: 4.07, y: height + 0.43), controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
        bezierPath.addCurve(to: CGPoint(x: 22, y: height), controlPoint1: CGPoint(x: 16, y: height), controlPoint2: CGPoint(x: 19, y: height))
        bezierPath.close()
        
        let incomingMessageLayer = CAShapeLayer()
        incomingMessageLayer.path = bezierPath.cgPath
        incomingMessageLayer.frame = CGRect(x: 0,
                                            y: 0,
                                            width: width,
                                            height: height)
        
        message.contentMode = .scaleAspectFill
        message.clipsToBounds = true
        message.layer.mask = incomingMessageLayer
    }

}
