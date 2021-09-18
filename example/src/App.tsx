import * as React from 'react';
import {
  StyleSheet,
  View,
  Alert,
  Text,
  SafeAreaView,
  Animated,
  Dimensions,
  Platform,
  TouchableOpacity,
} from 'react-native';
//@ts-ignore
import { Camera, CameraFace, TorchMode } from 'new-rn-camera';

import Rotate from './icons/Rotate';
import LightBulb from './icons/LightBulb';

export default function App() {
  const camera = React.useRef<Camera>(null);
  const animatedZoom = React.useRef(new Animated.Value(0)).current;

  const [cameraPermission, setCameraPermission] = React.useState(false);
  const [storagePermission, setStoragePermission] = React.useState(false);
  const [zoom, setZoom] = React.useState(0);
  const [face, setFace] = React.useState<CameraFace>(CameraFace.back);
  const [torch, setTorch] = React.useState<TorchMode>(TorchMode.off);

  React.useEffect(() => {
    (async () => {
      setCameraPermission(await Camera.requestCameraPermissionsAsync());
      setStoragePermission(await Camera.requestStoragePermissionsAsync());
    })();
  }, []);

  React.useEffect(() => {
    animatedZoom.addListener(({ value }) => setZoom(value));
  }, []);

  const zoomIn = () => {
    Animated.timing(animatedZoom, {
      toValue: 0.8,
      duration: 500,
      useNativeDriver: true,
    }).start();
  };
  const zoomOut = () => {
    Animated.timing(animatedZoom, {
      toValue: 0,
      duration: 400,
      useNativeDriver: true,
    }).start();
  };

  return cameraPermission ? (
    <View style={styles.container}>
      <Camera
        ref={camera}
        style={styles.cameraView}
        zoom={zoom}
        cameraFacing={face}
        torch={torch}
      />
      <View style={styles.interactionContainer}>
        <ZoomView zoom={zoom} zoomIn={zoomIn} zoomOut={zoomOut} />
        <SafeAreaView
          style={[
            styles.bottomButtonContainer,
            Platform.OS === 'android' ? { paddingBottom: 8 } : {},
          ]}
        >
          <TouchableOpacity
            onPress={() => {
              setTorch(torch === TorchMode.off ? TorchMode.on : TorchMode.off);
            }}
          >
            <LightBulb />
          </TouchableOpacity>
          <TouchableOpacity
            onPress={async () => {
              if (!storagePermission) {
                Alert.alert('Cannot save images without storage permission.');
                return;
              }
              const result = await camera.current?.takePictureAsync();
              console.log(result);
              if (result)
                Alert.alert('Successfully saved image to ' + result.uri);
            }}
          >
            <View style={styles.outerCircle}>
              <View style={styles.innerCircle} />
            </View>
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => {
              setFace(
                face === CameraFace.back ? CameraFace.front : CameraFace.back
              );
            }}
          >
            <Rotate />
          </TouchableOpacity>
        </SafeAreaView>
      </View>
    </View>
  ) : (
    <MissingCameraPermission />
  );
}

const ZoomView = (props: any) => (
  <View style={styles.zoomViewContainer}>
    <TouchableOpacity
      style={[
        styles.zoomButton,
        { marginLeft: 8, marginRight: 3 },
        props.zoom === 0 ? { backgroundColor: '#00000060' } : {},
      ]}
      onPress={props.zoomOut}
    >
      <Text style={styles.zoomText}>1x</Text>
    </TouchableOpacity>
    <TouchableOpacity
      style={[
        styles.zoomButton,
        { marginRight: 8, marginLeft: 3 },
        props.zoom === 0 ? {} : { backgroundColor: '#00000060' },
      ]}
      onPress={props.zoomIn}
    >
      <Text style={styles.zoomText}>2x</Text>
    </TouchableOpacity>
  </View>
);

const MissingCameraPermission = () => (
  <View style={{ flex: 1, justifyContent: 'center' }}>
    <Text style={{ textAlign: 'center' }}>
      Please grant camera permissions.
    </Text>
  </View>
);

const { width, height } = Dimensions.get('window');

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'flex-end' },
  cameraView: {
    flex: 1,
    position: 'absolute',
    top: 0,
    left: 0,
    width,
    height,
  },
  interactionContainer: {
    flexBasis: 'auto',
    justifyContent: 'flex-end',
  },
  bottomButtonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#00000080',
    alignItems: 'center',
  },
  outerCircle: {
    marginTop: 10,
    borderRadius: 40,
    width: 80,
    height: 80,
    backgroundColor: 'grey',
  },
  innerCircle: {
    borderRadius: 35,
    width: 70,
    height: 70,
    margin: 5,
    backgroundColor: 'white',
  },
  zoomViewContainer: {
    alignSelf: 'center',
    marginBottom: 10,
    width: 100,
    paddingVertical: 4,
    flexDirection: 'row',
    alignContent: 'space-around',
    backgroundColor: '#00000040',
    borderRadius: 30,
  },
  zoomButton: {
    flex: 1,
    borderRadius: 20,
    paddingVertical: 8,
  },
  zoomText: { color: 'white', textAlign: 'center' },
});
