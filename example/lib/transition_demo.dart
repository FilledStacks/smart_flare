import 'dart:async';
import 'dart:math' as math;

import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

class TransitionDemo extends StatefulWidget {
  @override
  _TransitionDemoState createState() => _TransitionDemoState();
}

class _TransitionDemoState extends State<TransitionDemo> {
  FlareControls controls = FlareControls();
  SwipeAdvanceController swipeController;
  CustomPageController pageController;

  Map<int, Color> colorMap = {
    0: Colors.red,
    1: Colors.green,
    2: Colors.blue,
    3: Colors.yellow,
    4: Colors.pink,
  };

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    if (swipeController == null) {
      swipeController = SwipeAdvanceController(pageWidth: screenWidth);
      pageController = CustomPageController();
    }
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (tapInfo) {
          swipeController.interactionStarted();
        },
        onHorizontalDragUpdate: (tapInfo) {
          // print('onHorizontalDragUpdate');
          swipeController.updateSwipeDelta(tapInfo.delta.dx);
          pageController.updateOffset(tapInfo.delta.dx);
        },
        onHorizontalDragEnd: (tapInfo) {
          // print('DragEnd');
          swipeController.interactionEnded();
        },
        onTapDown: (tapInfo) {
          // print('TapDown');
          swipeController.interactionStarted();
        },
        onTap: () {
          // print('TapUp');
          swipeController.interactionEnded();
        },
        onTapCancel: () {
          // print('TapCanel');
          // swipeController.interactionEnded();
        },
        child: AbsorbPointer(
          child: PageView.builder(
            itemCount: 5,
            controller: pageController,
            itemBuilder: (buildContext, index) {
              return Container(
                  color: colorMap[index],
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: FlareActor(
                    "assets/tutorial-transition.flr",
                    controller: swipeController,
                    fit: BoxFit.fill,
                  ));
            },
          ),
        ),
      ),
    );
  }

  void onPageScroll() {}
}

class CustomPageController extends PageController {
  double _internalXOffset = 0.0;

  @override
  double get offset => _internalXOffset;

  void updateOffset(double dragChange) {
    
    dragChange *= -1;
    _internalXOffset += dragChange;
    print('Updated offset: $_internalXOffset');
    this.animateTo(offset, duration: Duration(milliseconds: 50,), curve: ElasticInCurve());
  }
}

class SwipeAdvanceController extends FlareController {
  final double pageWidth;

  ActorAnimation _transition;
  double _currentTime = 0.0;
  double _endTime = 30.0;
  double _speed = 0.5;
  double _relativeSwipePosition = 0.0;
  double _lastInteractivePosition = 0.0;
  double timeToApply = 0.0;
  double deltaXSinceInteraction = 0.0;
  bool thresholdReached = false;

  bool _interacting = false;

  SwipeAdvanceController({@required this.pageWidth});

  double get transitionPosition =>
      _transition.duration * _relativeSwipePosition;

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    // _currentTime += elapsed * _speed;
    if (_interacting) {
      timeToApply = transitionPosition;
    } else if (thresholdReached && !_interacting) {
      timeToApply += (elapsed * _speed) % _transition.duration;
    } else {
      if (timeToApply > 0) {
        // Reverse the animation
        timeToApply -= 0.05;
      }
    }

    if (_interacting) {
      // print('Advance.\ntransition_duration: ${_transition.duration}\ntransitionPosition: $transitionPosition\ntimeToApply: $timeToApply');
    }

    _transition.apply(timeToApply, artboard, 1.0);
    // TODO: implement advance
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _transition = artboard.getAnimation('transition-3');
  }

  void updateSwiptePosition(double relativeSwipePosition) {
    _relativeSwipePosition = relativeSwipePosition;
  }

  void updateSwipeDelta(double swipeDeltaX) {
    swipeDeltaX *= -1;

    deltaXSinceInteraction += swipeDeltaX;

    if (deltaXSinceInteraction < 0) {
      deltaXSinceInteraction = 0;
    }

    _relativeSwipePosition =
        1.0 - (pageWidth / (pageWidth + deltaXSinceInteraction));

    thresholdReached = deltaXSinceInteraction > 45.0;
    print(
        'Update swipe delta\nthresholdReached: $thresholdReached\n_relativeSwipePosition:$_relativeSwipePosition \npageWidth: $pageWidth\nswipeDeltaX:$swipeDeltaX\ndeltaXSinceInteraction: $deltaXSinceInteraction');
  }

  void interactionStarted() {
    print('interactionStarted\n\n\n\n');
    _interacting = true;
  }

  void interactionEnded() {
    print('interactionEnded\n\n\n\n');
    _interacting = false;
    deltaXSinceInteraction = 0.0;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    // TODO: implement setViewTransform
  }
}

class CustomSimulation extends Simulation {
  final double initPosition;
  final double velocity;

  CustomSimulation({@required this.initPosition, @required this.velocity});

  @override
  double dx(double time) {
    return velocity;
  }

  @override
  bool isDone(double time) {
    // TODO: implement isDone
    return false;
  }

  @override
  double x(double time) {
    var max =
        math.max(math.min(initPosition, 0.0), initPosition + velocity * time);
    print(max.toString());
    return max;
  }
}

class CustomScrollPhysics extends ScrollPhysics {
  @override
  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    // TODO: implement applyTo
    return CustomScrollPhysics();
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // TODO: implement createBallisticSimulation
    return CustomSimulation(initPosition: position.pixels, velocity: velocity);
  }
}
