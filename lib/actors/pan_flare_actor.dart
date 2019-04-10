import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';

enum PanDirection { Horizontal, Vertical }

class PanFlareActor extends StatefulWidget {
  final double width;
  final double height;

  /// Direction that the actor will listen for advancing gestures.
  final PanDirection panDirection;

  final String animationFilePath;

  /// The name of the animation that has to be advanced while panning
  final String animationName;

  /// The threshold in percentage for animation to complete when gesture is finished.
  ///
  /// When this threshold is passed and the pan/drag gesture ends the animation will play until it's complete
  final double thresholdPercentage;

  /// The threshold in pixels for animation to complete when gesture is finished.
  ///
  /// When this threshold is passed and the pan/drag gesture ends the animation will play until it's complete
  final double threshold;

  /// When true the animation will reverse on the release of the gesture if threshold is not reached.
  final bool reverseOnRelease;

  const PanFlareActor(
      {@required this.width,
      @required this.height,
      this.panDirection = PanDirection.Horizontal,
      @required this.animationFilePath,
      @required this.animationName,
      this.thresholdPercentage = 0.5,
      this.threshold = 200.0,
      this.reverseOnRelease = true});

  @override
  _PanFlareActorState createState() => _PanFlareActorState();
}

class _PanFlareActorState extends State<PanFlareActor> {
  SwipeAdvanceController swipeController;

  @override
  void initState() {
    if (swipeController == null) {
      swipeController = SwipeAdvanceController(
          pageWidth: widget.width, animationName: widget.animationName);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
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
            child: FlareActor(
              widget.animationFilePath,
              controller: swipeController,
              fit: BoxFit.contain,
            )));
  }
}

class SwipeAdvanceController extends FlareController {
  final double pageWidth;
  final String animationName;

  ActorAnimation _transition;
  double _speed = 0.5;
  double _relativeSwipePosition = 0.0;
  double timeToApply = 0.0;
  double deltaXSinceInteraction = 0.0;
  bool thresholdReached = false;

  bool _interacting = false;

  SwipeAdvanceController(
      {@required this.pageWidth, @required this.animationName});

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

    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _transition = artboard.getAnimation(animationName);
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
