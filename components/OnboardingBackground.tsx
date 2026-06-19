import { StyleSheet, Text, useWindowDimensions, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

export function OnboardingBackground() {
  const { width, height } = useWindowDimensions();
  const hillHeight = Math.max(height * 0.26, 180);

  return (
    <View style={styles.container} pointerEvents="none">
      <Text style={[styles.heart, { top: height * 0.2, left: width * 0.1 }]}>❤️</Text>
      <Text style={[styles.paw, { top: height * 0.36, right: width * 0.12 }]}>🐾</Text>

      <View style={[styles.hill, { height: hillHeight }]}>
        <View style={styles.hillWave} />
        <Text style={[styles.plant, { left: width * 0.08, bottom: hillHeight * 0.35 }]}>🌿</Text>
        <Text style={[styles.plant, { left: width * 0.22, bottom: hillHeight * 0.22 }]}>🌱</Text>
        <Text style={[styles.plant, { right: width * 0.18, bottom: hillHeight * 0.3 }]}>🌿</Text>
        <Text style={[styles.plant, { right: width * 0.06, bottom: hillHeight * 0.18 }]}>🌱</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 0,
  },
  heart: {
    position: 'absolute',
    fontSize: 18,
    opacity: 0.85,
  },
  paw: {
    position: 'absolute',
    fontSize: 22,
    opacity: 0.45,
  },
  hill: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: AuthColors.accentSoft,
    borderTopLeftRadius: 280,
    borderTopRightRadius: 280,
    overflow: 'hidden',
  },
  hillWave: {
    position: 'absolute',
    top: -40,
    left: -40,
    right: -40,
    height: 80,
    backgroundColor: AuthColors.primarySoft,
    borderBottomLeftRadius: 200,
    borderBottomRightRadius: 200,
    opacity: 0.85,
  },
  plant: {
    position: 'absolute',
    fontSize: 28,
    opacity: 0.55,
  },
});
