import 'package:flutter/material.dart';
import 'package:smart_flare/smart_flare.dart';

class PanActorDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: 
      Container(
        color: Colors.grey[600],
        child: Align(
          alignment: Alignment.centerRight,
          child: PanFlareActor(
          width: 135.0,
          height: screenSize.height,
          filename: "assets/gooey-slideout-menu.flr",
          openAnimation: 'open',
          closeAnimation: 'close',
          direction: ActorAdvancingDirection.RightToLeft,
          threshold: 20.0,
          reverseOnRelease: true,
          completeOnThresholdReached: true,
          activeAreas: [
            RelativePanArea(
              area: Rect.fromLTWH(0, 0.7, 1.0, 0.3),
              debugArea: true
            )
          ],
        )),
      )
    );
  }
}
