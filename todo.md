Use this revised prompt to implement real-time walking navigation in both applications:

```text
Implement matching real-time walking navigation in both:

- `sabasaba_nextjs`
- `sabasaba_mobile_app`

Neither application currently supports live route progress or wrong-way detection. Inspect both codebases and implement the feature consistently while respecting their different map technologies:

- Next.js uses Leaflet and browser geolocation.
- Flutter uses its custom map canvas and Geolocator.

Goal:
When a user follows a displayed route, update the route continuously, remove the completed section, reduce the remaining distance/time, detect off-route or wrong-direction movement, and offer rerouting.

The two applications must behave as similarly as possible.

1. Shared navigation behavior

Implement the same navigation states in both applications:

- `idle`
- `locating`
- `navigating`
- `offRoute`
- `wrongDirection`
- `rerouting`
- `arrived`
- `error`

Use equivalent configurable thresholds in TypeScript and Dart.

2. Start a navigation session

When navigation begins:

- Obtain a reliable GPS position.
- Build the complete route from the user’s position to the selected destination.
- For an off-site user, route from GPS to SabaSaba Gate 1 and then follow the fairground routing graph to the destination.
- For an on-site user, route from the nearest valid fairground routing node to the destination.
- Do not force an on-site user to return to Gate 1.
- Never create direct fallback lines through buildings.
- If no valid route is available, show an error instead of inventing a line.
//////////////////////////////


3. Live GPS tracking

Next.js:

- Use `navigator.geolocation.watchPosition`.
- Use high accuracy.
- Properly clear the watch when navigation stops, the destination changes, the component unmounts, or arrival occurs.

Flutter:

- Use `Geolocator.getPositionStream`.
- Use high accuracy and a distance filter of approximately 2–5 metres.
- Cancel the stream when navigation stops, the destination changes, the screen is disposed, or arrival occurs.

Both:

- Track latitude, longitude, accuracy, heading, speed and timestamp when available.
- Ignore invalid coordinates and stale readings.
- Do not use unreliable readings for route decisions when accuracy is worse than approximately 30 metres.
- Continue displaying the accuracy circle.

/////////////////
4. Match the user to the route

Create testable route-matching utilities in both languages.

Suggested TypeScript modules:

- `navigation-session.ts`
- `polyline-matcher.ts`
- `off-route-detector.ts`
- `route-progress.ts`

Suggested Dart files/classes:

- `navigation_session.dart`
- `PolylineMatcher`
- `OffRouteDetector`
- `RouteProgress`

For every reliable GPS reading:

- Find the nearest projected point on the active route polyline.
- Determine the distance between GPS and the projected route point.
- Determine how far along the complete route the projected point occurs.
- Calculate completed distance.
- Calculate remaining distance.
- Produce a remaining route polyline beginning at the projected position.
- Preserve the correct order of route coordinates.
- Prevent progress from jumping backwards because of minor GPS noise.

Use geographic distance calculations rather than raw latitude/longitude subtraction.

//////////////////


5. Shrink the route while walking

As the user moves forward:

- Remove the completed route section from the highlighted route.
- Draw the remaining route from the projected current position to the destination.
- Update remaining distance and estimated walking time.
- Keep the original route available internally for matching and recovery.
- Optionally draw the completed section using a muted colour, but it must not look like the remaining route.
- Ensure the remaining route never gains synthetic segments through buildings.

Next.js:

- Update the Leaflet polyline with `setLatLngs`.
- Avoid destroying and recreating the whole map.

Flutter:

- Update navigation state and repaint `ExhibitionMapPainter`.
- Ensure `shouldRepaint` includes every live navigation field.
- Do not refetch map data for every GPS reading.

6. Off-route detection

Do not trigger an off-route warning from one GPS reading.

Mark the user off-route only when:

- At least three consecutive reliable readings are outside the route corridor.
- The distance from the route exceeds a configurable threshold, initially 20 metres.
- GPS accuracy is good enough to support the decision.

Use an accuracy-aware threshold, for example:

`effectiveThreshold = max(configuredThreshold, gpsAccuracy * 1.25)`

Clear off-route status only after at least two consecutive reliable readings return inside the recovery threshold.

Use separate enter and exit thresholds to prevent warning flicker.

7. Wrong-direction detection

Detect when the user is following the route in reverse or consistently moving away from the destination.

Use route progress as the primary signal:

- Compare the current along-route progress with recent progress.
- Ignore backward changes smaller than a GPS-noise tolerance.
- Only evaluate direction when the user has moved a meaningful distance.
- Trigger wrong direction only after at least three reliable readings show meaningful backward progress.
- Do not trigger while the user is stationary.
- Use heading as supporting evidence only.
- Do not rely only on the compass.

Show messages such as:

- “You are moving away from the destination.”
- “This is not the required direction.”
- “Turn back toward the highlighted route.”

////////////////////////

8. Warning interface

Implement equivalent warnings in Next.js and Flutter:

- Show a non-blocking amber warning for possible wrong direction.
- Show a red warning for confirmed off-route status.
- Change the live-location/navigation indicator colour while off-route.
- Display a wrong-way or warning icon.
- Include a “Recalculate route” action.
- Announce when the user returns to the route.
- Do not repeatedly display dialogs for every GPS update.

Flutter may provide one vibration when off-route is first confirmed. Do not vibrate repeatedly.

Ensure warnings are accessible and readable on mobile and desktop screens.

9. Automatic rerouting

Support manual and automatic rerouting.

- Rate-limit automatic rerouting.
- Do not make a routing request on every location update.
- Reroute only after off-route status remains confirmed for a configurable duration or number of readings.
- Cancel or ignore stale routing responses.
- Preserve the selected destination.

Outside SabaSaba:

- Recalculate the road or pedestrian route from the newest reliable GPS position to Gate 1.
- Use an appropriate walking routing profile if the configured provider supports it.
- If public OSRM only supports driving on the deployed profile, keep the travel mode explicit and do not falsely label a driving route as walking.

Inside SabaSaba:

- Find a valid nearby reachable routing node.
- Calculate a new graph route to the destination.
- Never connect the GPS point directly through a building.
- If needed, show the GPS marker separately from the graph route until the visitor reaches the mapped path.

10. Arrival detection

Mark the user as arrived when:

- A reliable reading is within approximately 8–12 metres of the destination.
- Preferably require two consecutive arrival readings.

Show:

“You have arrived at [destination name].”

After arrival:

- Set the session state to `arrived`.
- Clear off-route and wrong-direction warnings.
- Stop automatic rerouting.
- Optionally stop location watching after the user dismisses the arrival message.

11. Route summary

Update the route summary in both applications with:

- Current navigation state.
- Remaining distance.
- Estimated remaining time.
- Destination name.
- Off-site road distance when applicable.
- Fairground walking distance.
- A clear “Stop Navigation” action.

Distance and time must decrease as the user progresses.

12. Consistency between applications

Use the same:

- State names.
- Threshold defaults.
- Consecutive-reading rules.
- Progress logic.
- Off-route recovery behavior.
- User-facing messages where practical.
- Route and warning colours.

Document any platform-specific differences.

Avoid duplicating inconsistent formulas. Add shared specification comments or documentation describing the algorithm used by both implementations.

13. Performance and lifecycle

- Throttle visual updates when necessary.
- Do not rebuild all map layers for each GPS reading.
- Do not continuously refetch exhibition data.
- Avoid duplicate geolocation subscriptions.
- Ignore updates after components or widgets are disposed.
- Cancel pending route requests when navigation stops or the destination changes.
- Prevent old requests from overwriting newer routes.

14. Privacy

Both applications currently use live coordinates for route calculation.

- Send coordinates only while the user actively requests navigation.
- Clearly document which external routing service receives coordinates.
- Stop external routing requests when navigation ends.
- Do not store location history unless explicitly required.
- Do not add analytics containing precise coordinates.

15. Testing

Add equivalent TypeScript and Dart tests for:

- Projection onto a route segment.
- Along-route progress calculation.
- Remaining-polyline trimming.
- Remaining-distance calculation.
- Forward walking progress.
- Minor GPS backward noise.
- Confirmed wrong-direction movement.
- Stationary user behavior.
- Single inaccurate off-route reading.
- Consecutive off-route readings.
- Recovery after returning to the route.
- Arrival detection.
- On-site versus off-site routing.
- Stale rerouting responses.
- No synthetic lines through buildings.
- Cleanup of geolocation subscriptions.

Next.js validation:

- Run formatting/linting.
- Run route/navigation unit tests.
- Run the production build.

Flutter validation:

- Run `dart format`.
- Run `flutter analyze`.
- Run `flutter test`.
- Build the Android application if the environment supports it.

