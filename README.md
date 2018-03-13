# ExpandArcButtonStyle2
# ExpandArcButtonStyle2
https://www.youtube.com/watch?v=0C0ULxN_mIA
https://youtu.be/kLedwWFnQMk

<img width="356" alt="screen shot 2018-03-13 at 4 34 01 pm" src="https://user-images.githubusercontent.com/11773312/37375366-78d38c3a-26dc-11e8-9f38-f7dbcf378c0a.png"><img width="359" alt="screen shot 2018-03-13 at 4 34 19 pm" src="https://user-images.githubusercontent.com/11773312/37375367-78ec1d54-26dc-11e8-94c9-abc00d0cfdd8.png"><img width="359" alt="screen shot 2018-03-13 at 4 34 26 pm" src="https://user-images.githubusercontent.com/11773312/37375368-79049bea-26dc-11e8-99fe-69b67743ed09.png">


Wanted to make the chat wheel from Dota 2, so I did.  Follows a similar template as ExpandArcButton, but uses UICollisionBehavior, CATransformm3DRotations, RxSwift, and much much more.

Note: I did have to tweak the RxSwift RxGesture Pan file in the framework.  UIGestureRecognizerSubclass needs to be imported via umbrella header file.

init(frame:CGRect, titles :[String])

The general structure begins with a simple UIView subclass at its foundation, the ExpandingArcButton (excuse the semantics i.e. calling a UIView a button).  This will essentially act as the bounding box of the entire bananza, expanding and contracting when need be.  A UIButton, one I like to call mainButton, acts as the primary controller as interacting with it mostly results in a state change.  

The initial state starts with just the ExpandingArcButton View with its mainButton subview.  Once a tap has been recognized, 
the initializer has already setup CATextLayers & CAShapeLayers for each respective string in titles.  The CAShapelayers act as 
circle partitioned coordinate planes which represent a single title's "domain".  The CATextLayers have auto-calculating sizing and are simply placeholders.  All of this is encapsulated in a UICollisionBehavior/Boundary.  

The 2nd state is the mainButton in the center with all these things repositioning/resizing themselves.  Now, mainButton's tap recognition contracts the views & mainButton has now gained the ability to panGesture.

The 3rd state is the panning state, where mainButton is in the process of being dragged around.  Collisions keep mainButton 
bounded within the given area, but dragging outside the bounding circle or letting go will bring the panGesture to its end state.  
