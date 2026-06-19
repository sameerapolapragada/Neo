import { Image } from 'expo-image';
import { StyleSheet, useWindowDimensions, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

export function OnboardingHero() {
  const { width } = useWindowDimensions();
  const heroWidth = Math.min(width - 96, 320);
  const heroHeight = heroWidth * 0.82;

  return (
    <View style={[styles.wrap, { width: heroWidth, height: heroHeight }]}>
      <Image
        source={require('@/assets/images/onboarding-hero.jpg')}
        style={styles.image}
        contentFit="cover"
        accessibilityLabel="Golden retriever puppy running outdoors"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignSelf: 'center',
    marginTop: 20,
    marginBottom: 8,
    borderRadius: 24,
    overflow: 'hidden',
    shadowColor: AuthColors.primary,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.12,
    shadowRadius: 16,
    elevation: 4,
  },
  image: {
    width: '100%',
    height: '100%',
  },
});
