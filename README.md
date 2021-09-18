# new-rn-camera

Hi! This was just a fun and challenging task. I didn't have much experience with native _UI_ components before this, and the camera is such a huge part of so many mobile apps, I thought it was worth just putting together a quick native module to get a sense of the native platform APIs.

Don't care about anything and just wanna try it out? [Skip to here](#installation&setup).

### Goals & scope

- Zoom control with a pinch gesture ✅
- Zoom control with a toggle ✅
- Auto-focus/exposure control with touch coordinates ✅
- Toggle for the front/back camera ✅
- Toggle for the flashlight ✅

Some personal goals:

- Use Android CameraX
  - Some of the complications here were that most of Google's own examples were using their now deprecated Camera module
- Minimize code and maximize readability
- Use Kotlin
- Use no deprecated classes or methods on iOS (no sidebar warnings when building)

### Limitations and challenges

- Had quite a bit of trouble getting started with CameraX on Android
  - I like to work by getting _something_ functioning (first achieve a displayed Camera preview), and then organizing and moving forward from there. That preview took longer than I expected due to a React Native bug: https://github.com/facebook/react-native/issues/17968. After adding that, "poof" it worked.
  - CameraX API is pretty great once you're set up 👍
- Android permissions take a lot more code to set up than iOS. Put together a scrap implementation for development, then realized that relying directly on React Native's AndroidPermissions API was much more suitable for now. Doesn't look like it's worth building out a custom implementation.
  - For reference, iOS permissions took ~20 lines of code. One direct method
- Not a fully thought out story once you have the image because I'm not sure if it's an image we want to save to an album specifically in the app, or save to the user's media library directly

### Future work

- Crop module
- Refine zoom factors
- Add support for negative zoom for compatible devices
- Gain a better understanding of Android camera apps & how users prefer them to work
- Built in Animated support for zooming? (that's also overrideable)
- More file output options?

## Installation & setup

```sh
yarn add new-rn-camera // This module isn't available on npm yet, you'll have to install it from source
npx pod-install
```

### Android

Android requires some additional permissions declared in your `AndroidManifest.xml` file:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="your.package.name">
          ...
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

iOS requires some additional permissions declared in your `info.plist` file:

```xml
<key>NSCameraUsageDescription</key>
<string>Allow $(PRODUCT_NAME) to use the camera</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Allow $(PRODUCT_NAME) to use the microphone</string>
```

## Usage

```js
import { Camera } from 'new-rn-camera';

// ...

<Camera
  ref={camera}
  style={styles.box}
  zoom={zoom}
  cameraFacing={face}
  torch={torch}
/>;
```

Please see the `example/src/App.tsx` file for a full example.

If you'd like to run the example locally:

- clone this repo
- `cd example/`
- `yarn && npx pod-install`
- `yarn android` or `yarn ios`

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
