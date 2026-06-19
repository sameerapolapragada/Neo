import { Image } from 'expo-image';
import { StyleSheet, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

const HERO_IMAGE = require('@/assets/images/add-milestone-hero.png');

export function QuickAddMilestoneHero() {
  return (
    <View style={styles.wrap}>
      <View style={styles.circle}>
        <Image
          source={HERO_IMAGE}
          style={styles.image}
          contentFit="contain"
          accessibilityLabel="Gold medal milestone icon"
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    marginBottom: 20,
  },
  circle: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: AuthColors.weightBadgeBackground,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  image: {
    width: 72,
    height: 72,
  },
});
