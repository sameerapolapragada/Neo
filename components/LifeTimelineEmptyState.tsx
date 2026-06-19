import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { EmptyTimelineIllustration } from '@/components/EmptyTimelineIllustration';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

interface LifeTimelineEmptyStateProps {
  onAddMemory: () => void;
}

export function LifeTimelineEmptyState({ onAddMemory }: LifeTimelineEmptyStateProps) {
  return (
    <View style={styles.wrap}>
      <EmptyTimelineIllustration />

      <Text style={styles.headline}>
        <Text style={styles.headlineBold}>Every Pet </Text>
        <Text style={styles.headlineRegular}>Has a Story</Text>
      </Text>

      <Text style={styles.subtitle}>
        Start capturing memories, milestones, and special moments.
      </Text>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Add first memory"
        onPress={onAddMemory}
        style={({ pressed }) => [styles.ctaButton, pressed && styles.pressed]}>
        <View style={styles.ctaIconCircle}>
          <Ionicons name="add" size={18} color={AuthColors.background} />
        </View>
        <Text style={styles.ctaLabel}>Add First Memory</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: 8,
    paddingBottom: 24,
  },
  headline: {
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 10,
  },
  headlineBold: {
    fontSize: 24,
    lineHeight: 30,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  headlineRegular: {
    fontSize: 24,
    lineHeight: 30,
    ...withAppFont('400'),
    color: AuthColors.text,
  },
  subtitle: {
    ...AuthTypography.body,
    fontSize: 14,
    lineHeight: 21,
    color: AuthColors.onboardingTextMuted,
    textAlign: 'center',
    maxWidth: 280,
    marginBottom: 28,
  },
  ctaButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    alignSelf: 'stretch',
    minHeight: 54,
    borderRadius: 14,
    backgroundColor: AuthColors.onboardingPrimary,
    paddingHorizontal: 20,
  },
  ctaIconCircle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.85)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  ctaLabel: {
    ...AuthTypography.button,
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.92,
  },
});
