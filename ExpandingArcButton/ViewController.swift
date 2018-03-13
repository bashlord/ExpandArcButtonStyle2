//
//  ViewController.swift
//  ExpandingArcButton
//
//  Created by John Jin Woong Kim on 2/13/18.
//  Copyright © 2018 John Jin Woong Kim. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxGesture

class ViewController: UIViewController {
    var expandingArcButton : ExpandingArcButton!
    var buttonWidth: CGFloat = 60
    var buttonOrg: CGFloat = 30
    // 2-3 = 0.5 4-5 = 0.6 6 = 0.65
    var titles = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let keyFrame = UIScreen.main.bounds
        let x = keyFrame.width/2
        // Do any additional setup after loading the view, typically from a nib.
        expandingArcButton = ExpandingArcButton(
            frame: CGRect(x: x-buttonOrg, y: x-buttonOrg, width: buttonWidth, height: buttonWidth ),
            titles: titles)
        view.addSubview(expandingArcButton)

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // view.addSubview(expandingArcButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * CGFloat(Double.pi) / 180.0
    }
    
    func toDegrees() -> CGFloat{
        return self * 180 / CGFloat(Double.pi)
    }
}

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func removeAllConstraints() {
        for c in self.constraints{
            
            self.removeConstraint(c)
        }
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

extension UIColor {
    static func rgb(_ red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}
