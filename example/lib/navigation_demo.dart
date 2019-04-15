import 'package:flare_tutorial/flare_demo.dart';
import 'package:flare_tutorial/pan_actor_demo.dart';
import 'package:flutter/material.dart';
import 'package:smart_flare/actors/smart_flare_actor.dart';
import 'package:smart_flare/models.dart';

class NavigationDemo extends StatefulWidget {
  @override
  _NavigationDemoState createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  var animationWidth = 195.0;
  var animationHeight = 151.0;

  @override
  Widget build(BuildContext context) {
    var activeAreas = [
      // Insert top-left
      ActiveArea(
          debugArea: true,
          area: Rect.fromLTWH(40, 20, 50, 40),
          animationName: 'image_tapped',
          onAreaTapped: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PanActorDemo()));
          }),
      // Insert middle

      // Insert top-right
      ActiveArea(
          debugArea: true,
          area: Rect.fromLTWH(110, 20, 50, 40),
          animationName: 'image_tapped',
          onAreaTapped: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FlareDemo())
            );
          }),
      // Insert bottom half area
      ActiveArea(
          debugArea: true,
          area: Rect.fromLTWH(75, 82, 50, 55),
          animationsToCycle: ['deactivate', 'activate'],
          onAreaTapped: () {
            print('Activate toggles!');
          }),
    ];

    return SafeArea(
      top: false,
      bottom: false,
      child: new Container(
        child: new Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            Padding(
                child: Container(),
                padding: const EdgeInsets.only(top: 60.0)),
            // GuillotineMenu(),
            Align(
                alignment: Alignment.bottomCenter,
                child: SmartFlareActor(
                  width: animationWidth,
                  height: animationHeight,
                  filename: 'assets/button-animation.flr',
                  startingAnimation: 'deactivate',
                  activeAreas: activeAreas,
                )),
          ],
        ),
      ),
    );
  }
}
