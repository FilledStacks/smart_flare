import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/material.dart';

import '../enums.dart';

enum _AnimationOrigin { Beginning, End }

class SwipeAdvanceController extends FlareControls {
  final double width;
  final String _openAnimationName;
  final String? _closeAnimationName;
  ActorAdvancingDirection _direction;
  final bool? reverseOnRelease;
  double? swipeThreshold;
  final bool? completeOnThresholdReached;

  _AnimationOrigin _currentAnimationOrigin = _AnimationOrigin.Beginning;

  ActorAnimation? _openAnimation;
  ActorAnimation? _closeAnimation;
  double _speed = 1.0;
  double _previousTimeToApply = 0.0;
  double _deltaXSinceInteraction = 0.0;
  double _openAnimationPosition = 0.0;
  double _closeAnimationPosition = 0.0;
  bool _thresholdReached = false;
  bool _interacting = false;
  bool animationAtEnd = false;
  bool _playNormalAnimation = false;

  SwipeAdvanceController(
      {required this.width,
      required String openAnimationName,
      required String? closeAnimationName,
      required ActorAdvancingDirection direction,
      this.completeOnThresholdReached,
      this.reverseOnRelease,
      this.swipeThreshold})
      : _openAnimationName = openAnimationName,
        _closeAnimationName = closeAnimationName,
        _direction = direction;

  bool get _hasCloseAnimation => _closeAnimation != null;

  bool get _playCloseAnimation =>
      _hasCloseAnimation && _currentAnimationOrigin == _AnimationOrigin.End;

  double get _animationTimeToApply =>
      _openAnimation!.duration * _openAnimationPosition;
  double get _closeAnimationTimeToApply =>
      _closeAnimation!.duration * _closeAnimationPosition;

  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    _openAnimation = artboard.getAnimation(_openAnimationName);

    if (_closeAnimationName != null) {
      _closeAnimation = artboard.getAnimation(_closeAnimationName!);
    }

    if (swipeThreshold != null && swipeThreshold! > 0 && swipeThreshold! < 1) {
      swipeThreshold = width * swipeThreshold!;
    }

    // Set the starting animation as End
    _currentAnimationOrigin = _AnimationOrigin.End;
    // Then indicate the threshold is reached so we can play to the end
    // of the animation (Playing the close animation)
    _thresholdReached = true;
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (_playNormalAnimation) {
      super.advance(artboard, elapsed);
      // print('Play normal animation: $normalAnimation');
      // return normalAnimation;

    } else {
      if (_openAnimation == null) {
        return true;
      }

      if (!_playCloseAnimation) {
        _advanceOnlyOpenAnimation(elapsed);
      } else {
        if (_closeAnimation == null) {
          return true;
        }

        _advanceClosingAnimation(elapsed);
      }

      if ((_previousTimeToApply !=
              _animationTimeToApply) && // Always has to be true. We don't do uneccessary updates
          (_currentAnimationOrigin ==
                  _AnimationOrigin
                      .Beginning || // If we're coming from the beginning we want to play the open animation
              _closeAnimation == null)) {
        // If we have no closeAnimation defined we want to always play the open animation
        _openAnimation!.apply(_animationTimeToApply, artboard, 1.0);
        _previousTimeToApply = _animationTimeToApply;
      } else if ((_previousTimeToApply !=
              _closeAnimationTimeToApply) && // Always has to be true. We don't do uneccessary updates
          (_currentAnimationOrigin == _AnimationOrigin.End &&
              _closeAnimation != null)) {
        // print(
        //     'PLAY CLOSEANIMATION: _closeAnimationTimeToApply: $_closeAnimationTimeToApply, closeAnimationPosition: $_closeAnimationPosition');
        _closeAnimation!.apply(_closeAnimationTimeToApply, artboard, 1.0);
        _previousTimeToApply = _closeAnimationTimeToApply;
      }
    }
    return true;
  }

  @override
  void onCompleted(String name) {
    _playNormalAnimation = false;
    if (name == _closeAnimationName) {
      _updateAnimationPositionToBeginning();
    }
    super.onCompleted(name);
  }

  void playAnimation(String animationName) {
    _playNormalAnimation = true;
    play(animationName);
  }

  void updateSwipePosition(Offset touchPosition, Offset touchDelta) {
    animationAtEnd = false;

    var insideBounds = touchPosition.dx > 0 &&
        touchPosition.dx < width &&
        touchPosition.dy > 0;

    if (completeOnThresholdReached! && _thresholdReached) {
      interactionEnded();
      return;
    }

    if (insideBounds) {
      if (!_playCloseAnimation) {
        _updateSwipeForSingleOpenAnimation(touchDelta);
      } else {
        _updateSwipeForClosingAnimation(touchDelta);
      }
    }
  }

  void _advanceClosingAnimation(double elapsed) {
    if (!_interacting) {
      if (_thresholdReached) {
        _updateClosingAnimation(elapsed);
      } else if (!animationAtEnd && reverseOnRelease!) {
        _reverseCloseAnimation(elapsed);
      }
    }
  }

  void _advanceOnlyOpenAnimation(double elapsed) {
    if (!_interacting) {
      if (_thresholdReached) {
        // If we've released the drag and has reached the threshold
        _updateAnimationForNoCloseAnimationSupplied(elapsed);
      } else if (!animationAtEnd && reverseOnRelease!) {
        _reverseOpenAnimation(elapsed);
      }
    }
  }

  void _reverseOpenAnimation(double elapsed) {
    // print('_reverseOpenAnimation');
    // If the animation has not ended and we haven't reached the threshold yet
    var reverseAnimation =
        _currentAnimationOrigin == _AnimationOrigin.Beginning;
    var reverseValue = (elapsed * _speed) % _openAnimation!.duration;
    if (reverseAnimation && _openAnimationPosition > 0) {
      _openAnimationPosition -= reverseValue;
    } else if (!reverseAnimation && _openAnimationPosition < 1) {
      _openAnimationPosition += reverseValue;
    } else {
      _handleOpenAnimationReverseComplete();
    }
  }

  void _handleOpenAnimationReverseComplete() {
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

    // print(
    //     'Animation@end REVERSE: _currentAnimationOrigin: $_currentAnimationOrigin, _deltaXSinceInteraction: $_deltaXSinceInteraction');
  }

  void _handleCloseAnimationReverseComplete() {
    // If we're reversing the animation and we get to the end we want to set
    // the delta interaction back to 0 so that we can start from the beginning
    _deltaXSinceInteraction = 0;
    animationAtEnd = true;
    _thresholdReached = false;

    // print(
    //     'CLOSING Animation@end REVERSE: _currentAnimationOrigin: $_currentAnimationOrigin, _deltaXSinceInteraction: $_deltaXSinceInteraction');
  }

  void _updateAnimationForNoCloseAnimationSupplied(double elapsed) {
    // If we're coming from the beginning we want to advance the animation until the end
    var comingFromBeginning =
        _currentAnimationOrigin == _AnimationOrigin.Beginning;
    if (comingFromBeginning && _openAnimationPosition < 1) {
      // advance until we get to the end of the animation
      _openAnimationPosition += (elapsed * _speed) % _openAnimation!.duration;
    } else if (!comingFromBeginning && _openAnimationPosition > 0) {
      _openAnimationPosition -= (elapsed * _speed) % _openAnimation!.duration;
    } else {
      // When we get to the end of the animation we want to indicate that and set some values.
      // Here we prapare for the swipe back
      if (!animationAtEnd) {
        // If we are advancing towards the end of the animtion and we're coming from beginning
        if (_currentAnimationOrigin == _AnimationOrigin.Beginning) {
          // We want to indicate that we are now at the end of the animation.
          _currentAnimationOrigin = _AnimationOrigin.End;
          // We also want to set the delta interaction equal to the pagewidth
          _deltaXSinceInteraction = _playCloseAnimation ? 0 : width;
        } else {
          // If we're coming from the end, We want to indicate that we are now at the beginning of the animation.
          _currentAnimationOrigin = _AnimationOrigin.Beginning;
          // We want our delta Since interaction to reflect the same
          _deltaXSinceInteraction = 0;
        }

        animationAtEnd = true;
        _thresholdReached = false;
        // Make sure the position for the closeAnimation is at the beginning.
        _closeAnimationPosition = 0;
        // print(
        //     'Animation@end FORWARD: _currentAnimationOrigin: $_currentAnimationOrigin, _deltaXSinceInteraction: $_deltaXSinceInteraction');
      }
    }
  }

  void _updateClosingAnimation(double elapsed) {
    if (_closeAnimationPosition < 1) {
      // advance until we get to the end of the animation
      _closeAnimationPosition += (elapsed * _speed) % _closeAnimation!.duration;
    } else {
      // When we get to the end of the animation we want to indicate that and set some values.
      // Here we prapare for the swipe back
      if (!animationAtEnd) {
        _updateAnimationPositionToBeginning();

        animationAtEnd = true;
        _thresholdReached = false;
        // print(
        //     'CLOSING Animation@end FORWARD: _currentAnimationOrigin: $_currentAnimationOrigin, _deltaXSinceInteraction: $_deltaXSinceInteraction');
      }
    }
  }

  void _updateAnimationPositionToBeginning() {
    // Set back to beginning when we complete the animation
    _currentAnimationOrigin = _AnimationOrigin.Beginning;
    // We want our delta Since interaction to reflect the same
    _deltaXSinceInteraction = 0;
    // Reset the open animation position since the first frame of the open
    // animation equals the last frame of the close animation
    _openAnimationPosition = 0;
  }

  void _reverseCloseAnimation(double elapsed) {
    // If the animation has not ended and we haven't reached the threshold yet
    // print('_reverseCloseAnimation');
    var reverseValue = (elapsed * _speed) % _closeAnimation!.duration;
    if (_closeAnimationPosition > 0) {
      _closeAnimationPosition -= reverseValue;
    } else {
      _handleCloseAnimationReverseComplete();
    }
  }

  void _updateSwipeForClosingAnimation(Offset touchDelta) {
    var deltaX = touchDelta.dx;

    // Reverse only when it's left to right because the end animation will be
    // swiped in the opposite direction but needs to advance normally from 0 - 1
    if (_direction == ActorAdvancingDirection.LeftToRight) {
      deltaX *= -1;
    }

    _deltaXSinceInteraction += deltaX;

    // clamp the _deltaXSinceInteraction value
    if (_deltaXSinceInteraction > width) {
      _deltaXSinceInteraction = width;
    }
    if (_deltaXSinceInteraction < 0) {
      _deltaXSinceInteraction = 0;
    }

    if (swipeThreshold != null) {
      _thresholdReached = _deltaXSinceInteraction > swipeThreshold!;
    }

    if (_direction == ActorAdvancingDirection.RightToLeft) {
      _closeAnimationPosition = _deltaXSinceInteraction / width;
    } else {
      _closeAnimationPosition = 1.0 - (_deltaXSinceInteraction / width);
    }

    // print(
    //     'CLOSE SWIPE: closeAnimationPosition: $_closeAnimationPosition, _thresholdReached: $_thresholdReached, _deltaXSinceInteraction: $_deltaXSinceInteraction, deltaX: $deltaX');
  }

  void _updateSwipeForSingleOpenAnimation(Offset touchDelta) {
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
        _thresholdReached = _deltaXSinceInteraction > swipeThreshold!;
      } else {
        _thresholdReached = _deltaXSinceInteraction < swipeThreshold!;
      }
    }

    if (_direction == ActorAdvancingDirection.RightToLeft) {
      _openAnimationPosition = _deltaXSinceInteraction / width;
    } else {
      _openAnimationPosition = 1.0 - (_deltaXSinceInteraction / width);
    }

    // print(
    //     'OPEN SWIPE: animationPosition: $_openAnimationPosition, _thresholdReached: $_thresholdReached, _deltaXSinceInteraction: $_deltaXSinceInteraction, deltaX: $deltaX');
  }

  void interactionStarted() {
    _interacting = true;
  }

  void interactionEnded() {
    _interacting = false;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    super.setViewTransform(viewTransform);
    // TODO: implement setViewTransform
  }
}
