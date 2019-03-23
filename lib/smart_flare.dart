/// Smart Flare.
/// Developed by Dane mackier - Blog: https://medium.com/filledstacks

library smart_flare;

import 'package:flutter/material.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';

/// A wrapper to the FlareActor that provides additional user input functionality.
/// By identifying certain areas on the animation we can assign it callbacks to trigger or
/// even some additional animation to play.
class SmartFlareActor extends StatefulWidget {
  final double width;

  final double height;

  /// Thefile path to the flare animation
  final String filename;

  /// Animation that the Flare actor will start off playing
  final String startingAnimation;

  final List<ActiveArea> activeAreas;

  SmartFlareActor(
      {@required this.width,
      @required this.height,
      @required this.filename,
      this.startingAnimation,
      this.activeAreas});

  _SmartFlareActorState createState() => _SmartFlareActorState();
}

class _SmartFlareActorState extends State<SmartFlareActor> {
  String _lastPlayedAnimation;

  final FlareControls _animationControls = FlareControls();

  @override
  Widget build(BuildContext context) {
    if (widget.startingAnimation == null) {
      print('SmartFlare:Warning: - No starting animation supplied');
    }

    // print('SmartFlare: ${_animationName ?? widget.startingAnimation}');

    return GestureDetector(
      onTapUp: _handleTapUp,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: FlareActor(
          widget.filename,
          controller: _animationControls,
          animation: widget.startingAnimation,
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails tapDetails) {
    // Convert the global position to a local position within our widget
    var localPosition = (context.findRenderObject() as RenderBox)
        .globalToLocal(tapDetails.globalPosition);

    widget.activeAreas.forEach((activeArea) {
      // Check if the current touch is in the local position
      if (activeArea.area.contains(localPosition)) {
        playAnimation(activeArea);

        if (activeArea.onAreaTapped != null) {
          activeArea.onAreaTapped();
        }
      }
    });
  }

  void playAnimation(ActiveArea activeArea) {
    String animationToPlay;

    if (activeArea.animationName != null) {
     animationToPlay = activeArea.animationName;
    } else if (activeArea.animationsToCycle != null) {
     animationToPlay = activeArea.getNextAnimation();
    }

      if(activeArea.hasRequiredAnimation && _lastPlayedAnimation ==activeArea.animationRequired) {
        print('SmartFlare:Info - Last played animation is $_lastPlayedAnimation and $animationToPlay has a guard against it');
        return;
      }
     _animationControls.play(animationToPlay);
     _lastPlayedAnimation = animationToPlay;
  }

}

/// This model represents an area ontop of our Smart Flare actor that
/// the user can interact with.
class ActiveArea {
  /// The area that the ActiveArea represents
  final Rect area;

  /// The name of the animation to play when a user taps on this
  /// area.
  final String animationName;

  /// A list of the animations to cycle through when a user taps this area.
  /// It cycles through from 0 to the end of the list. One animation per tap
  /// This cannot be used together with animation name.
  final List<String> animationsToCycle;

  /// This callback will be fired when the animation area is interacted with
  final Function onAreaTapped;

  /// Set this value to the required animation that needs to be active
  /// in order for this animation to play
  final String animationRequired;

  int _nextAnimationIndex = 0;

  ActiveArea(
      {@required this.area,
      this.animationsToCycle,
      this.animationName,
      this.onAreaTapped,
      this.animationRequired}) {
    if (animationName == null && onAreaTapped == null) {
      print(
          'SmartFlare:Warning - If you want some feedback from the animation add either animationName or onAreaTapped');
    }

    var hasAnimationsToCycleAndAnimationName =
        this.animationName != null && this.animationsToCycle != null;
    assert(!hasAnimationsToCycleAndAnimationName,
        'Use either animationsToCycle or animationName but not both');

    if (animationsToCycle == null) {
      print(
          'SmartFlare:Warning - If you are cycling through animations there\'s a high chance that you might need to set the animationRequired property on the Active area.');
    }
  }

  bool get hasRequiredAnimation => animationRequired != null;

  String getNextAnimation() {
    var nextAnimation = animationsToCycle[_nextAnimationIndex];
    _nextAnimationIndex++;

    if (_nextAnimationIndex == animationsToCycle.length) {
      _nextAnimationIndex = 0;
    }

    return nextAnimation;
  }

  @override
  String toString() {
    return 'AnimationName: $animationName - Area: $area - hasOnTapCallback: ${onAreaTapped != null}';
  }
}
