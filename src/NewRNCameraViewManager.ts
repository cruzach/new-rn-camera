import { requireNativeComponent } from 'react-native';

import type { CameraNativeProps } from './Camera.types';

export const NewRNCameraViewManager: React.ComponentType<CameraNativeProps> =
  requireNativeComponent<CameraNativeProps>('NewRNCameraView');

export default NewRNCameraViewManager;
