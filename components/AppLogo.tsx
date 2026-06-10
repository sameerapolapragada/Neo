import { Image, ImageStyle } from 'expo-image';
import { StyleProp, StyleSheet, View, ViewStyle } from 'react-native';

import { useResponsive } from '@/hooks/useResponsive';

const logoSource = require('@/assets/images/logo.png');

interface AppLogoProps {
  width?: number;
  style?: StyleProp<ViewStyle>;
  imageStyle?: StyleProp<ImageStyle>;
}

export function AppLogo({ width, style, imageStyle }: AppLogoProps) {
  const { width: screenWidth, isSmall, isLarge } = useResponsive();
  const logoWidth =
    width ?? (isSmall ? screenWidth * 0.62 : isLarge ? 320 : Math.min(screenWidth * 0.68, 300));

  return (
    <View style={[styles.wrap, { width: logoWidth }, style]}>
      <Image
        source={logoSource}
        style={[styles.image, { width: logoWidth, height: logoWidth }, imageStyle]}
        contentFit="contain"
        accessibilityLabel="Neo logo"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  image: {
    aspectRatio: 1,
  },
});
