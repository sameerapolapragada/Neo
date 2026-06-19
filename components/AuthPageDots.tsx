import { StyleSheet, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

interface AuthPageDotsProps {
  activeIndex?: number;
  count?: number;
}

export function AuthPageDots({ activeIndex = 0, count = 3 }: AuthPageDotsProps) {
  return (
    <View style={styles.wrap}>
      {Array.from({ length: count }, (_, index) =>
        index === activeIndex ? (
          <View key={index} style={styles.active} />
        ) : (
          <View key={index} style={styles.inactive} />
        ),
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 6,
    marginTop: 8,
  },
  active: {
    width: 24,
    height: 6,
    borderRadius: 999,
    backgroundColor: AuthColors.onboardingPrimary,
  },
  inactive: {
    width: 6,
    height: 6,
    borderRadius: 999,
    backgroundColor: AuthColors.border,
  },
});
