import * as React from 'react';
import {
  findNodeHandle,
  NativeModules,
  Platform,
  PermissionsAndroid,
} from 'react-native';

import CameraView from './NewRNCameraViewManager';

import type { CameraProps, ImageResult } from './Camera.types';

const iOSCameraModule = NativeModules.NewRNCameraViewManager;
const AndroidCameraModule = NativeModules.NewRNCameraModule;

export default class Camera extends React.Component<CameraProps> {
  static defaultProps: CameraProps = {
    zoom: 0,
    torch: 'off',
    cameraFacing: 'back',
  };

  _cameraHandle?: number | null;
  _cameraRef?: React.Component | null;

  async takePictureAsync(): Promise<ImageResult> {
    return Platform.OS === 'android'
      ? await AndroidCameraModule.capture(this._cameraHandle)
      : await iOSCameraModule.capture();
  }

  static async requestCameraPermissionsAsync(): Promise<boolean> {
    return Platform.OS === 'android'
      ? await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA)
      : await iOSCameraModule.requestCameraPermissions();
  }

  static async requestStoragePermissionsAsync(): Promise<boolean> {
    return Platform.OS === 'android'
      ? await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE
        )
      : await iOSCameraModule.requestStoragePermissions();
  }

  _setReference = (ref?: React.Component) => {
    if (ref) {
      this._cameraRef = ref;
      this._cameraHandle = findNodeHandle(ref);
    } else {
      this._cameraRef = null;
      this._cameraHandle = null;
    }
  };

  render() {
    return <CameraView {...this.props} ref={this._setReference} />;
  }
}
