import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'dart:math';

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
              var localPosition = (context.findRenderObject() as RenderBox)
                  .globalToLocal(tapInfo.globalPosition);
              swipeController.updateSwipePosition(localPosition, tapInfo.delta);
            },
            onHorizontalDragEnd: (tapInfo) {
              swipeController.interactionEnded();
            },
            onHorizontalDragCancel: () {
              // swipeController.interactionEnded();
            },
            child: FlareActor(
              widget.animationFilePath,
              controller: swipeController,
              fit: BoxFit.contain,
            )));
  }
}

enum _AnimationOrigin { Beginning, End }

class SwipeAdvanceController extends FlareController {
  final double _pageWidth;
  final String _animationName;
  final ActorOrientation _orientation;
  ActorAdvancingDirection _direction;

  _AnimationOrigin _currentAnimationOrigin = _AnimationOrigin.Beginning;

  ActorAnimation _animation;
  double _speed = 0.5;
  double _previousTimeToApply = 0.0;
  double _deltaXSinceInteraction = 0.0;
  double animationPosition = 0.0;
  bool _thresholdReached = false;
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

  double get swipePosition => _animation.duration * animationPosition;

  double get _animationTimeToApply => _animation.duration * animationPosition;

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (!_interacting) {
      if (_thresholdReached) {
        // If we've released the drag and has reached the threshold

        // If we're coming from the beginning we want to advance the animation until the end
        var comingFromBeginning =
            _currentAnimationOrigin == _AnimationOrigin.Beginning;
        if (comingFromBeginning && animationPosition < 1) {
          // advance until we get to the end of the animation
          animationPosition += (elapsed * _speed) % _animation.duration;
        } else if (!comingFromBeginning && animationPosition > 0) {
          animationPosition -= (elapsed * _speed) % _animation.duration;
        } else {
          // When we get to the end of the animation we want to indicate that and set some values.
          // Here we prapare for the swipe back
          if (!animationAtEnd) {
            // If we are advancing towards the end of the animtion and we're coming from beginning
            if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
              // We want to indicate that we are now at the end of the animation.
              _currentAnimationOrigin = _AnimationOrigin.End;
              // We also want to set the delta interaction equal to the pagewidth
              _deltaXSinceInteraction = _pageWidth;
            } else {
              // If we're coming from the end, We want to indicate that we are now at the beginning of the animation.
              _currentAnimationOrigin = _AnimationOrigin.Beginning;
              // We want our delta Since interaction to reflect the same
              _deltaXSinceInteraction = 0;
            }

            animationAtEnd = true;
            _thresholdReached = false;
            // Set the _deltaXSinceInteraction to the full width of the actor so that swiping back
            // Will decrease the value vausing the animation to reverse.
            print(
                'Animation@end!_deltaXSinceInteraction: $_deltaXSinceInteraction, _currentAnimationOrigin: $_currentAnimationOrigin');
          }
        }
      } else if (!animationAtEnd) {
        // If the animation has not ended and we haven't reached the threshold yet
        var reverseAnimation = _currentAnimationOrigin == _AnimationOrigin.Beginning;
        var reverseValue = max(animationPosition * 0.1, 0.005);
        if (reverseAnimation && animationPosition > 0) {
          animationPosition -= reverseValue;
          print('ReverseAnimation GO BACK TO BEGINNING !! $animationPosition');
        } else if (!reverseAnimation && animationPosition < 1) {
          animationPosition += reverseValue;
          print('ReverseAnimation GO TO END !! $animationPosition');
        } else {
          // If we're reversing the animation and we get to the end we want to set
          // the delta interaction back to 0 so that we can start from the beginning
          if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
            _deltaXSinceInteraction = 0;
          } else {
            // If we're reversing back to the end then we want to set the
            // deltaXSinceInteraction equal to the pageWidth so we can play animation from the end.
            _deltaXSinceInteraction = _pageWidth;
          }

          animationAtEnd = true;
          _thresholdReached = false;
          print(
              'Animation@end!_deltaXSinceInteraction: $_deltaXSinceInteraction, _currentAnimationOrigin: $_currentAnimationOrigin');
        }
      }
    }

    if (_interacting) {
      // print('Advance.\ntransition_duration: ${_transition.duration}\ntransitionPosition: $transitionPosition\ntimeToApply: $timeToApply');
    }

    if (_previousTimeToApply != _animationTimeToApply) {
      print('swipePosition: $swipePosition, _timeToApply: $animationPosition');
      _animation.apply(_animationTimeToApply, artboard, 1.0);
    }

    _previousTimeToApply = _animationTimeToApply;
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _animation = artboard.getAnimation(_animationName);
  }

  void updateSwipePosition(Offset touchPosition, Offset touchDelta) {
    animationAtEnd = false;

    var insideBounds = touchPosition.dx > 0 &&
        touchPosition.dx < _pageWidth &&
        touchPosition.dy > 0;

    if (insideBounds) {
      var deltaX = touchDelta.dx;
      if (_direction == ActorAdvancingDirection.RightToLeft) {
        deltaX *= -1;
      }

      print(
          'BEFORE: AnimationPosition: $animationPosition, _deltaXSinceInteraction: $_deltaXSinceInteraction, deltaX (Norm): $deltaX, deltaX (Ridge): ${touchDelta.dx}');
      _deltaXSinceInteraction += deltaX;

      if (_deltaXSinceInteraction > _pageWidth) {
        _deltaXSinceInteraction = _pageWidth;
      }
      if (_deltaXSinceInteraction < 0) {
        _deltaXSinceInteraction = 0;
      }

      if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
        _thresholdReached = _deltaXSinceInteraction > 100.0;
      } else {
        _thresholdReached = _deltaXSinceInteraction < 100.0;
      }

      if (_direction == ActorAdvancingDirection.RightToLeft) {
        animationPosition = _deltaXSinceInteraction / _pageWidth;
      } else {
        animationPosition = 1.0 - (_deltaXSinceInteraction / _pageWidth);
      }

      print(
          'AFTER: AnimationPosition: $animationPosition, _deltaXSinceInteraction: $_deltaXSinceInteraction, deltaX (Norm): $deltaX, deltaX (Ridge): ${touchDelta.dx}');

      // print(
      //     'relativeBasedOnTotalDelta: $relativeBasedOnTotalDelta ,_deltaXSinceInteraction: $_deltaXSinceInteraction, _thresholdReached: $_thresholdReached');
    }
  }

  void updateSwipeDelta(double swipeDeltaX) {
    swipeDeltaX *= -1;
    _deltaXSinceInteraction += swipeDeltaX;

    if (_deltaXSinceInteraction < 0) {
      _deltaXSinceInteraction = 0;
    }

    // Handle forward animation first
    if (!animationAtEnd) {
      _thresholdReached = _deltaXSinceInteraction > 45.0;
      print(
          'Update swipe delta\nthresholdReached: $_thresholdReached\n\npageWidth: $_pageWidth\nswipeDeltaX:$swipeDeltaX\ndeltaXSinceInteraction: $_deltaXSinceInteraction');
    } else {
      _thresholdReached = _deltaXSinceInteraction < 100.0;
    }
  }

  void interactionStarted() {
    print('interactionStarted');

    _interacting = true;
    // Indicate that the animation is not at the end as soon as we start
  }

  void interactionEnded() {
    print('interactionEnded\n');
    _interacting = false;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    // TODO: implement setViewTransform
  }
}
