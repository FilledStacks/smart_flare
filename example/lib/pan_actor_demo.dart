import 'package:flutter/material.dart';
import 'package:smart_flare/actors/pan_flare_actor.dart';

class PanActorDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: 
      Container(
        color: Colors.green,
        child: Align(
          alignment: Alignment.centerRight,
          child: PanFlareActor(
          width: 135.0,
          height: screenSize.height,
          animationFilePath: "assets/tutorial-transition.flr",
          openAnimationName: 'drawer-open',
          closeAnimationName: 'drawer-close',
          direction: ActorAdvancingDirection.RightToLeft,
          threshold: 60.0,
          reverseOnRelease: true,
        )),
      )
    );
  }
}
