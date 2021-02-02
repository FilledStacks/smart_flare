import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:smart_flare/controllers/swipe_advance_controller.dart';
import 'package:smart_flare/controllers/tap_controller.dart';
import 'package:smart_flare/reducers.dart';
import '../models.dart';

/// A wrapper to the FlareActor that provides additional user input functionality.
/// By identifying certain areas on the animation we can assign it callbacks to trigger or
/// even some additional animation to play.
class SmartFlareActor extends StatefulWidget {
  final double width;

  final double height;

  /// Thefile path to the flare animation
  final String filename;

  /// The name of the artboard to display.
  final String artboard;

  /// Animation that the Flare actor will start off playing
  final String startingAnimation;

  final List<ActiveArea> activeAreas;

  /// When true the starting animation will be played on actions that rebuild the widget
  ///
  /// Set to true when you want the starting animation to play whenever you navigate back to a view
  final bool playStartingAnimationWhenRebuilt;

  FlareController _controller;

  SmartFlareActor(
      {@required this.width,
      @required this.height,
      @required this.filename,
      this.artboard,
      this.startingAnimation,
      this.playStartingAnimationWhenRebuilt = false,
      this.activeAreas,
      FlareController controller})
      : _controller = controller {
    if (_controller != null) {
      var hasPanAreaIfSwipeControllerSupplied =
          _controller is SwipeAdvanceController &&
              activeAreas.firstWhere((area) => area is RelativePanArea) != null;
      assert(hasPanAreaIfSwipeControllerSupplied,
          'A RelativePanArea has to be supplied when using the SwipeAdvanceController');
    }
  }

  _SmartFlareActorState createState() =>
      _SmartFlareActorState(controller: _controller);
}

class _SmartFlareActorState extends State<SmartFlareActor> {
  FlareController _controller;

  _SmartFlareActorState({FlareController controller})
      : _controller = controller;

  @override
  Widget build(BuildContext context) {
    if (widget.startingAnimation == null) {
      print('SmartFlare:Warning: - No starting animation supplied');
    }

    if (_controller == null) {
      _controller = TapController();
    }

    if (widget.startingAnimation != null &&
        widget.playStartingAnimationWhenRebuilt) {
      (_controller as TapController).playAnimation(ActiveArea(
          animationName: widget.startingAnimation,
          area: Rect.fromLTRB(0, 0, 1, 1)));
    }

    var interactableWidgets = List<Widget>();
    interactableWidgets.add(Container(
      width: widget.width,
      height: widget.height,
      child: FlareActor(
        widget.filename,
        artboard: widget.artboard,
        controller: _controller,
        animation: widget.startingAnimation,
      ),
    ));

    if (widget.activeAreas != null) {
      var interactiveAreas = widget.activeAreas.map((activeArea) {
        var isRelativeArea = activeArea is RelativeActiveArea;

        var top = isRelativeArea
            ? widget.height * activeArea.area.top
            : activeArea.area.top;
        var left = isRelativeArea
            ? widget.width * activeArea.area.left
            : activeArea.area.left;
        var width = isRelativeArea
            ? widget.width * activeArea.area.width
            : activeArea.area.width;
        var height = isRelativeArea
            ? widget.height * activeArea.area.height
            : activeArea.area.height;

        var isPanArea = activeArea is RelativePanArea;

        return Positioned(
            top: top,
            left: left,
            child: isPanArea
                ? _getPanArea(activeArea, width, height)
                : _getTappableArea(activeArea, width, height));
      });

      interactableWidgets.addAll(interactiveAreas);
    }

    return Stack(children: interactableWidgets);
  }

  void playAnimation(ActiveArea activeArea) {
    var animationToPlay = getAnimationToPlay(activeArea);

    if (_controller is SwipeAdvanceController) {
      (_controller as SwipeAdvanceController).playAnimation(animationToPlay);
    } else {
      (_controller as TapController).playAnimation(activeArea);
    }
  }

  Widget _getTappableArea(ActiveArea activeArea, double width, double height) {
    return GestureDetector(
      onTap: () {
        playAnimation(activeArea);
        if (activeArea.hasAnimationGuard) {
          if (_controller != null) {
            if (_controller is TapController) {
              if ((_controller as TapController).lastPlayedAnimation != null) {
                if (activeArea.guardComingFrom.contains(
                    (_controller as TapController).lastPlayedAnimation)) {
                  return;
                }
              }
              if ((_controller as TapController).lastPlayedCycleAnimation !=
                  null) {
                if (activeArea.guardComingFrom.contains(
                    (_controller as TapController).lastPlayedCycleAnimation)) {
                  return;
                }
              }
            }
          }
        }

        if (activeArea.onAreaTapped != null) {
          activeArea.onAreaTapped();
        }
      },
      child: _activeAreaRepresentation(activeArea, width, height),
    );
  }

  Widget _getPanArea(ActiveArea activeArea, double width, double height) {
    return GestureDetector(
        onHorizontalDragStart: (tapInfo) {
          (_controller as SwipeAdvanceController).interactionStarted();
        },
        onHorizontalDragUpdate: (tapInfo) {
          var localPosition = (context.findRenderObject() as RenderBox)
              .globalToLocal(tapInfo.globalPosition);
          (_controller as SwipeAdvanceController)
              .updateSwipePosition(localPosition, tapInfo.delta);
        },
        onHorizontalDragEnd: (tapInfo) {
          (_controller as SwipeAdvanceController).interactionEnded();
        },
        child: _activeAreaRepresentation(activeArea, width, height,
            borderColor: Colors.red));
  }

  Widget _activeAreaRepresentation(
      ActiveArea activeArea, double width, double height,
      {Color borderColor = Colors.blue}) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: (activeArea.debugArea ?? false)
                ? Color.fromARGB(80, 256, 0, 0)
                : Colors.transparent,
            border: (activeArea.debugArea ?? false)
                ? Border.all(color: borderColor, width: 1.0)
                : null));
  }
}
