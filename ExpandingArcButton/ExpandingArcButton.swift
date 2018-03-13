//
//  ExpandingArcButton.swift
//  ExpandingArcButton
//
//  Created by John Jin Woong Kim on 2/13/18.
//  Copyright © 2018 John Jin Woong Kim. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import RxGesture

// https://d1u5p3l4wpay3k.cloudfront.net/dota2_gamepedia/4/43/Defaultchatwheel.jpeg?version=7c5bf1cb8746ddc46e148c99e0ec259e
// This SubArcButton will be similar to the above link, the chat wheel in dota.  The subarc will
//   not be visible, but will still be computed to act as a contains checker to see whether or not
//   the user has dragged and panned the center button to a respective subarc

class ExpandingArcButton: UIView, CAAnimationDelegate,UICollisionBehaviorDelegate{
    var someViews:[UIView] = []

    // main controller.  expands/contracts sublayers and can drag and drop
    var mainButton: UIButton!
    // SubArcButtons which act as the handlers for the layers in each
    //  partition taking up the circle.  Deals in CAShapeLayers & CATextLayers
    //  and handles formatting, animations, etc
    var expandButtons = [SubArcButton]()
    
    // CAShapeLayer circle encapsulating the mainbutton whne
    //   expanded.  Uses UICollisionBehavior to detect when main button
    //   has been dragged into collision
    var outerCircleShapeLayer = CAShapeLayer()
    // 3 paths representing 3 states of the outerCircleShapeLayer.
    //  1. When the superview has expanded but the outerCircleShapeLayer is still contracted
    //  2. When the superview has expanded and the outerCircleShapeLayer
    //  3. When the superview & outerCircleShapeLayer has contracted
    var preExpandedPath: UIBezierPath!
    var postExpandedPath: UIBezierPath!
    var postContractedPath: UIBezierPath!
    // The 2 pairs of 2 paths that draw the donut shape for outerCircleShapeLayer
    //   The first two have bounds to center on the expanded superview
    var innerCirclePath: UIBezierPath!
    var outerCirclePath : UIBezierPath!
    //   These two have bounds to center on the contracted superview
    var conInnerCirclePath: UIBezierPath!
    var conOuterCirclePath : UIBezierPath!
    // width value of outerCircleShapeLayer
    var outerCircleBorderWidth: CGFloat = 10
    // animation duration for layers and views
    var animDuration: CGFloat = 0.5
    
    var centralBorderColor: CGColor = UIColor.white.cgColor
    var centralFillColor: CGColor = UIColor.black.cgColor
    
    // state variable that determines what mode it is
    //  0 == unexpanded
    //  1 == expanded, main button not being panned
    //  2 == expanded, main button being panned
    var state = 0
    let disposeBag = DisposeBag()
    // cgrect,cgpoint for the superview's expanded state
    var expandedFrame : CGRect!
    var expandCenter: CGPoint!

    // cgrect,cgpoint for the superview's contracted state
    var orgFrame:CGRect!
    var orgCenter: CGPoint!
    // duration to be divided depending on titles.count and delay
    //  sequential animations by that value
    var animationOffset: CGFloat = 0.5
    // text titles for the subarcs
    var titles = [String]()
    
    var animator: UIDynamicAnimator!
    // path that is used to check if users are within the
    //  main button's original bounds
    var mainButtonPath: UIBezierPath!
    
    // temp var used to hold the last panned location coords, useful
    //  when neededing to backtrack
    var lastCenter:CGPoint!
    // temp var used to hold the index of the subarc that is currently being panned
    var currentTextLayerIndex = -1
    
    // size offset for the arrow pointer
    var arrowOffset:CGFloat!
    // CAShapeLayer for arrow pointer
    var arrowShapeLayer: CAShapeLayer = CAShapeLayer()
    var preArrowPath: UIBezierPath!
    var postArrowPath: UIBezierPath!
    
    init(frame:CGRect, titles :[String]) {
        super.init(frame: frame)
        //self.layer.borderWidth = 1
        //self.layer.borderColor = UIColor.red.cgColor
        
        self.titles = titles
        let keyFrame = UIScreen.main.bounds
        // storing of two frame states, expanded and contracted
        orgFrame = frame
        expandedFrame = CGRect(origin: .zero, size: CGSize(width: keyFrame.width, height: keyFrame.width))
        orgCenter = CGPoint(x: frame.width/2, y: frame.width/2)
        expandCenter = CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2)
        
        // buttons
        centerButtonSetup()
        
        outerCircleShapeLayerSetup()
        
        initializeSubLayers()
        
        setButtonActions()
     
        self.arrowShapeLayer.zPosition = 10
        arrowOffset = 3
    }
    
    func setupArrowShapeLayer(angle: CGFloat){
        // given an angle, calculates paths for the 2 states the arrow indicator is in.
        //  Used when the arrow needs to animate into or out of use.
        preArrowPath = UIBezierPath()
        preArrowPath.move(to: expandCenter)
        preArrowPath.move(to: translatePoint(current: expandCenter, angle: remainder(angle-5.0, 360 ), rad: expandedFrame.width/6))
        preArrowPath.addArc(withCenter:expandCenter,
                                radius: self.expandedFrame.width/6,
                                startAngle: CGFloat( remainder(angle-5.0, 360 ) ).toRadians(),
                                endAngle: CGFloat( remainder(angle+5.0, 360 ) ).toRadians(),
                                clockwise: true)
        preArrowPath.addLine(to: translatePoint(current: expandCenter, angle: remainder(angle, 360 ), rad: (self.expandedFrame.width/6) + outerCircleBorderWidth ))
        preArrowPath.close()

        postArrowPath = UIBezierPath()
        postArrowPath.move(to: expandCenter)
        postArrowPath.move(to: translatePoint(current: expandCenter, angle: remainder(angle-5.0, 360 ), rad: expandedFrame.width/6 + self.outerCircleBorderWidth + arrowOffset ))
        postArrowPath.addArc(withCenter:expandCenter,
                                radius: self.expandedFrame.width/6 + self.outerCircleBorderWidth + arrowOffset,
                                startAngle: CGFloat( remainder(angle-5.0, 360 ) ).toRadians(),
                                endAngle: CGFloat( remainder(angle+5.0, 360 ) ).toRadians(),
                                clockwise: true)
        postArrowPath.addLine(to: translatePoint(current: expandCenter, angle: remainder(angle, 360 ), rad: (self.expandedFrame.width/6) + outerCircleBorderWidth+10 ))
        postArrowPath.close()
    }
    
    func centerButtonSetup(){
        self.mainButton = UIButton(frame: CGRect(origin: .zero, size: frame.size) )
        self.mainButton.layer.cornerRadius = frame.width/2
        self.mainButton.layer.borderWidth = 2
        self.mainButton.layer.borderColor = centralBorderColor
        self.mainButton.layer.backgroundColor = centralFillColor
        self.mainButton.translatesAutoresizingMaskIntoConstraints = false
        self.mainButton.layer.zPosition = 3
        mainButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        mainButton.layer.shadowOpacity = 0.7
        mainButton.layer.shadowRadius = 5
        mainButton.layer.shadowColor = UIColor(red: 44.0/255.0, green: 62.0/255.0, blue: 80.0/255.0, alpha: 1.0).cgColor
        
        self.addSubview(mainButton)
        self.someViews.append(mainButton)
    }
    
    func outerCircleShapeLayerSetup(){
        
        preExpandedPath = UIBezierPath(
            arcCenter: CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2 ),
            radius: 1,
            startAngle: CGFloat(0.0),
            endAngle: CGFloat(2.0 * .pi),
            clockwise: true)
        postExpandedPath = UIBezierPath(
            arcCenter: CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2 ),
            radius: expandedFrame.width/6,
            startAngle: CGFloat(0.0),
            endAngle: CGFloat(2.0 * .pi),
            clockwise: true)
        postContractedPath = UIBezierPath(
            arcCenter: CGPoint(x: self.orgFrame.width/2, y: self.orgFrame.width/2 ),
            radius: 1,
            startAngle: CGFloat(0.0),
            endAngle: CGFloat(2.0 * .pi),
            clockwise: true)
        
        
        outerCircleShapeLayer = CAShapeLayer()
        outerCircleShapeLayer.shadowOffset = CGSize(width: 5, height: 5)
        outerCircleShapeLayer.shadowOpacity = 0.7
        outerCircleShapeLayer.shadowRadius = 3
        outerCircleShapeLayer.shadowColor = UIColor(red: 44.0/255.0, green: 62.0/255.0, blue: 80.0/255.0, alpha: 1.0).cgColor
        outerCircleShapeLayer.fillRule = kCAFillRuleEvenOdd

        // essentially the same path, but one with a larger radius allowing for the formation
        //  of a donut shape
        outerCirclePath = UIBezierPath(arcCenter: CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2),
                                       radius: expandedFrame.width/6 + outerCircleBorderWidth,
                                       startAngle: CGFloat(0.0),
                                       endAngle: CGFloat(2.0 * .pi),
                                       clockwise: true)

        innerCirclePath = UIBezierPath(arcCenter: CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2),
                                       radius: expandedFrame.width/6,
                                       startAngle: CGFloat(0.0),
                                       endAngle: CGFloat(2.0 * .pi),
                                       clockwise: true)
        outerCirclePath.append(innerCirclePath)
        outerCirclePath.usesEvenOddFillRule = true
        
        //  same principal here, but adjusted for the contracted superview
        conOuterCirclePath = UIBezierPath(arcCenter: CGPoint(x: orgFrame.width/2, y: orgFrame.width/2),
                                       radius: expandedFrame.width/6 + outerCircleBorderWidth,
                                       startAngle: CGFloat(0.0),
                                       endAngle: CGFloat(2.0 * .pi),
                                       clockwise: true)
        conInnerCirclePath = UIBezierPath(arcCenter: CGPoint(x: orgFrame.width/2, y: orgFrame.width/2),
                                       radius: expandedFrame.width/6,
                                       startAngle: CGFloat(0.0),
                                       endAngle: CGFloat(2.0 * .pi),
                                       clockwise: true)
        conOuterCirclePath.append(conInnerCirclePath)
        conOuterCirclePath.usesEvenOddFillRule = true
        
        mainButtonPath = UIBezierPath(arcCenter: CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2),
                                      radius: 22,
                                      startAngle: CGFloat(0.0),
                                      endAngle: CGFloat(2.0 * .pi),
                                      clockwise: true)
    }
    
    // toggles the presence of the boundary
    func toggleBoundaries(flag: Int) {
        let collision = UICollisionBehavior(items: someViews)
        if flag == 0{
            animator = UIDynamicAnimator(referenceView: self)
            collision.collisionDelegate = self
            collision.translatesReferenceBoundsIntoBoundary = true
            collision.addBoundary(withIdentifier: "outerCircleBoundary" as NSCopying, for: UIBezierPath(cgPath: outerCircleShapeLayer.path!))
            collision.collisionMode = .everything
            animator.addBehavior(collision)
        }else{
            for v in someViews{
                collision.removeItem(v)
            }
            animator.removeAllBehaviors()
            collision.removeAllBoundaries()
        }
    }

    // initializes the subarcs and calculate necessary UI variables and components
    func initializeSubLayers(){
        for (index,t) in self.titles.enumerated(){
            let b = SubArcButton(frame: CGRect(origin: .zero, size: frame.size),
                                 index: index,
                                 title: t,
                                 total: titles.count,
                                 arcCenter: CGPoint(x: expandedFrame.width/2, y: expandedFrame.width/2 ),
                                 radius: expandedFrame.width/2,
                                 borderOffset: outerCircleBorderWidth)
            b.calculateWidth(smallFont: UIFont.boldSystemFont(ofSize: 25) , largeFont: UIFont.boldSystemFont(ofSize: 35) , title: t)
            self.expandButtons.append(b)
        }
    }
    
    func setButtonActions(){
        // rxswift pangesture subscriber
        mainButton.rx.panGesture()
            .when(.began, .ended, .changed)
            .subscribe(onNext: { gesture in
                // pangesture states can only be accessable when the button is in
                //  its expanded state
                if self.state == 1 || self.state == 2{
                    switch gesture.state{
                    case .began:
                        self.state = 2
                        let translate = gesture.translation(in: self)
                        let temp = CGPoint(x: self.mainButton.center.x + translate.x,
                                           y: self.mainButton.center.y + translate.y)

                        self.lastCenter = self.mainButton.center
                        self.mainButton.center = temp
                        gesture.setTranslation(CGPoint.zero, in: self)
                        self.toggleBoundaries(flag: 0)
                    case .changed:
                        let translate = gesture.translation(in: self)
                        let p = CGPoint(x: self.mainButton.center.x + translate.x, y: self.mainButton.center.y + translate.y)
                        let l = CGPoint(x: gesture.location(in: self).x, y: gesture.location(in: self).y)
                        if (!self.postExpandedPath.contains(p) && !self.outerCirclePath.contains(p)) ||
                                    (!self.postExpandedPath.contains(l) && !self.outerCirclePath.contains(l)){
                                                        self.setupArrowShapeLayer(
                                angle: atan2(self.mainButton.center.y - self.expandCenter.y ,
                                             self.mainButton.center.x - self.expandCenter.x).toDegrees())
                                self.applyArrowAnimation(flag: 1)
                                            gesture.end()
                                print("panning cancelled")
                            }else{
                            let temp = CGPoint(x: self.mainButton.center.x + translate.x, y: self.mainButton.center.y + translate.y)
                                            self.lastCenter = self.mainButton.center
                                self.mainButton.center = temp
                                gesture.setTranslation(CGPoint.zero, in: self)
                                self.toggleBoundaries(flag: 0)
                            // apply CATextLayer animation ehre
                            // if the new panned coord is not within the bounds of the original position of
                                //   main button, then continue to animate a textlayer
                                if !self.mainButtonPath.contains(temp){
                                    // get index of the subarc that contains the new panned coordinate
                                        var i = -1
                                        for sub in self.expandButtons{
                                            if sub.postExpandedPath.contains(temp){
                                                    i = sub.index
                                                        break
                                                    }
                                            }
                                        // states
                                        if  i != -1{
                                            if self.currentTextLayerIndex == -1{
                                                //  moving from the center area to a subarc
                                                self.expandButtons[i].applyPannedTextLayer(flag: 0)
                                                self.currentTextLayerIndex = i
                                                self.setupArrowShapeLayer(angle: atan2(self.mainButton.center.y - self.expandCenter.y , self.mainButton.center.x - self.expandCenter.x).toDegrees())
                                                self.layer.addSublayer(self.arrowShapeLayer)
                                                self.applyArrowAnimation(flag: 0)
                                                
                                            }else if self.currentTextLayerIndex != i{
                                                // moving from subarc to subarc
                                                self.expandButtons[i].applyPannedTextLayer(flag: 0)
                                            self.expandButtons[self.currentTextLayerIndex].applyPannedTextLayer(flag: 1)
                                                        self.currentTextLayerIndex = i
                                                let boundbox = self.arrowShapeLayer.path?.boundingBox
                                                let bx = (boundbox?.origin.x)! + (boundbox?.width)!/2
                                                let by = (boundbox?.origin.y)! + (boundbox?.height)!/2
                                                let angle0 = atan2(by - self.expandCenter.y, bx - self.expandCenter.x)
                                                let angle1 = atan2(self.mainButton.center.y - self.expandCenter.y , self.mainButton.center.x - self.expandCenter.x)
                                                self.applyArrowRotation(angle0: angle0, angle1: angle1)
                                        for sub in self.expandButtons{
                                            if sub.index != i && sub.textLayer.fontSize == 35{
                                                self.expandButtons[sub.index].applyPannedTextLayer(flag: 1)
                                            }
                                        }
                                    }else if self.currentTextLayerIndex == i{
                                        // panning but still in same arc
                                        let boundbox = self.arrowShapeLayer.path?.boundingBox
                                            let bx = (boundbox?.origin.x)! + (boundbox?.width)!/2
                                            let by = (boundbox?.origin.y)! + (boundbox?.height)!/2
                                                                    let angle0 = atan2(by - self.expandCenter.y, bx - self.expandCenter.x)
                                            let angle1 = atan2(self.mainButton.center.y - self.expandCenter.y , self.mainButton.center.x - self.expandCenter.x)
                                            self.applyArrowRotation(angle0: angle0, angle1: angle1)
                                        }
                                }
                            }else{
                                // moving from a subarc to the center
                                if self.currentTextLayerIndex != -1{
                                    self.expandButtons[self.currentTextLayerIndex].applyPannedTextLayer(flag: 1)
                                    self.currentTextLayerIndex = -1
                                            self.setupArrowShapeLayer(
                                        angle: atan2(self.mainButton.center.y - self.expandCenter.y ,
                                                     self.mainButton.center.x - self.expandCenter.x).toDegrees())
                                    self.applyArrowAnimation(flag: 1)
                                }
                            }
                        }
                    case .ended:
                        self.setupArrowShapeLayer(angle: atan2(self.mainButton.center.y - self.expandCenter.y , self.mainButton.center.x - self.expandCenter.x).toDegrees())
                        self.applyArrowAnimation(flag: 1)
                        UIView.animate(withDuration: 0.1, animations: {
                            self.mainButton.center = self.expandCenter
                        })
                        self.currentTextLayerIndex = -1
                        for s in self.expandButtons{
                            s.resetFontSize()
                        }
                        
                        self.toggleBoundaries(flag: 1)
                        self.state = 1
                    default:
                        print("panning default")
                    }
                }
            }).disposed(by: disposeBag)
        
        // rxswift tap gesture subscriber
        mainButton.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { gesture in
                if let gesture = gesture as? UITapGestureRecognizer{
                    if gesture.state == .recognized{
                        // currently unexpanded
                        if self.state == 0{
                            self.mainButton.isUserInteractionEnabled = false
                            self.isUserInteractionEnabled = false
                            self.delay(Double(self.animationOffset + self.expandButtons[0].animDuration ), closure: {
                                self.mainButton.isUserInteractionEnabled = true
                                self.isUserInteractionEnabled = true
                                self.state = 1
                            })
                            
                            self.frame = self.expandedFrame
                            self.mainButton.center = self.expandCenter
                            var i:CGFloat = 0.0
                            self.layer.addSublayer(self.outerCircleShapeLayer)
                            self.applyOuterCircleAnimation(flag: 0)
                            for b in self.expandButtons{
                                self.delay(Double(i), closure: {
                                    // set the CATextLayer to the cente rof the now bigger and expanded view
                                    self.layer.addSublayer(b.shapeLayer)
                                    self.layer.addSublayer(b.textLayer)
                                    b.applyShapeLayer(flag: 0 )
                                    b.applyTextLayer(flag: 0)
                                })
                                i += ( self.animationOffset / CGFloat(self.titles.count) )
                            }
                        }else if self.state == 1{
                            // currently expanded, will transition to contracted
                            self.mainButton.isUserInteractionEnabled = false
                            self.isUserInteractionEnabled = false
                            self.delay(Double(self.expandButtons[0].animDuration + self.animationOffset), closure: {
                                self.mainButton.isUserInteractionEnabled = true
                                self.isUserInteractionEnabled = true
                                self.state = 0
                            })
                            self.frame = self.orgFrame
                            self.mainButton.center = self.orgCenter
                            
                            for b in self.expandButtons{
                                b.applyTextLayer(flag: 1)
                                b.applyShapeLayer(flag: 1)
                            }
                            self.applyOuterCircleAnimation(flag: 1)
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyArrowAnimation(flag: Int){
        let animation = CABasicAnimation(keyPath: "path")
        if flag == 0{
            arrowShapeLayer.path = preArrowPath.cgPath
            animation.fromValue = preArrowPath.cgPath
            animation.toValue = postArrowPath.cgPath
        }else{
            arrowShapeLayer.path = postArrowPath.cgPath
            animation.fromValue = postArrowPath.cgPath
            animation.toValue = preArrowPath.cgPath
        }
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = 1
        
        let animation1 = CABasicAnimation(keyPath: "fillColor")
        
        if flag == 0{
            animation1.fromValue = UIColor.clear.cgColor
            animation1.toValue = UIColor.black.cgColor
            self.arrowShapeLayer.fillColor = UIColor.black.cgColor
        }else{
            animation1.fromValue = UIColor.black.cgColor
            animation1.toValue = UIColor.clear.cgColor
            self.arrowShapeLayer.fillColor = UIColor.clear.cgColor
        }
        animation1.fillMode = kCAFillModeForwards
        
        let group = CAAnimationGroup()
        group.delegate = self
        group.animations = NSArray(arrayLiteral: animation1, animation) as? [CAAnimation]
        group.isRemovedOnCompletion = false
        group.duration = CFTimeInterval(0.1)
        group.fillMode = kCAFillModeForwards
        
        if flag == 0{
            arrowShapeLayer.add(group, forKey: "arrowOut")
        }else{
            arrowShapeLayer.add(group, forKey: "arrowIn")
        }
    }
    
    func applyArrowRotation(angle0: CGFloat, angle1: CGFloat){
        var angle: CGFloat = 0.0
        angle = angle0 - angle1        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        let center = CGPoint(x: self.arrowShapeLayer.position.x, y: self.arrowShapeLayer.position.y )
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, self.expandCenter.x - (center.x), self.expandCenter.y - (center.y), 0.0)
        transform = CATransform3DRotate(transform, angle, 0.0, 0.0, -1.0)
        transform = CATransform3DTranslate(transform, (center.x) - self.expandCenter.x, center.y - self.expandCenter.y, 0.0)
        self.arrowShapeLayer.transform = transform
        CATransaction.commit()
    }
    
    func applyOuterCircleAnimation(flag: Int){
        outerCircleShapeLayer.strokeColor = UIColor.white.cgColor
        outerCircleShapeLayer.lineWidth = 1
        
        let animation = CABasicAnimation(keyPath: "path")
        if flag == 0{
            outerCircleShapeLayer.path = preExpandedPath.cgPath
            animation.fromValue = preExpandedPath.cgPath
            animation.toValue = outerCirclePath.cgPath
        }else{
            animation.fromValue = conOuterCirclePath.cgPath
            animation.toValue = postContractedPath.cgPath
        }
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = 1

        let animation1 = CABasicAnimation(keyPath: "fillColor")
        
        if flag == 0{
            animation1.fromValue = UIColor.clear.cgColor
            animation1.toValue = UIColor.black.cgColor
            self.outerCircleShapeLayer.fillColor = UIColor.black.cgColor
        }else{
            animation1.fromValue = UIColor.black.cgColor
            animation1.toValue = UIColor.clear.cgColor
            self.outerCircleShapeLayer.fillColor = UIColor.clear.cgColor
        }
        animation1.fillMode = kCAFillModeForwards
        
        let group = CAAnimationGroup()
        group.delegate = self
        group.animations = NSArray(arrayLiteral: animation1, animation) as? [CAAnimation]
        group.isRemovedOnCompletion = false
        group.duration = CFTimeInterval(self.animDuration + self.expandButtons[0].animDuration)
        group.fillMode = kCAFillModeForwards
        
        if flag == 0{
            outerCircleShapeLayer.add(group, forKey: "outerCircle0")
        }else{
            outerCircleShapeLayer.add(group, forKey: "outerCircle1")
        }
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        if outerCircleShapeLayer.animation(forKey: "outerCircle") == anim{
        }
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if outerCircleShapeLayer.animation(forKey: "outerCircle0") == anim{
            outerCircleShapeLayer.path = outerCirclePath.cgPath
            self.outerCircleShapeLayer.removeAllAnimations()
        }else if outerCircleShapeLayer.animation(forKey: "outerCircle1") == anim{
            self.outerCircleShapeLayer.removeFromSuperlayer()
            self.outerCircleShapeLayer.removeAllAnimations()
        }else if self.arrowShapeLayer.animation(forKey: "arrowIn") == anim{
            self.arrowShapeLayer.removeFromSuperlayer()
            self.arrowShapeLayer.removeAllAnimations()
        }

    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        //print("Boundary contact occurred - \(String(describing: identifier)) at point ", p.x, "," , p.y)
        item.center = self.lastCenter
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        //print("Boundary contact occurred - \(String(describing: identifier)) at point ")
        item.center = self.lastCenter

    }
    
    func translatePoint(current:CGPoint, angle:CGFloat, rad: CGFloat) -> CGPoint{
        var x: CGFloat = current.x + rad*cos(angle.toRadians())
        var y: CGFloat = current.y + rad*sin(angle.toRadians())
        x = x.rounded(.down)
        y = y.rounded(.down)
        return CGPoint(x: x, y: y)
    }
}

extension UIGestureRecognizer{
    func cancel(){
    }
}




