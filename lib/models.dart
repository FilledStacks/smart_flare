import 'dart:ui';
import 'package:flutter/foundation.dart';

/// This model represents an area ontop of our Smart Flare actor that
/// the user can interact with.
class ActiveArea {
  /// The area that the ActiveArea represents
  Rect area;

  /// The name of the animation to play when a user taps on this
  /// area.
  String animationName;

  /// A list of the animations to cycle through when a user taps this area.
  /// It cycles through from 0 to the end of the list. One animation per tap
  /// This cannot be used together with animation name.
  List<String> animationsToCycle;

  /// This callback will be fired when the animation area is interacted with
  Function onAreaTapped;

  /// A list of values for the active area to guard against coming from certain animations.
  List<String> guardComingFrom;

  /// Draws debug data over the animation to indicate the active area
  bool debugArea;

  /// ()A list of values for the active area to guard against, going to certain animations.
  // final List<String> guardGoingTo;

  int _nextAnimationIndex = 0;

  ActiveArea(
      {@required this.area,
      this.animationsToCycle,
      this.animationName,
      this.onAreaTapped,
      this.guardComingFrom,
      this.debugArea = false}) {

    assert(area != null, 'Please provide an area for this ActiveArea');

    if (animationName == null && onAreaTapped == null) {
      print(
          'SmartFlare:Warning - If you want some feedback from the animation add either animationName or onAreaTapped');
    }

    var hasAnimationsToCycleAndAnimationName =
        this.animationName != null && this.animationsToCycle != null;
    assert(!hasAnimationsToCycleAndAnimationName,
        'Use either animationsToCycle or animationName but not both');
  }

  bool get hasRequiredAnimation => guardComingFrom != null;

  String getNextAnimation() {
    _nextAnimationIndex++;

    if (_nextAnimationIndex == animationsToCycle.length) {
      _nextAnimationIndex = 0;
    }

    var nextAnimation = animationsToCycle[_nextAnimationIndex];

    return nextAnimation;
  }

  @override
  String toString() {
    return 'AnimationName: $animationName - Area: $area - hasOnTapCallback: ${onAreaTapped != null}';
  }
}

class RelativeActiveArea extends ActiveArea {
  RelativeActiveArea(
      {debugArea, area, guardComingFrom, animationName, onAreaTapped})
      : super(
            debugArea: debugArea,
            area: area,
            guardComingFrom: guardComingFrom,
            animationName: animationName,
            onAreaTapped: onAreaTapped);
}

class RelativePanArea extends RelativeActiveArea {
  RelativePanArea(
      {debugArea, area, guardComingFrom, animationName, onAreaTapped})
      : super(
            debugArea: debugArea,
            area: area,
            guardComingFrom: guardComingFrom,
            animationName: animationName,
            onAreaTapped: onAreaTapped);
}
