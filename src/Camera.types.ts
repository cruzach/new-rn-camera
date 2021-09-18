import type { ViewProps } from 'react-native';

export type CapturedPicture = {
  width: number;
  height: number;
  uri: string;
};

export enum TorchMode {
  on = 'on',
  off = 'off',
}

export enum CameraFace {
  front = 'front',
  back = 'back',
}

export type CameraNativeProps = {
  pointerEvents?: any;
  style?: any;
  ref?: Function;
  type?: keyof typeof CameraFace;
  torch?: keyof typeof TorchMode;
  zoom?: number;
};

export type CameraProps = ViewProps & {
  cameraFacing?: keyof typeof CameraFace;
  torch?: keyof typeof TorchMode;
  zoom?: number;
};

export type ImageResult = {
  uri: string;
  height: number;
  width: number;
};
