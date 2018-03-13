

import UIKit

class ButtonPanGestureRecognizer:UIPanGestureRecognizer {
    func end(){
        self.state = .ended
    }
    
}

