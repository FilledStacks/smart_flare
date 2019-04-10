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

  /// Full path to the animation file
  final String animationFilePath;

  /// The name of the animation that has to be played while advancing
  final String openAnimationName;

  /// The animation that has to be played when going back from advanced position
  ///
  /// If none is supplied the open animation will be reversed
  final String closeAnimationName;

  /// The threshold for animation to complete when gesture is finished. If < 0 it's taken as percentage else pixels.
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
      @required this.openAnimationName,
      this.closeAnimationName,
      this.threshold,
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
          width: widget.width,
          openAnimationName: widget.openAnimationName,
          direction: widget.direction,
          orientation: widget.orientation,
          reverseOnRelease: widget.reverseOnRelease,
          swipeThreshold: widget.threshold,
          closeAnimationName: widget.closeAnimationName);
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
            child: FlareActor(
              widget.animationFilePath,
              controller: swipeController,
              fit: BoxFit.contain,
            )));
  }
}

enum _AnimationOrigin { Beginning, End }

class SwipeAdvanceController extends FlareController {
  final double width;
  final String _openAnimationName;
  final String _closeAnimationName;
  final ActorOrientation _orientation;
  ActorAdvancingDirection _direction;
  final bool reverseOnRelease;
  double swipeThreshold;

  _AnimationOrigin _currentAnimationOrigin = _AnimationOrigin.Beginning;

  ActorAnimation _openAnimation;
  ActorAnimation _closeAnimation;
  double _speed = 0.5;
  double _previousTimeToApply = 0.0;
  double _deltaXSinceInteraction = 0.0;
  double animationPosition = 0.0;
  bool _thresholdReached = false;
  bool _interacting = false;
  bool animationAtEnd = false;

  SwipeAdvanceController(
      {@required this.width,
      @required String openAnimationName,
      @required String closeAnimationName,
      @required ActorAdvancingDirection direction,
      @required ActorOrientation orientation,
      this.reverseOnRelease,
      this.swipeThreshold})
      : _openAnimationName = openAnimationName,
        _closeAnimationName = closeAnimationName,
        _direction = direction,
        _orientation = orientation;

  double get _animationTimeToApply =>
      _openAnimation.duration * animationPosition;

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
          animationPosition += (elapsed * _speed) % _openAnimation.duration;
        } else if (!comingFromBeginning && animationPosition > 0) {
          animationPosition -= (elapsed * _speed) % _openAnimation.duration;
        } else {
          // When we get to the end of the animation we want to indicate that and set some values.
          // Here we prapare for the swipe back
          if (!animationAtEnd) {
            // If we are advancing towards the end of the animtion and we're coming from beginning
            if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
              // We want to indicate that we are now at the end of the animation.
              _currentAnimationOrigin = _AnimationOrigin.End;
              // We also want to set the delta interaction equal to the pagewidth
              _deltaXSinceInteraction = width;
            } else {
              // If we're coming from the end, We want to indicate that we are now at the beginning of the animation.
              _currentAnimationOrigin = _AnimationOrigin.Beginning;
              // We want our delta Since interaction to reflect the same
              _deltaXSinceInteraction = 0;
            }

            animationAtEnd = true;
            _thresholdReached = false;
          }
        }
      } else if (!animationAtEnd) {
        // If the animation has not ended and we haven't reached the threshold yet
        var reverseAnimation =
            _currentAnimationOrigin == _AnimationOrigin.Beginning;
        var reverseValue = (elapsed * _speed) % _openAnimation.duration;
        if (reverseAnimation && animationPosition > 0) {
          animationPosition -= reverseValue;
        } else if (!reverseAnimation && animationPosition < 1) {
          animationPosition += reverseValue;
        } else {
          // If we're reversing the animation and we get to the end we want to set
          // the delta interaction back to 0 so that we can start from the beginning
          if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
            _deltaXSinceInteraction = 0;
          } else {
            // If we're reversing back to the end then we want to set the
            // deltaXSinceInteraction equal to the pageWidth so we can play animation from the end.
            _deltaXSinceInteraction = width;
          }

          animationAtEnd = true;
          _thresholdReached = false;
        }
      }
    }

    if ((_previousTimeToApply !=
            _animationTimeToApply) && // Always has to be true. We don't do uneccessary updates
        (_currentAnimationOrigin ==
                _AnimationOrigin
                    .Beginning || // If we're coming from the beginning we want to play the open animation
            _closeAnimation == null)) {
      // If we have no closeAnimation defined we want to always play the open animation
      _openAnimation.apply(_animationTimeToApply, artboard, 1.0);
    } else if ((_previousTimeToApply !=
            _animationTimeToApply) && // Always has to be true. We don't do uneccessary updates
        (_currentAnimationOrigin == _AnimationOrigin.End &&
            _closeAnimation != null)) {
      _closeAnimation.apply(_animationTimeToApply, artboard, 1.0);
    }

    _previousTimeToApply = _animationTimeToApply;
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _openAnimation = artboard.getAnimation(_openAnimationName);

    if (_closeAnimationName != null) {
      _closeAnimation = artboard.getAnimation(_closeAnimationName);
    }

    if (swipeThreshold != null && swipeThreshold > 0 && swipeThreshold < 1) {
      swipeThreshold = width * swipeThreshold;
    }
  }

  void updateSwipePosition(Offset touchPosition, Offset touchDelta) {
    animationAtEnd = false;

    var insideBounds = touchPosition.dx > 0 &&
        touchPosition.dx < width &&
        touchPosition.dy > 0;

    if (insideBounds) {
      var deltaX = touchDelta.dx;
      if (_direction == ActorAdvancingDirection.RightToLeft) {
        deltaX *= -1;
      }

      _deltaXSinceInteraction += deltaX;

      if (_deltaXSinceInteraction > width) {
        _deltaXSinceInteraction = width;
      }
      if (_deltaXSinceInteraction < 0) {
        _deltaXSinceInteraction = 0;
      }

      if (swipeThreshold != null) {
        if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
          _thresholdReached = _deltaXSinceInteraction > swipeThreshold;
        } else {
          _thresholdReached = _deltaXSinceInteraction < swipeThreshold;
        }
      }

      if (_direction == ActorAdvancingDirection.RightToLeft) {
        animationPosition = _deltaXSinceInteraction / width;
      } else {
        animationPosition = 1.0 - (_deltaXSinceInteraction / width);
      }
    }
  }

  void interactionStarted() {
    _interacting = true;
  }

  void interactionEnded() {
    _interacting = false;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    // TODO: implement setViewTransform
  }
}
