import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:smart_flare/controllers/swipe_advance_controller.dart';
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

  FlareController _controller;

  SmartFlareActor(
      {@required this.width,
      @required this.height,
      @required this.filename,
      this.startingAnimation,
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
  String _lastPlayedAnimation;

  FlareController _controller;

  _SmartFlareActorState({FlareController controller})
      : _controller = controller;

  @override
  Widget build(BuildContext context) {
    if (widget.startingAnimation == null) {
      print('SmartFlare:Warning: - No starting animation supplied');
    }

    if (_controller == null) {
      _controller = FlareControls();
    }

    var interactableWidgets = List<Widget>();
    interactableWidgets.add(Container(
      width: widget.width,
      height: widget.height,
      child: FlareActor(
        widget.filename,
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

    if (_controller is SwipeAdvanceController) {
      (_controller as SwipeAdvanceController).play(animationToPlay);
    } else {
      (_controller as FlareControls).play(animationToPlay);
    }

    _lastPlayedAnimation = animationToPlay;
  }

  Widget _getTappableArea(ActiveArea activeArea, double width, double height) {
    return GestureDetector(
      onTap: () {
        playAnimation(activeArea);

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
            color: activeArea.debugArea
                ? Color.fromARGB(80, 256, 0, 0)
                : Colors.transparent,
            border: activeArea.debugArea
                ? Border.all(color: borderColor, width: 1.0)
                : null));
  }
}
