/// Smart Flare.
/// Developed by Dane mackier - Blog: https://medium.com/filledstacks

library smart_flare;

import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

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
  String _animationName;

  @override
  Widget build(BuildContext context) {
    if (widget.startingAnimation == null) {
      print('SmartFlare:Warning: - No starting animation supplied');
    }

    print('SmartFlare: ${_animationName ?? widget.startingAnimation}');

    return GestureDetector(
      onTapUp: _handleTapUp,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: FlareActor(widget.filename,
            animation: _animationName ?? widget.startingAnimation),
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
        if (activeArea.animationName != null) {
          setState(() {
            _animationName = activeArea.animationName;
          });
        }

        if (activeArea.animationsToCycle != null) {
          setState(() {
            _animationName = activeArea.getNextAnimation();
          });
        }

        if (activeArea.onAreaTapped != null) {
          activeArea.onAreaTapped();
        }
      }
    });
  }
}

/// This model represents an area ontop of our Smart Flare actor that
/// the user can interact with.
class ActiveArea {
  /// The area that the ActiveArea represents
  final Rect area;

  /// The name of the animation to play when a user has tapped on this
  /// area.
  final String animationName;

  /// A list of the animations to cycle through when a user taps this area
  final List<String> animationsToCycle;

  /// This callback will be fired when the animation area is interacted with
  final Function onAreaTapped;

  int _nextAnimationIndex = 0;

  ActiveArea(
      {@required this.area,
      this.animationsToCycle,
      this.animationName,
      this.onAreaTapped}) {
    if (animationName == null && onAreaTapped == null) {
      print(
          'SmartFlare:Warning - If you want some feedback from the animation add either animationName or onAreaTapped');
    }
  }

  String getNextAnimation() {
    var nextAnimation =animationsToCycle[_nextAnimationIndex];
    _nextAnimationIndex++;

    if(_nextAnimationIndex ==animationsToCycle.length) {
      _nextAnimationIndex = 0;
    }

    return nextAnimation;
  }

  @override
  String toString() {
    return 'AnimationName: $animationName - Area: $area - hasOnTapCallback: ${onAreaTapped != null}';
  }
}
