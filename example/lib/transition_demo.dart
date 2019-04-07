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

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    if (swipeController == null) {
      swipeController = SwipeAdvanceController(pageWidth: screenWidth);
    }
    return Scaffold(
      backgroundColor: Colors.red,
      body: GestureDetector(
        onHorizontalDragStart: (tapInfo) {
          swipeController.interactionStarted();
        },
        onHorizontalDragUpdate: (tapInfo) {
          // print('onHorizontalDragUpdate');
          swipeController.updateSwipeDelta(tapInfo.delta.dx);
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
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: FlareActor(
            "assets/tutorial-transition.flr",
            animation: 'Untitled',
            controller: swipeController,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
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
    if (_interacting && !thresholdReached) {
      timeToApply = transitionPosition;
    } else if (thresholdReached) {
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
    _transition = artboard.getAnimation('Untitled');
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
