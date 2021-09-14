import 'package:flutter/material.dart';
import '../actors/smart_flare_actor.dart';
import '../controllers/swipe_advance_controller.dart';

import '../enums.dart';
import '../models.dart';

class PanFlareActor extends StatefulWidget {
  final double width;
  final double height;

  /// The direction to swipe for the animation to advance
  final ActorAdvancingDirection direction;

  /// Full path to the animation file
  final String filename;

  /// The name of the artboard to display.
  final String? artboard;

  /// The name of the animation that has to be played while advancing
  final String openAnimation;

  /// The animation that has to be played when going back from advanced position
  ///
  /// If none is supplied the open animation will be reversed
  final String? closeAnimation;

  /// The threshold for animation to complete when gesture is finished. If < 1 it's taken as percentage else number of logical pixels.
  ///
  /// When this threshold is passed and the pan/drag gesture ends the animation will play until it's complete
  final double? threshold;

  /// When true the animation will reverse on the release of the gesture if threshold is not reached.
  final bool reverseOnRelease;

  /// When true the animation will play to completion as soon as the threshold is reached
  final bool completeOnThresholdReached;

  final List<ActiveArea>? activeAreas;

  const PanFlareActor(
      {required this.width,
      required this.height,
      required this.filename,
      required this.openAnimation,
      this.direction = ActorAdvancingDirection.LeftToRight,
      this.artboard,
      this.activeAreas,
      this.closeAnimation,
      this.threshold,
      this.completeOnThresholdReached = false,
      this.reverseOnRelease = true});

  @override
  _PanFlareActorState createState() => _PanFlareActorState();
}

class _PanFlareActorState extends State<PanFlareActor> {
  SwipeAdvanceController? swipeController;

  @override
  void initState() {
    if (swipeController == null) {
      swipeController = SwipeAdvanceController(
          width: widget.width,
          openAnimationName: widget.openAnimation,
          direction: widget.direction,
          reverseOnRelease: widget.reverseOnRelease,
          swipeThreshold: widget.threshold,
          closeAnimationName: widget.closeAnimation,
          completeOnThresholdReached: widget.completeOnThresholdReached);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SmartFlareActor(
      width: widget.width,
      height: widget.height,
      filename: widget.filename,
      artboard: widget.artboard,
      controller: swipeController,
      activeAreas: widget.activeAreas,
    );
  }
}
