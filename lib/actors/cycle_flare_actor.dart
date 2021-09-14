import 'package:flutter/material.dart';
import './smart_flare_actor.dart';
import '../models.dart';

/// Given a list of animations. This actor will play through them all as it's tapped.
class CycleFlareActor extends StatefulWidget {
  final String filename;
  final List<String> animations;
  final int startingAnimationindex;
  final Function(String)? callback;
  final double width;
  final double height;

  /// The name of the artboard to display.
  final String? artboard;

  CycleFlareActor(
      {Key? key,
      required this.width,
      required this.height,
      required this.filename,
      required this.animations,
      this.artboard,
      this.startingAnimationindex = 0,
      this.callback})
      : super(key: key) {
    assert(animations != null, 'Animations cannot be null');
    assert(animations.length > 1,
        'To cycle through animations supply more than 1 key,');
  }

  _CycleFlareActorState createState() => _CycleFlareActorState();
}

class _CycleFlareActorState extends State<CycleFlareActor> {
  late int animationIndex;

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
      activeAreas: [
        ActiveArea(
            area: Rect.fromLTWH(0, 0, widget.width, widget.height),
            animationsToCycle: widget.animations)
      ],
    );
  }
}
