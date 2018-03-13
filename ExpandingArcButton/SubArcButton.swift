//
//  SubArcButton.swift
//  ExpandingArcButton
//
//  Created by John Jin Woong Kim on 2/13/18.
//  Copyright © 2018 John Jin Woong Kim. All rights reserved.
//

import Foundation
import UIKit

// https://d1u5p3l4wpay3k.cloudfront.net/dota2_gamepedia/4/43/Defaultchatwheel.jpeg?version=7c5bf1cb8746ddc46e148c99e0ec259e
// This SubArcButton will be similar to the above link, the chat wheel in dota.  The subarc will
//   not be visible, but will still be computed to act as a contains checker to see whether or not
//   the user has dragged and panned the center button to a respective subarc

class SubArcButton: NSObject, CAAnimationDelegate{
    
    var index = -1
    var total:CGFloat = 0
    var animDuration: CGFloat = 0.1
    
    // 4 bezier paths representing the shapes between the 4 states
    //  pre/post ExpandedPath are for when the subbuttons are to be expanded
    //  pre/post ContractedPath are for when the subbuttons are to be contracted
    var preExpandedPath: UIBezierPath!
    var postExpandedPath: UIBezierPath!
    var preContractedPath: UIBezierPath!
    var postContractedPath: UIBezierPath!
    
    // centerExpandedPoint is the centerpoint when the subbuttons are expanded into view
    // centerContractedPoint is when the subbuttons have been contracted out of view
    var centerExpandedPoint: CGPoint!
    var centerContractedPoint:CGPoint!
    
    // title: string to be used on the subbutton's text
    var title: String!
    // radius that determines subbutton's two isosceles side lengths are
    var radius: CGFloat!
    
    // Frame variables that represent the superview's sizes when expanded/contracted
    var expandedFrame: CGRect!
    var frame : CGRect!
    
    // the two layers we are working with
    let shapeLayer = CAShapeLayer()
    let textLayer = CATextLayer()
    
    // angleStart: Starting angle, clockwise
    var angleStart:CGFloat!
    // angleEnd: angle to end at from angleStart, clockwise
    var angleEnd: CGFloat!
    // angleOffset - offset value to be added to angleStart to give the angle between start and end
    var angleOffset: CGFloat!
    
    //  textLayerPositionScalar - scalar to manipulate where the origin of the textLayer's frame will be
    var textLayerPositionScalar: CGFloat!
    //  textLayerWidth - width of the textLayer, to be calculated once the height is given
    var textLayerWidth: CGFloat = 0
    
    var shapeBorderColor: CGColor = UIColor.clear.cgColor
    var shapeFillColor: CGColor = UIColor.clear.cgColor
    var onTapFillColor: CGColor = UIColor.clear.cgColor
    var onTapBorderColor: CGColor = UIColor.clear.cgColor
    
    var onTapTextColor: CGColor = UIColor.black.cgColor
    
    var smallFontFrame: CGRect!
    var largeFontFrame: CGRect!
    
    var borderOffset: CGFloat!
    var smallFontOffset: CGFloat!
    var largeFontOffset: CGFloat!
    
    var originPointForTextExpandedPoint: CGPoint!
    var originPointForTextContractedPoint: CGPoint!
    var originPointForTextContractedPostPoint:CGPoint!
    
    var arrowOffset: CGFloat = 10

    init(frame:CGRect, index: Int, title:String, total: Int, arcCenter: CGPoint, radius: CGFloat, borderOffset: CGFloat) {
        super.init()
        self.expandedFrame = CGRect(x: 0, y: 0, width: radius*2, height: radius*2)
        self.centerContractedPoint = CGPoint(x:  frame.width/2, y: frame.width/2)
        self.index = index
        self.title = title
        self.centerExpandedPoint = arcCenter
        self.radius = radius
        self.frame = frame
        self.total = CGFloat(total)
        self.borderOffset = borderOffset
        self.textLayerPositionScalar = 1/3
        //self.animDuration = self.animDuration / CGFloat( total)
        

        self.setPath()
        shapeFillColor = UIColor.clear.cgColor
    }
    
    // this creates the arc shape that this sub button will employ
    func setPath(){
        angleStart = 90+((360.0/total)/2)
        angleStart = angleStart + ((360.0/total)*CGFloat( index))
        angleOffset = ((360.0/total)/2)
        angleEnd = angleStart+(360.0/total)
        
        // Calculates shape path for expanded sections of the subbuttons, but parentview is expanded
        postExpandedPath = UIBezierPath()
        postExpandedPath.move(to: centerExpandedPoint)
        postExpandedPath.addLine(to: translatePoint(current: centerExpandedPoint, angle: CGFloat( remainder(angleStart, 360.0) ), rad: radius/3))
        postExpandedPath.addArc(withCenter:centerExpandedPoint,
                       radius: self.radius/3,
                       startAngle: CGFloat(  remainder(angleStart, 360.0) ).toRadians(),
                       endAngle: CGFloat(remainder(angleEnd, 360.0) ).toRadians(),
                       clockwise: true)
        postExpandedPath.close()
        
        // calculates shape path for the subbuttons expanded, but the parentview is contracted
        preContractedPath = UIBezierPath()
        preContractedPath.move(to: centerContractedPoint)
        preContractedPath.addLine(to: translatePoint(current: centerContractedPoint, angle: CGFloat(remainder(angleStart, 360.0) ), rad: radius/3))
        preContractedPath.addArc(withCenter:centerContractedPoint,
                       radius: self.radius/3,
                       startAngle: CGFloat(remainder(angleStart, 360.0) ).toRadians(),
                       endAngle: CGFloat(remainder(angleEnd, 360.0) .toRadians()),
                       clockwise: true)
        preContractedPath.close()
        //preContractedPath.addLine(to: centerContractedPoint)
        
        // calculates shape path for the subbuttons contracted, but parentview is expanded
        preExpandedPath = UIBezierPath()
        preExpandedPath.move(to: centerExpandedPoint)
        preExpandedPath.addLine(to: translatePoint(current: centerExpandedPoint, angle: CGFloat(remainder(angleStart, 360.0) ), rad: 0))
        preExpandedPath.addArc(withCenter:centerExpandedPoint,
                       radius: 0,
                       startAngle: CGFloat(remainder(angleStart, 360.0) ).toRadians(),
                       endAngle: CGFloat(remainder(angleEnd, 360.0) ).toRadians(),
                       clockwise: true)
        preExpandedPath.addLine(to: centerExpandedPoint)
        
        // calculates shape path for the subbutons contracted, but parentview is contracted
        postContractedPath = UIBezierPath()
        postContractedPath.move(to: centerContractedPoint)
        postContractedPath.addLine(to: translatePoint(current: centerContractedPoint, angle: CGFloat(remainder(angleStart, 360.0) ), rad: 0))
        postContractedPath.addArc(withCenter:centerContractedPoint,
                         radius: 0,
                         startAngle: CGFloat(remainder(angleStart, 360.0) ).toRadians(),
                         endAngle: CGFloat(remainder(angleEnd, 360.0) ).toRadians(),
                         clockwise: true)
        postContractedPath.addLine(to: centerContractedPoint)
    }
    
    
    func calculateWidth(smallFont: UIFont, largeFont: UIFont, title:String){
        // font parameter passed in is  UIFont.boldSystemFont(ofSize: 25)
        smallFontFrame = CGRect(x: expandedFrame.width/2, y: expandedFrame.height/2, width: title.width(withConstrainedHeight: smallFont.fontDescriptor.pointSize, font: smallFont), height: smallFont.fontDescriptor.pointSize )
        largeFontFrame = CGRect(x: expandedFrame.width/2, y: expandedFrame.height/2, width: title.width(withConstrainedHeight: largeFont.fontDescriptor.pointSize, font: largeFont), height: largeFont.fontDescriptor.pointSize )
        
        let sw = smallFontFrame.width/2
        let sh = smallFontFrame.height/2
        let lw = largeFontFrame.width/2
        let lh = largeFontFrame.height/2
        
        smallFontOffset = sqrt( ( sw*sw ) + ( sh*sh) )
        largeFontOffset = sqrt( ( lw*lw ) + ( lh*lh) )
        
        originPointForTextExpandedPoint = originPointForTextExpanded()
        originPointForTextContractedPoint = originPointForTextContracted(flag: 0)
        originPointForTextContractedPostPoint = originPointForTextContracted(flag: 1)
        
        textLayer.frame = largeFontFrame
        textLayer.font = smallFont
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.string = title
        //textLayer.borderWidth = 1
        //textLayer.borderColor = UIColor.green.cgColor
        textLayer.zPosition = 2
        textLayer.masksToBounds = true
        //print("texyLayer title/truncationMode", title, " / ", textLayer.truncationMode)
        
    }
    
    // Given the flag, applies the transformation of the shapeLayer's path,
    //  which will either go from small to large, or large to small.
    //  Although there are only two transformations, the superview itself also
    //  expands and contracts, thus giving the 4 states.
    func applyShapeLayer(flag:Int){
        //shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = 2.0
        
        let animation = CABasicAnimation(keyPath: "path")
        if flag == 0{
            shapeLayer.path = preExpandedPath.cgPath
            animation.fromValue = preExpandedPath.cgPath
            animation.toValue = postExpandedPath.cgPath
        }else{
            animation.fromValue = preContractedPath.cgPath
            animation.toValue = postContractedPath.cgPath
        }
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = 1
        
        let animation1 = CABasicAnimation(keyPath: "fillColor")
        
        if flag == 0{
            animation1.fromValue = UIColor.clear.cgColor
            animation1.toValue = self.shapeFillColor
            self.shapeLayer.fillColor = self.shapeFillColor
        }else{
            animation1.fromValue = self.onTapFillColor
            animation1.toValue = UIColor.clear.cgColor
            self.shapeLayer.fillColor = UIColor.clear.cgColor
        }
        animation1.fillMode = kCAFillModeForwards
        
        let group = CAAnimationGroup()
        group.delegate = self
        group.animations = NSArray(arrayLiteral:  animation) as? [CAAnimation]
        group.isRemovedOnCompletion = false
        group.duration = CFTimeInterval(self.animDuration)
        group.fillMode = kCAFillModeForwards
        
        // specific to the ontap animation of highlighting the subbutton that has been
        //  tapped.
        let animation2 = CABasicAnimation(keyPath: "strokeColor")
        if flag == 1{
            animation2.fromValue = self.onTapBorderColor
            animation2.toValue = UIColor.clear.cgColor
            self.shapeLayer.fillColor = nil
             group.animations?.append(animation2)
        }
       
        if flag == 0{
            shapeLayer.add(group, forKey: "shapeLayer0")
        }else{
            shapeLayer.add(group, forKey: "shapeLayer1")
        }
    }
    
    // Given the flag, animations will translate subbutton's positions as well as
    //   scale the textSize of the textLayers.
    func applyTextLayer(flag:Int){
        
        let animation1 = CABasicAnimation(keyPath: "position")
        if flag == 0{
            //textLayer.position = CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2 )
            animation1.fromValue = CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2 )
            animation1.toValue = originPointForTextContractedPoint
            textLayer.position = originPointForTextContractedPoint
        }else{
            animation1.fromValue = originPointForTextContractedPostPoint
            animation1.toValue = CGPoint(x: frame.width/2, y: frame.width/2 )
            textLayer.position = CGPoint(x: frame.width/2, y: frame.width/2 )
        }
        animation1.fillMode = kCAFillModeForwards
        
        let animation2 = CABasicAnimation(keyPath: "fontSize")
        if flag == 0{
            animation2.fromValue = 0.0
            animation2.toValue =  25.0
            textLayer.fontSize = 25.0
        }else{
            animation2.fromValue = 25.0
            animation2.toValue = 0.0
            textLayer.fontSize = 0.0
        }
        animation2.fillMode = kCAFillModeForwards
        
        let group = CAAnimationGroup()
        group.delegate = self
        group.animations = NSArray(arrayLiteral: animation2, animation1) as? [CAAnimation]
        group.isRemovedOnCompletion = true
        group.duration = CFTimeInterval(animDuration)
        group.fillMode = kCAFillModeForwards
        
        // specific to the ontap animation of highlighting the subbutton that has been
        //  tapped.
        let animation3 = CABasicAnimation(keyPath: "foregroundColor")
        if flag == 1{
            animation3.fromValue = self.onTapBorderColor
            animation3.toValue = UIColor.black.cgColor
            self.textLayer.foregroundColor = UIColor.black.cgColor
            group.animations?.append(animation3)
        }
        
        if flag == 0{
            textLayer.add(group, forKey: "textLayer0")
        }else{
            textLayer.add(group, forKey: "textLayer1")
        }
    }
    
    func applyPannedTextLayer(flag:Int){
        
        let animation1 = CABasicAnimation(keyPath: "position")
        if flag == 0{
            animation1.fromValue = originPointForTextContractedPoint
            animation1.toValue = originPointForTextExpandedPoint
            textLayer.position = originPointForTextExpandedPoint
        }else{
            animation1.fromValue = originPointForTextExpandedPoint
            animation1.toValue = originPointForTextContractedPoint
            textLayer.position = originPointForTextContractedPoint
        }
        animation1.fillMode = kCAFillModeForwards
        
        let animation2 = CABasicAnimation(keyPath: "fontSize")
        if flag == 0{
            animation2.fromValue = 25.0
            animation2.toValue =  35.0
            textLayer.fontSize = 35.0
        }else{
            animation2.fromValue = 35.0
            animation2.toValue = 25.0
            textLayer.fontSize = 25.0
        }
        animation2.fillMode = kCAFillModeForwards
        
        let group = CAAnimationGroup()
        group.delegate = self
        group.animations = NSArray(arrayLiteral: animation1, animation2) as? [CAAnimation]
        group.isRemovedOnCompletion = true
        group.duration = CFTimeInterval(self.animDuration)
        group.fillMode = kCAFillModeForwards
        
        if flag == 0{
            textLayer.add(group, forKey: "textLayer3")
        }else{
            textLayer.add(group, forKey: "textLayer4")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func translatePoint(current:CGPoint, angle:CGFloat, rad: CGFloat) -> CGPoint{
        var x: CGFloat = current.x + rad*cos(angle.toRadians())
        var y: CGFloat = current.y + rad*sin(angle.toRadians())
        x = x.rounded(.down)
        y = y.rounded(.down)
        return CGPoint(x: x, y: y)
    }
    
    func originPointForTextExpanded()-> CGPoint{
        return translatePoint(current: centerExpandedPoint, angle: angleStart + angleOffset, rad: (self.radius*textLayerPositionScalar) + (self.borderOffset + self.largeFontOffset + self.arrowOffset) )
    }
    
    func originPointForTextContracted(flag: Int)-> CGPoint{
        // flag == 0 origin point for textlayers when the superview is expanded
        if flag == 0{
            return translatePoint(current: centerExpandedPoint, angle: angleStart + angleOffset, rad: (self.radius*textLayerPositionScalar) + (self.borderOffset + self.smallFontOffset) )
        }else{
            // flag == 1 origin point for texylayters wehe the superview is contracted
            return translatePoint(current: centerContractedPoint, angle: angleStart + angleOffset, rad: (self.radius*textLayerPositionScalar) + (self.borderOffset + self.smallFontOffset) )

        }
     }
    
    
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if shapeLayer.animation(forKey: "shapeLayer1") == anim{
            self.shapeLayer.removeAllAnimations()
            self.shapeLayer.removeFromSuperlayer()
            self.resetColors()
        }else if textLayer.animation(forKey: "textLayer0") == anim{
           // self.textLayer.fontSize = 25.0
        }else if textLayer.animation(forKey: "textLayer1") == anim{
            self.textLayer.removeAllAnimations()
            self.textLayer.removeFromSuperlayer()
            //self.textLayer.removeAllAnimations()
            //self.textLayer.frame = largeFontFrame
        }else if textLayer.animation(forKey: "textLayer3") == anim{
            
            //self.textLayer.fontSize = 35.0
        }else if textLayer.animation(forKey: "textLayer4") == anim{
            //self.textLayer.removeAllAnimations()
            //self.textLayer.fontSize = 25.0
            
        }
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        //print("animationDidStart")
        
    }
    
    func resetColors(){
        self.onTapBorderColor = self.shapeBorderColor
        self.onTapFillColor = self.shapeFillColor
        self.onTapTextColor = UIColor.black.cgColor
    }
    
    func resetFontSize(){
        self.textLayer.removeAllAnimations()
        self.textLayer.fontSize = 25
        self.textLayer.position = self.originPointForTextContractedPoint
    }
}

