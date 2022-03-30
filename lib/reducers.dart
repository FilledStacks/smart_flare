import 'models.dart';

String? getAnimationToPlay(ActiveArea activeArea) {
  String? animationToPlay;

  if (activeArea.animationName != null) {
    animationToPlay = activeArea.animationName;
  } else if (activeArea.animationsToCycle != null) {
    animationToPlay = activeArea.getNextAnimation();
  }

  return animationToPlay;
}
