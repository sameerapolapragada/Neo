import { Image } from 'expo-image';
import { StyleSheet, useWindowDimensions, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

const LOGO = require('@/assets/images/logo.png');

export function AuthLandingHero() {
  const { width, height } = useWindowDimensions();
  const heroHeight = Math.max(height * 0.46, 280);

  return (
    <View style={[styles.wrap, { width, height: heroHeight }]}>
      <Image
        source={LOGO}
        style={styles.logo}
        contentFit="contain"
        accessibilityLabel="Neo logo"
      />
    </View>
  );
}

export function AuthLogoBackground() {
  return (
    <Image
      source={LOGO}
      style={StyleSheet.absoluteFill}
      contentFit="contain"
      accessibilityLabel="Neo logo"
    />
  );
}

const styles = StyleSheet.create({
  wrap: {
    overflow: 'hidden',
    backgroundColor: AuthColors.emptyTimelineBackground,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  logo: {
    width: '100%',
    height: '100%',
    maxWidth: 320,
    maxHeight: 320,
  },
});
