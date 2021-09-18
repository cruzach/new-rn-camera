import React from 'react';
import { Svg, Path } from 'react-native-svg';

export default function LightBulb() {
  return (
    <Svg width={24} height={24} viewBox="0 0 24 24">
      <Path
        d="M20 11h3v2h-3v-2M1 11h3v2H1v-2M13 1v3h-2V1h2M4.92 3.5l2.13 2.14l-1.42 1.41L3.5 4.93L4.92 3.5m12.03 2.13l2.12-2.13l1.43 1.43l-2.13 2.12l-1.42-1.42M12 6a6 6 0 0 1 6 6c0 2.22-1.21 4.16-3 5.2V19a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-1.8c-1.79-1.04-3-2.98-3-5.2a6 6 0 0 1 6-6m2 15v1a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-1h4m-3-3h2v-2.13c1.73-.44 3-2.01 3-3.87a4 4 0 0 0-4-4a4 4 0 0 0-4 4c0 1.86 1.27 3.43 3 3.87V18z"
        fill="white"
      />
    </Svg>
  );
}
