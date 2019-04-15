import 'package:flare_flutter/flare_controls.dart';
import 'package:smart_flare/reducers.dart';

import '../models.dart';

class TapController extends FlareControls {
  String _lastPlayedAnimation;
  String _lastPlayedCycleAnimation;

  void playAnimation(ActiveArea activeArea) {
    var animationName = getAnimationToPlay(activeArea);

    // DOING: When cycling through animations, the same animation should never play twice,
    // always advance

    print('LastPlayedCycleAnimation: $_lastPlayedCycleAnimation, hascycleAnimation: ${activeArea.hasCycleAnimations}');
    if(activeArea.hasCycleAnimations && _lastPlayedCycleAnimation == animationName) {
      animationName = activeArea.getNextAnimation();
    }

    if (activeArea.hasAnimationGuard &&
        activeArea.guardComingFrom.contains(_lastPlayedAnimation)) {
      // print('SmartFlare:Info - Last played animation is $_lastPlayedAnimation and $animationName has a guard against it');
      return;
    }

    play(animationName);

    _lastPlayedAnimation = animationName;

    if(activeArea.hasCycleAnimations) {
      _lastPlayedCycleAnimation = animationName;
    }
  }
}
