import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';

enum ActorOrientation { Horizontal, Vertical }
enum ActorAdvancingDirection { LeftToRight, RightToLeft }

class PanFlareActor extends StatefulWidget {
  final double width;
  final double height;

  /// Orientation that the actor will listen for advancing gestures.
  final ActorOrientation orientation;

  /// The direction to swipe for the animation to advance
  final ActorAdvancingDirection direction;

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
      this.orientation = ActorOrientation.Horizontal,
      this.direction = ActorAdvancingDirection.LeftToRight,
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
          pageWidth: widget.width,
          animationName: widget.animationName,
          direction: widget.direction,
          orientation: widget.orientation);
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
              var localPosition = (context.findRenderObject() as RenderBox)
                  .globalToLocal(tapInfo.globalPosition);
              // swipeController.updateSwipeDelta(tapInfo.delta.dx);
              swipeController.updateSwipePosition(localPosition, tapInfo.delta);
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
  final double _pageWidth;
  final String _animationName;
  final ActorOrientation _orientation;
  ActorAdvancingDirection _direction;

  ActorAnimation _transition;
  double _speed = 0.5;
  double _relativeSwipePosition = 0.0;
  double _timeToApply = 0.0;
  double _previousTimeToApply = 0.0;
  double _deltaXSinceInteraction = 0.0;
  bool _advancingThreshold = false;
  bool animationAtEnd = false;

  bool _interacting = false;

  SwipeAdvanceController(
      {@required double pageWidth,
      @required String animationName,
      @required ActorAdvancingDirection direction,
      @required ActorOrientation orientation})
      : _animationName = animationName,
        _pageWidth = pageWidth,
        _direction = direction,
        _orientation = orientation {
    if (direction == ActorAdvancingDirection.RightToLeft) {
      // _deltaXSinceInteraction = _pageWidth;
    }
  }

  double get swipePosition => _transition.duration * _relativeSwipePosition;

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    // _currentTime += elapsed * _speed;
    if (_interacting) {
      _timeToApply = swipePosition;
    } else if (_advancingThreshold && !_interacting) {
      if (_timeToApply < _transition.duration) {
        _timeToApply += (elapsed * _speed) % _transition.duration;
      } else {
        if (!animationAtEnd) {
          animationAtEnd = true;
          _advancingThreshold = false;
          // if (_direction == ActorAdvancingDirection.RightToLeft) {
          //   _direction = ActorAdvancingDirection.LeftToRight;
          // } else if (_direction == ActorAdvancingDirection.LeftToRight) {
          //   _direction = ActorAdvancingDirection.RightToLeft;
          // }
          _deltaXSinceInteraction = _pageWidth;
          print('Animation@end!_deltaXSinceInteraction: $_deltaXSinceInteraction');
        }
      }
    } else if (!animationAtEnd) {
      if (_timeToApply > 0) {
        // Reverse the animation
        _timeToApply -= 0.05;
      } else {
        if (!animationAtEnd) {
          animationAtEnd = true;
          // _deltaXSinceInteraction = _pageWidth;
          _advancingThreshold = false;
          // if (_direction == ActorAdvancingDirection.RightToLeft) {
          //   _direction = ActorAdvancingDirection.LeftToRight;
          // } else if (_direction == ActorAdvancingDirection.LeftToRight) {
          //   _direction = ActorAdvancingDirection.RightToLeft;
          // }

          print('Animation back at staer! Swap Direction: $_direction');
        }
      }
    }

    if (_interacting) {
      // print('Advance.\ntransition_duration: ${_transition.duration}\ntransitionPosition: $transitionPosition\ntimeToApply: $timeToApply');
    }

    if (_previousTimeToApply != _timeToApply) {
      print('swipePosition: $swipePosition, _timeToApply: $_timeToApply');
      _transition.apply(_timeToApply, artboard, 1.0);
    }

    _previousTimeToApply = _timeToApply;
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _transition = artboard.getAnimation(_animationName);
  }

  void updateSwipePosition(Offset touchPosition, Offset touchDelta) {
    var insideBounds = touchPosition.dx > 0 &&
        touchPosition.dx < _pageWidth &&
        touchPosition.dy > 0;

    if (insideBounds) {
      double relativePosition;
      double relativeBasedOnTotalDelta;

      var deltaX = touchDelta.dx;
        if (_direction == ActorAdvancingDirection.RightToLeft) {
          deltaX *= -1;
        }

      _deltaXSinceInteraction += deltaX;

      // _deltaXSinceInteraction *= -1;

      _advancingThreshold = _deltaXSinceInteraction > 100.0;

      if (_direction == ActorAdvancingDirection.RightToLeft) {
        relativeBasedOnTotalDelta = _deltaXSinceInteraction / _pageWidth;
      } else {
        relativeBasedOnTotalDelta =
            1.0 - (_deltaXSinceInteraction / _pageWidth);
      }

      _relativeSwipePosition = relativeBasedOnTotalDelta;
      print(
          'relativeBasedOnTotalDelta: $relativeBasedOnTotalDelta ,_deltaXSinceInteraction: $_deltaXSinceInteraction');
    }
  }

  void updateSwipeDelta(double swipeDeltaX) {
    swipeDeltaX *= -1;
    _deltaXSinceInteraction += swipeDeltaX;

    if (_deltaXSinceInteraction < 0) {
      _deltaXSinceInteraction = 0;
    }

    _relativeSwipePosition =
        1.0 - (_pageWidth / (_pageWidth + _deltaXSinceInteraction));

    // Handle forward animation first
    if (!animationAtEnd) {
      _advancingThreshold = _deltaXSinceInteraction > 45.0;
      print(
          'Update swipe delta\nthresholdReached: $_advancingThreshold\n_relativeSwipePosition:$_relativeSwipePosition \npageWidth: $_pageWidth\nswipeDeltaX:$swipeDeltaX\ndeltaXSinceInteraction: $_deltaXSinceInteraction');
    } else {
      _advancingThreshold = _deltaXSinceInteraction < 100.0;
    }
  }

  void interactionStarted() {
    print('interactionStarted');
    _interacting = true;

    var hasReachedAnimationEnd = _timeToApply == _transition.duration;
    animationAtEnd = hasReachedAnimationEnd && !animationAtEnd;

    print(
        '**_timeToApply:$_timeToApply,_transition.duration:${_transition.duration} Set animation @ end: $animationAtEnd, pageWidth: $_deltaXSinceInteraction ****');
  }

  void interactionEnded() {
    print('interactionEnded\n');
    _interacting = false;
    // _timeToApply = 0;
    // _relativeSwipePosition = 0;
    // _deltaXSinceInteraction = 0;

    // _transition.triggerEvents(components, fromTime, toTime, triggerEvents)
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    // TODO: implement setViewTransform
  }
}
