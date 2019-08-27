//
//  messageBubbleOutgoingCell.swift
//  ChatBubbleAdvanced
//
//  Created by Kashif Rizwan on 8/16/19.
//  Copyright © 2019 Dima Nikolaev. All rights reserved.
//

import UIKit

class messageBubbleOutgoingCell: UITableViewCell {
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bubbleLayerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.arrangedSubviews.last?.isHidden = true
        stackView.arrangedSubviews.first?.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: { () -> Void in
                        self.stackView.arrangedSubviews.last?.isHidden = !selected
                        self.stackView.arrangedSubviews.first?.isHidden = !selected
        },
                       completion: nil)
    }
    
    func showOutgoingMessage(text: String, cellWidth: CGFloat){
        
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .white
        label.text = text
        
        let constraintRect = CGSize(width: 0.66 * cellWidth,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font],
                                            context: nil)
        label.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))
        
        let bubbleSize = CGSize(width: label.frame.width + 33,
                                height: label.frame.height + 18)
        
        let width = bubbleSize.width
        let height = bubbleSize.height
        
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
        
        self.frame = CGRect(x: 0.0, y: 0.0, width: cellWidth, height: height + 5)
        
        incomingMessageLayer.frame = CGRect(x: 20,
                                            y: self.frame.height/2 - height/2 + 2,
                                            width: 68,
                                            height: 17)
        incomingMessageLayer.fillColor = UIColor(red: 0.09, green: 0.54, blue: 1, alpha: 1).cgColor
        
        self.layer.addSublayer(incomingMessageLayer)
        
        self.bubbleLayerView.layer.insertSublayer(incomingMessageLayer, below: self.message.layer)
    }

}
