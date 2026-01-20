# ChangeLog

## Version 2.9.3-dev

### Common

- Rename project to `cordova-plugin-google-maps-sdk`
  - This makes clear, what this plugin is about and maybe it's better not to have a number in the plugin name like it was before: `cordova-plugin-googlemaps-2`

### iOS

- Update Google Maps SDK from 10.4.0 to 10.6.0
  - You need to do a `pod repo update` in `platforms/ios` before updating the plugin
  - Fixes:
    - QoS (Quality of Service) Inversion Warning fixed.


## Version 2.9.2 (12.10.2025)

### iOS
- Update Google Maps SDK from 10.0.0 to 10.4.0
  - If you upgrade the plugin, you have first to upgrade the pod repo in `platforms/ios` by executing `pod repo update`. Than you can remove and re-add the plugin, to update it.
- Fix XCode warnings:
  - Update parameter descriptions in code documentation:
    - `@params` often declared a wrong parameter
    - Document the content of the command parameter
  - Add missing class cast `CordovaGoogleMaps` for `[cdvViewController getCommandInstance:@"CordovaGoogleMaps"]`
    - Fixes warning: `Incompatible pointer types initializing 'CordovaGoogleMaps *' with an expression of type 'CDVPlugin * _Nullable'`
  - Init `CLLocationCoordinate2D` variables with `kCLLocationCoordinate2DInvalid`
    - Check if variable is valid by `CLLocationCoordinate2DIsValid()`
- Make plugin compatible with `cordova-ios` 8.0.0
  - Call `[CDVViewController registerPlugin:withPluginName:]` instead calling private properties
    - Since cordova-ios 8 the properties `pluginObjects` and `pluginsMap` in `CDVViewController` are deprecated and should not be used anymore. `[CDVViewController registerPlugin:withPluginName:]` is used, when `setObject` or `setValue` was called on these deprecated properties before.
    - Removed deregistering of pseudo map plugins in`pluginUnload` by using private properties `pluginObjects` and `pluginsMap` of `CDVViewController`. There is no equivalent method in `CDVViewController` for deregister a plugin. The plugin was tested to make sure, that it doesn't break anything.
  - Don't import `MainViewController.h` in `PluginUtil.h`
    - Fixes warning: `It is unsafe to rely on the MainViewController class as an extension point. Update your code to extend CDVViewController instead. This code will stop working in Cordova iOS 9!`
  - Use `performSelector` for `scrollView` of `webView`
    - Fixes deprecation warning of direct property access of `webView.scrollView` in cordova-ios 8.x. Cordova will remove the `scrollView` property added as a global category extension to `UIView` in the future.
- Code cleaning
    - Clean up whitespace and improve code readability

## Version 2.9.1 (03.09.2025)

### Android

- Replace TBXML library with native Anroid `XmlPullParser`
  - The TBXML library produces a warning in Google Play Console that an app does not support 16 KB page sizes
  - It's not necessary to use a third party library for parsing XML files, so it's not necessary to support that library still
  - TBXML was used to read KML files, which is now handled by `XmlPullParser`

## Version 2.9.0 (06.08.2025)

### Android
- Build cleanups:
  - Let Google Maps SDK specify the version for `com.android.volley`: The version used for com.android.volley was sepcified in tbxml-android.gradle manually to 1.2.1. This was needed when using the old Google Maps SDK com.google.android.libraries.maps:maps:3.1.0-beta which pointed to version 1.1.1 and which was no longer available online. Since the latest Google Maps SDK is used, it will point by itself to a more recent version.
  - Copy tbxml-android.aar only once: tbxml-android.aar was copied to two paths: `app/src/main/libs` and `app/src/main/app/src/libs`. The second copy was useless and also wrong. Use the first path only.
  - Remove unnecessary repositories from tbxml-android.gradle
    - The default repositories for google and mavenCentral are already defined by cordova-android
    - Removes a gradle warning: Deprecated Gradle features were used in this build, making it incompatible with Gradle 9.0, because `url 'https://maven.google.com'` would have to be `url = 'https://maven.google.com'`
  - Remove `compileSdkVersion` and `packagingOptions` from tbxml-android.gradle
    - `compileSdkVersion` is set by cordova-android
    - Removed `packagingOptions` for excluding `README` and `LICENSE`. This should not be done here and it is not sure if this works and will bring a benefit.
  - Don't use `flatDir` in `tbxml-android.gradle`: Using `flatDir` produces the warning `Using flatDir should be avoided because it doesn't support any meta-data formats.`. Instead android source sets will be used.

### iOS
- Upgrade Google Maps SDK from version 9.3.0 to 10.0.0
- Use Metal renderer also for simulator instead of OpenGL
- Remove WebKit redraw hack
  - Removed `document.body.style.transform = 'rotateZ(0deg)';` from `Map.js` from `Map.refreshLayout` and `Map.setDiv`, which was used to for force WebKit browsers to perform a repaint/redraw, because in older WebKit browsers (Safari, early Chrome), certain DOM manipulations or CSS changes wouldn't trigger a visual update immediately, causing rendering glitches or elements appearing "stuck" in their old positions.
  - This fix is no longer needed in modern WebKit Browsers and caused issues on Chrome on Android, see https://github.com/GitToTheHub/cordova-plugin-google-maps-sdk/issues/19

## Version 2.8.1 (05.07.2025)

### Android
- Don't set backround color on div change: It could happen, that an undefined background color was set, which lead to a black background. Now nothing will be set on the div

### iOS
- Add `deployment-target` with `15.5` to `config.xml`, when user didn't set something. Google Maps SDK for iOS 9.3.0 needs minimum iOS 15 as deployment target.
- Don't set backround color on div change: It could happen, that an undefined background color was set, which lead to a black background. Now nothing will be set on the div

### Browser
- feat: option to add mapId when using browser maps: Since Google Maps pricing already includes the SKU: [Dynamic Maps (with or without a map ID using the Maps JavaScript API)](https://developers.google.com/maps/billing-and-pricing/sku-details#dynamic-maps-ess-sku), and with the latest JS SDK the plugin’s tilt option doesn’t work because [WebGL (Vector maps) requires a map ID](https://developers.google.com/maps/documentation/javascript/map-ids/mapid-over), users should have the option to include one. Thanks to [leyenda](https://github.com/leyenda).
- fix: browser cluster icon opacity: Eliminates the conflicting pull on iconMarker's opacity and establishes a clear path for opacity changes originating from self [PR #11](https://github.com/GitToTheHub/cordova-plugin-google-maps-sdk/pull/11). Thanks to [leyenda](https://github.com/leyenda).

## Version 2.8.0 (24.03.2025)

### Android
- Gradle: Remove obsolete repository jcenter
  - JCenter sunset was on August 15th, 2024. mavenCentral will be used instead.
  - The appeareance of jcenter as a repository, produced the gradle warning "Deprecated Gradle features were used in this build, making it incompatible with Gradle 9.0."
- Use pure Android X and latest Google Maps SDK
  - Change Imports for Android Support Library to Android X
  - Remove Plugin dependency cordova-androidx-build from plugin.xml. This is not needed anymore.
  - Raise android-minSdkVersion from 19 to 21. This was needed for this PR.
  - Remove 'com.android.support:multidex:1.0.3' from pgm-custom.gradle. This was needed, when the minSdkVersion was lower then 21.
  - Use original Google Maps SDK dependencies again and not any longer a deprecated and decommissioned beta version
  - Google Maps SDK dependencies versions are configurable again with GOOGLE_MAPS_PLAY_SERVICES_VERSION and GOOGLE_MAPS_PLAY_SERVICES_LOCATION_VERSION
  - Cleanup of pgm-custom.gradle
- Fixes Build Error: Could not find com.android.volley:volley:1.1.1.
  - Use implementation 'com.android.volley:volley:1.2.1'
- Fix: Invalid <color> for given resource value.
  - For the deprecated Crosswalk WebView, the preference key "BackgroundColor" was wrongly set with "0". It would have to be set with "#000000", but this would also set the splashscreen backround color to black. So the preference is removed.
- Fix: uses-sdk:minSdkVersion 19 cannot be smaller than version 21 declared in library [androidx.core:core-splashscreen:1.0.0]
  - In plugin.xml "android-minSdkVersion" ist set to 19 for the config.xml and must be set to 21, because the referenced Library "androidx.core:core-splashscreen:1.0.0" defines minSdkVersion to 21. Both cannot live side by side.
- Resolve blank map when running compiled with latest cordova-android (which uses AGP 4.1.3)

## iOS
- Add Google Maps SDK Version 9.3.0 with Cocoapods
  - Google Maps can now be tested in the simulator
- Fix misplaced or white splash screen
  - The splash screen on iOS was misplaced or was not appearing. To fix this, the views will not be removed anymore from the view hierarchy and the plugin layer will be send only to the front, when the splash screen is dismissed.
- Fix all warnings when using `cordova-ios` 7
  - Remove reference of `CDVCommandDelegateImpl`
    - Since `cordova-ios` 7.x. `CDVCommandDelegateImpl` is private and no longer public
  - Remove deprecated `extra.address` from `Geocoder.geocode` result
    - `CLPlacemark.addressDictionary` is deprecated and was used for this field
  - PluginLocationService.m: Support for iOS 14 
    - On iOS 14 [CLLocationManager authorizationStatus] is deprecated and instead [CLLocationManager new].authorizationStatus should be called
  - Remove unused methods from PluginDirectionsService.h. Seems to be a leftover from copy & paste of PluginElevationService.h
  - Use GMSMapViewOptions for init GMSMapView since iOS 14 and Google Maps SDK 8.3.0
    - [GMSMapView mapWithFrame] is deprecated, use only on iOS 13 and Google Maps SDK older then 8.3.0
  - Fix warnings "A block declaration without a prototype is deprecated"
    - void had to be added to all these statements (proposed fix by XCode)
  - Remove unused method PluginUtil.urlencode
  - Add PluginCAAnimationDelegate for markers: The animationDelegate for markers was not set to a real delegate and was giving a warning. The CAAnimationGroup was overwritten and set as delegate, but was not implementing the CAAnimationDelegate. Now a  custom delegate is created which calls the completion block.
  - Define nullability for property and parameters in PluginStreetViewPanoramaController.h
    - XCode has issued a warning, that the nullability was not defined for the panoramaView property and parameters

## Common
- Add: (Android/iOS/Browser) `mapOptions.preferences.restriction` which is able to set the camera bounds.
- Add: (Android/iOS/Browser) `mapOptions.preferences.clickableIcons` which is able to be disable clicking on POI icons.
- Bug fix: (Android/iOS/Browser) `mapOptions.preferences.building` does not work.
- Add: (Android/iOS/Browser) ElevationService
- Add: (Android/iOS/Browser) DirectionsService and `map.addDirectionsRenderer()`
- Change: (Android/iOS/Browser) `map.setDiv()`, `map.setOptions()` returns `Promise`.
- Change: (Android/iOS/Browser) Hides `__pluginDomId` and `__pluginMapId` properties.

## 2.7.1

- Fix: (iOS) UiWebView references present in v2.7.0

## 2.7.0

- Re-adoption: cordova-plugin-googlemaps-sdk dependency
- Important update: No longer support UIWebView on iOS. WKWebView only.
- Fix: (iOS) Can't load image files from local host on ionic 4 / 5
- Update: (Android) prevent null pointer error in AsyncLoadImage.java
- Fix: Css animation interference when call setDiv and there is a push/pop page
- Fix: (Android/iOS/Browser) KML parser crash
- Fix: flickering and wrong rendering of some DOM elements
- Add: map.stopAnimation()
- Fix: can't remove map while map.animateCamera() is running
- Update: (Android) Increase cache memory size
- Update: (Android/iOS) Danish localization
- Fix: (Android) Prevent resize event after map.setDiv(null)
- Fix: (Android/iOS) Can not interactive with the map inside
- Fix: jslint errors
- Fix: marker.setIcon crashes
- Update: Set default value range to heading and tilt
- Fix: (Android/iOS) touch detection is wrong after clicking on back button very soon.
- Fix: An error occurs when you click a marker of marker cluster #2660
- Remove promise-7.0.4-min.js.map
- Fix: (iOS) bug fix: App crashes if "bearing" property is ""
- Fix: HTMLColor2RGBA() converts to incorrect value
- Fix: (Android) Can't load marker image from the Internet
- many bug fixes...
