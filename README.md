# Smart Flare - Customizable Interactable Flare actors

Interactive capabilities for larger Flare animations.

## Installation

Add smart_flare as dependency to your pubspec file.

```
smart_flare: any
```

## Example

Here is [an example](https://youtu.be/fZuLh-oc5Ao) of how to use the functionality within this project.

## Usage

If you want to just play a normal animation I would recommend using [Flare's Flutter Package](https://pub.dartlang.org/packages/flare_flutter). This is for animations that you want some interaction on.

This is used the same as a Flare Actor is used with some additional properties. To use this actor at a minimum level you have to supply width, heigh and the filename to the animation. This will draw the animation on screen without playing anything.

```dart
import 'package:flutter/material.dart';
import 'package:smart_flare/smart_flare.dart';

class FlareDemo extends StatefulWidget {
  @override
  _FlareDemoState createState() => _FlareDemoState();
}

class _FlareDemoState extends State<FlareDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        body: SmartFlareActor(
            width: 295.0,
            height: 251.0,
            filename: 'assets/button-animation.flr'));
  }
}
```

Additionally you can then give it a starting animation for it to play something.

```dart
SmartFlareActor(
    width: 295.0,
    height: 251.0,
    filename: 'assets/button-animation.flr',
    startingAnimation: 'deactivate')
```

### Interactive Areas

The main feature of this package is to provide it's interactive nature. You can supply the actor with ActiveArea's which looks as follows.

```dart
class ActiveArea {
  final Rect area;
  final String animationName;
  final List<String> animationsToCycle;
  final Function onAreaTapped;
  final List<String> guardComingFrom;
  final bool debugArea;
  ...
}
```

Each active area requires an area and either an animationName to play when tapped, or a list of animationsToCycle through when tapped. You can also set debugArea to true and the touch area will display over the animation so you can see if your calculations are correct.

```dart
ActiveArea(
    debugArea: true,
    area: Rect.fromLTWH(thirdOfWidth*2, 0, thirdOfWidth, animationHeight / 2),
    animationName: 'image_tapped',
   ),
```

Areas can also be defined using relative placements.

```dart
 RelativeActiveArea(
    // from (0,0) with a width 35% of animation width and 50% of height
    area: Rect.fromLTRB(0, 0, 0.35, 0.5),
    animationName: 'camera_tapped'
),
```

#### Area Callbacks

If you want to perform an action when something is tapped, which you probably do you can supply a function to onAreaTapped and run your code in there.

```dart
ActiveArea(
    debugArea: true,
    area: Rect.fromLTWH(thirdOfWidth*2, 0, thirdOfWidth, animationHeight / 2),
    animationName: 'image_tapped',
    onAreaTapped: () {
      print('Area Tapped!');
    }
   )
```

#### Guarding against animation

If you want to make sure that an animation does not play after another you can supply it with a list of animations to guard against. This means that, the area animation you want to play, WILL NOT PLAY of the **last played** animation is contained in the guardComingFrom list. _GuardGoingTo coming in next release._

```dart
ActiveArea(
          debugArea: true,
          area: Rect.fromLTWH(thirdOfWidth*2, 0, thirdOfWidth, animationHeight / 2),
          guardComingFrom: ['deactivate'],
          animationName: 'image_tapped',
          onAreaTapped: () {
            print('Image tapped!');
          }),
```

And that's it!

### Specialized Actors

#### CycleFlareActor

Given a list of animations this actor will play one after the other as it is tapped.

```dart
CycleFlareActor(
    width: animationWidth,
    height: animationHeight,
    filename: 'assets/button-animation.flr',
    animations: ['deactivate', 'activate'],
  )
```

#### PanFlareActor

Given an open and close animation this actor will play those animations when panned across it. It plays the open animation in the `direction` supplied. If no close animation is provided the open animation will be reversed when swiping in the "closing" direction.

_Currently only supports horizontal panning. Vertical panning on the way._

```dart
PanFlareActor(
    width: 135.0,
    height: screenSize.height,
    filename: "assets/tutorial-transition.flr",
    openAnimation: 'drawer-open',
    closeAnimation: 'drawer-close',
    direction: ActorAdvancingDirection.RightToLeft,
    threshold: 60.0,
    reverseOnRelease: true,
    activeAreas: [
      RelativePanArea(
        area: Rect.fromLTWH(0, 0.7, 1.0, 0.3),
        debugArea: true
      )
    ],
  )
```

**threshold** (optional): Total number of pixels to swipe to play the animation until the end when released.

**reverseOnRelease** (optional. Default true): Tells the actor to reverse the animation when the user stops interacting with the actor and the threshold is not reached.

**activeAreas** (required): You have to supply at least one relative pan area

## Contribution

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request.
