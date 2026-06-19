import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface NeoWordmarkProps {
  size?: 'large' | 'medium' | 'small';
  variant?: 'default' | 'onboarding';
}

export function NeoWordmark({ size = 'large', variant = 'default' }: NeoWordmarkProps) {
  const isLarge = size === 'large';
  const isSmall = size === 'small';
  const fontSize = isLarge ? 42 : isSmall ? 28 : 34;
  const circleSize = isLarge ? 40 : isSmall ? 26 : 32;
  const pawSize = isLarge ? 18 : isSmall ? 12 : 14;
  const brandColor =
    variant === 'onboarding' ? AuthColors.onboardingPrimary : AuthColors.primary;

  if (variant === 'onboarding') {
    return (
      <View style={styles.wrap}>
        <View style={styles.row}>
          <Text style={[styles.wordmark, styles.wordmarkOnboarding, { fontSize, color: brandColor }]}>
            ne
          </Text>
          <View
            style={[
              styles.oCircle,
              {
                width: circleSize,
                height: circleSize,
                borderRadius: circleSize / 2,
                marginLeft: 1,
                backgroundColor: brandColor,
              },
            ]}>
            <Ionicons name="paw" size={pawSize} color={AuthColors.background} />
          </View>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.wrap}>
      <View style={styles.row}>
        <Text style={[styles.wordmark, isLarge ? styles.wordmarkLarge : styles.wordmarkMedium]}>
          ne
        </Text>
        <Ionicons
          name="paw"
          size={isLarge ? 34 : 26}
          color={AuthColors.primary}
          style={styles.paw}
        />
      </View>
    </View>
  );
}

interface NeoTaglineProps {
  variant?: 'default' | 'onboarding';
}

export function NeoTagline({ variant = 'default' }: NeoTaglineProps) {
  if (variant === 'onboarding') {
    return (
      <View style={styles.taglineWrap}>
        <Text style={styles.onboardingTagline}>Every Pet Has a Story.</Text>
      </View>
    );
  }

  return (
    <View style={styles.taglineWrap}>
      <Text style={styles.taglineLine}>
        <Text style={styles.taglineScriptPurple}>Every Pet </Text>
        <Text style={styles.taglineScriptBlack}>Has a Story</Text>
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  wordmark: {
    ...AuthTypography.wordmark,
    color: AuthColors.primary,
  },
  wordmarkOnboarding: {
    ...withAppFont('800'),
    letterSpacing: -0.5,
  },
  wordmarkLarge: {
    fontSize: 42,
  },
  wordmarkMedium: {
    fontSize: 34,
  },
  oCircle: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  paw: {
    marginLeft: -2,
    marginTop: 2,
  },
  taglineWrap: {
    marginTop: 10,
    alignItems: 'center',
  },
  taglineLine: {
    textAlign: 'center',
  },
  onboardingTagline: {
    ...AuthTypography.taglineSans,
    fontSize: 22,
    lineHeight: 28,
    color: AuthColors.onboardingPrimary,
    textAlign: 'center',
  },
  taglineScriptPurple: {
    ...AuthTypography.taglineScript,
    color: AuthColors.primary,
  },
  taglineScriptBlack: {
    ...AuthTypography.taglineScript,
    color: AuthColors.text,
  },
});
