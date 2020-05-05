## 0.2.9+1

- Change log style updates

## 0.2.9

- Update flare_flutter to 2.0.1

## 0.2.7

- Update the flare_flutter package version to fix build issue(https://github.com/FilledStacks/smart_flare/issues/7).

## 0.2.6

- Added playStartingAnimationWhenRebuilt to SmartFlareActor to control if the starting animation is played coming back from a navigation
- Added a new TapController to better manage the last played animations, specifically for active areas with a list of cycle animations.

## 0.2.5

- Added completeOnThresholdReached to PanFlareActor to indicate that we want the animation to play until completion once we reach the defined threshold
- Made sure the animation always starts of at the correct place when the actor is shown for the first time.

## 0.2.2

- Fixed Some weird overriding crash for flare controls play function.

## 0.2.1

- Refactored the PanFlareActor to use the SmartFlareActor and it's interactive areas
- Added a new ActiveArea type called RelativePanArea which extends the RelativeActiveArea. _Normal pan area coming soon_
- Debugable areas show different colors depending on the area type. Tap areas show blue, draggable/pannable areas show red

## 0.2.0

- **PanFlareActor:** Added the new PanFlareActor that allows you to advance your Flare animation by panning accross the device. It comes with a few basic things like reversing on release, a threshold to indicate when to play animatin to the end, swiping direction, using an open and close animation or just open that can be reversed.

- **Code Refactor:** Moved the actors into their own folder to keep code more maintainable.

## 0.1.0

- New CycleFlareActor that you supply a list of animations too and it will cycle through them as you tap on it.
- **Relative Active Areas**: You can now place your active areas using coordinates relative to your animations dimensions.

## 0.0.1

Basic interactions and debug overlay functionality.
