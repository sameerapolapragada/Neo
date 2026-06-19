import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

const LOGO = require('@/assets/images/logo.png');

const FEATURE_PILLS = [
  { id: 'memories', label: 'Memories', icon: 'camera-outline' as const },
  { id: 'milestones', label: 'Milestones', icon: 'trophy-outline' as const },
  { id: 'wellness', label: 'Wellness', icon: 'heart-outline' as const },
];

interface HomeLandingScreenProps {
  variant?: 'auth' | 'home';
  onPrimaryAction?: () => void;
}

export function HomeLandingScreen({ variant = 'auth', onPrimaryAction }: HomeLandingScreenProps) {
  const insets = useSafeAreaInsets();
  const isAuth = variant === 'auth';

  function handlePrimaryPress() {
    if (onPrimaryAction) {
      onPrimaryAction();
      return;
    }

    router.push('/signup');
  }

  return (
    <SafeScreen style={styles.screen} edges={[]}>
      <View style={styles.flex}>
        <View style={[styles.topBar, { paddingTop: insets.top + 8 }]}>
          <View style={styles.brandRow}>
            <View style={styles.brandIcon}>
              <Ionicons name="heart" size={14} color={AuthColors.background} />
            </View>
            <Text style={styles.brandText}>Neo</Text>
          </View>

          {isAuth ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Skip"
              onPress={() => router.push('/login')}
              style={({ pressed }) => [styles.skipButton, pressed && styles.pressed]}>
              <Text style={styles.skipText}>Skip</Text>
            </Pressable>
          ) : (
            <View style={styles.skipButton} />
          )}
        </View>

        <View style={styles.hero}>
          <Image source={LOGO} style={styles.logo} contentFit="contain" accessibilityLabel="Neo logo" />
        </View>

        <View
          style={[
            styles.content,
            {
              paddingBottom: Math.max(insets.bottom, 24) + (isAuth ? 0 : 88),
            },
          ]}>
          <Text style={styles.eyebrow}>EVERY PET HAS A STORY.</Text>
          <Text style={styles.headline}>Capture the moments that matter most.</Text>
          <Text style={styles.description}>
            Memories, milestones, and wellness — all in one private, beautiful journal for your pet.
          </Text>

          <View style={styles.pillRow}>
            {FEATURE_PILLS.map((pill) => (
              <View key={pill.id} style={styles.pill}>
                <Ionicons
                  name={pill.icon}
                  size={14}
                  color={pill.id === 'wellness' ? AuthColors.primary : AuthColors.textMuted}
                />
                <Text style={styles.pillText}>{pill.label}</Text>
              </View>
            ))}
          </View>

          <Pressable
            accessibilityRole="button"
            accessibilityLabel={isAuth ? 'Get started' : 'Add first memory'}
            onPress={handlePrimaryPress}
            style={({ pressed }) => [styles.ctaButton, pressed && styles.pressed]}>
            <Text style={styles.ctaLabel}>{isAuth ? 'Get Started' : 'Add First Memory'}</Text>
            <Ionicons name="chevron-forward" size={18} color={AuthColors.background} />
          </Pressable>

          {isAuth ? (
            <Text style={styles.footer}>
              Already have an account?{' '}
              <Text style={styles.footerLink} onPress={() => router.push('/login')}>
                Sign in
              </Text>
            </Text>
          ) : null}
        </View>
      </View>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.emptyTimelineBackground,
  },
  flex: {
    flex: 1,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    zIndex: 1,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  brandIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: AuthColors.onboardingPrimary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  brandText: {
    fontSize: 16,
    fontWeight: '700',
    color: AuthColors.text,
  },
  skipButton: {
    minHeight: 32,
    justifyContent: 'center',
    paddingHorizontal: 4,
  },
  skipText: {
    fontSize: 15,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  hero: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingTop: 8,
    paddingBottom: 12,
  },
  logo: {
    width: '100%',
    height: '100%',
    maxWidth: 320,
    maxHeight: 320,
  },
  content: {
    paddingHorizontal: 24,
    paddingTop: 8,
    backgroundColor: AuthColors.emptyTimelineBackground,
  },
  eyebrow: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 1.2,
    color: AuthColors.quickAddLabel,
    marginBottom: 10,
  },
  headline: {
    fontSize: 30,
    lineHeight: 36,
    ...withAppFont('700'),
    color: AuthColors.text,
    marginBottom: 12,
  },
  description: {
    ...AuthTypography.body,
    fontSize: 15,
    lineHeight: 22,
    color: AuthColors.textMuted,
    marginBottom: 18,
  },
  pillRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 22,
  },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: AuthColors.quickAddField,
  },
  pillText: {
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.text,
  },
  ctaButton: {
    minHeight: 54,
    borderRadius: 999,
    backgroundColor: AuthColors.onboardingPrimary,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    marginBottom: 16,
  },
  ctaLabel: {
    ...AuthTypography.button,
    color: AuthColors.background,
  },
  footer: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.textMuted,
    textAlign: 'center',
  },
  footerLink: {
    color: AuthColors.onboardingPrimary,
    fontWeight: '700',
  },
  pressed: {
    opacity: 0.88,
  },
});
