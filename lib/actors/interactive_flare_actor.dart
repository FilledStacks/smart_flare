import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';
import '../models.dart';

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
        var isRelativeArea = activeArea is RelativeActiveArea;

        var top = isRelativeArea
            ? widget.width * activeArea.area.top
            : activeArea.area.top;
        var left = isRelativeArea
            ? widget.height * activeArea.area.left
            : activeArea.area.left;
        var width = isRelativeArea
            ? widget.width * activeArea.area.width
            : activeArea.area.width;
        var height = isRelativeArea
            ? widget.height * activeArea.area.height
            : activeArea.area.height;

        return Positioned(
            top: top,
            left: left,
            child: GestureDetector(
              onTap: () {
                // print("SmartFlare:INFO - Animation tped");
                playAnimation(activeArea);

                if (activeArea.onAreaTapped != null) {
                  activeArea.onAreaTapped();
                }
              },
              child: Container(
                width: width,
                height: height,
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