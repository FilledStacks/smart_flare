/// Smart Flare.
/// Developed by Dane mackier - Blog: https://medium.com/filledstacks

library smart_flare;

import 'package:flutter/material.dart';
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
  List<Widget> interactableWidgets;

  @override
  Widget build(BuildContext context) {
    if (widget.startingAnimation == null) {
      print('SmartFlare:Warning: - No starting animation supplied');
    }

    // if (interactableWidgets == null) {
    interactableWidgets = List<Widget>();
    interactableWidgets.add(Container(
      width: widget.width,
      height: widget.height,
      child: FlareActor(
        widget.filename,
        controller: _animationControls,
        animation: widget.startingAnimation,
      ),
    ));

    if (widget.activeAreas != null) {
      var interactiveAreas = widget.activeAreas.map((activeArea) {
        return Positioned(
            top: activeArea.area.top,
            left: activeArea.area.left,
            child: GestureDetector(
              onTap: () {
                // print("SmartFlare:INFO - Animation tped");
                playAnimation(activeArea);

                if (activeArea.onAreaTapped != null) {
                  activeArea.onAreaTapped();
                }
              },
              child: Container(
                width: activeArea.area.width,
                height: activeArea.area.height,
                decoration: BoxDecoration(
                    color: activeArea.debugArea
                        ? Color.fromARGB(80, 256, 0, 0)
                        : Colors.transparent,
                    border: activeArea.debugArea
                        ? Border.all(color: Colors.blue, width: 1.0)
                        : null),
              ),
            ));
      });

      interactableWidgets.addAll(interactiveAreas);
    }
    // }

    return Stack(children: interactableWidgets);
  }

  void playAnimation(ActiveArea activeArea) {
    String animationToPlay;

    if (activeArea.animationName != null) {
      animationToPlay = activeArea.animationName;
    } else if (activeArea.animationsToCycle != null) {
      animationToPlay = activeArea.getNextAnimation();
    }

    if (activeArea.hasRequiredAnimation &&
        activeArea.guardComingFrom.contains(_lastPlayedAnimation)) {
      print(
          'SmartFlare:Info - Last played animation is $_lastPlayedAnimation and $animationToPlay has a guard against it');
      return;
    }

    _animationControls.play(animationToPlay);

    _lastPlayedAnimation = animationToPlay;
  }
}

class CycleFlareActor extends StatefulWidget {
  final String filename;
  final List<String> animations;
  final int startingAnimationindex;
  final Function(String) callback;
  final double width;
  final double height;


  CycleFlareActor(
      {Key key,
      this.width,
      this.height,
      this.filename,
      this.animations,
      this.startingAnimationindex = 0,
      this.callback})
      : super(key: key);

  _CycleFlareActorState createState() => _CycleFlareActorState();
}

class _CycleFlareActorState extends State<CycleFlareActor> {
  int animationIndex;

  @override
  void initState() {
    animationIndex = widget.startingAnimationindex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SmartFlareActor(
      width: widget.width,
      height: widget.height,
      filename: 'assets/button-animation.flr',
      startingAnimation: widget.animations[animationIndex],
      activeAreas: [ActiveArea(
        area: Rect.fromLTWH(0, 0, widget.width, widget.height),
        animationsToCycle: widget.animations
      )],
    );
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

  /// A list of values for the active area to guard against coming from certain animations.
  final List<String> guardComingFrom;

  /// Draws debug data over the animation to indicate the active area
  final bool debugArea;

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

  bool get hasRequiredAnimation => guardComingFrom != null;

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
