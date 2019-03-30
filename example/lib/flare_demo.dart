import 'package:flutter/material.dart';
import 'package:smart_flare/smart_flare.dart';

class FlareDemo extends StatefulWidget {
  @override
  _FlareDemoState createState() => _FlareDemoState();
}

class _FlareDemoState extends State<FlareDemo> {
  @override
  Widget build(BuildContext context) {
    var animationWidth = 295.0;
    var animationHeight = 251.0;
    var thirdOfWidth = animationWidth / 3;
    var activeAreas = [
      // Insert top-left
      RelativeActiveArea(
          debugArea: true,
          area: Rect.fromLTRB(0, 0, 0.35, 0.5),
          guardComingFrom: ['deactivate'],
          animationName: 'camera_tapped',
          onAreaTapped: () {
            print('Camera tapped!');
          }),
      // Insert middle
      ActiveArea(
          // debugArea: true,
          area:
              Rect.fromLTWH(thirdOfWidth, 0, thirdOfWidth, animationHeight / 2),
          guardComingFrom: ['deactivate'],
          animationName: 'pulse_tapped',
          onAreaTapped: () {
            print('Pulse tapped!');
          }),
      // Insert top-right
      ActiveArea(
          // debugArea: true,
          area: Rect.fromLTWH(
              thirdOfWidth * 2, 0, thirdOfWidth, animationHeight / 2),
          guardComingFrom: ['deactivate'],
          animationName: 'image_tapped',
          onAreaTapped: () {
            print('Image tapped!');
          }),
      // Insert bottom half area
      ActiveArea(
          // debugArea: true,
          area: Rect.fromLTWH(
              0, animationHeight / 2, animationWidth, animationHeight / 2),
          animationsToCycle: ['activate', 'deactivate'],
          onAreaTapped: () {
            print('Activate toggles!');
          }),
    ];

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 102, 18, 222),
        body: Align(
            alignment: Alignment.bottomCenter,
            child: SmartFlareActor(
              width: animationWidth,
              height: animationHeight,
              filename: 'assets/button-animation.flr',
              startingAnimation: 'deactivate',
              activeAreas: activeAreas,
            )));
  }
}
