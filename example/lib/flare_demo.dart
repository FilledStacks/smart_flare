import 'package:flutter/material.dart';
import 'package:smart_flare/smart_flare.dart';

class FlareDemo extends StatefulWidget {
  @override
  _FlareDemoState createState() => _FlareDemoState();
}

class _FlareDemoState extends State<FlareDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        body: SmartFlareActor(
            width: 295.0,
            height: 251.0,
            filename: 'assets/button-animation.flr',
            startingAnimation: 'deactivate',));
  }
}
