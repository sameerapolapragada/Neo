import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface PetProfileFlowBadgeProps {
  step?: number;
  title?: string;
}

export function PetProfileFlowBadge({
  step = 2,
  title = 'Create Pet Profile',
}: PetProfileFlowBadgeProps) {
  return (
    <View style={styles.flowBadge}>
      <View style={styles.stepCircle}>
        <Text style={styles.stepNumber}>{step}</Text>
      </View>
      <Text style={styles.flowTitle}>{title}</Text>
    </View>
  );
}

interface PetProfileCardHeaderProps {
  title?: string;
  subtitle?: string;
}

export function PetProfileCardHeader({
  title = 'Create Your Pet Profile',
  subtitle = 'Tell us about your furry friend',
}: PetProfileCardHeaderProps) {
  return (
    <View style={styles.cardHeader}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.subtitle}>{subtitle}</Text>
    </View>
  );
}

interface PetProfileEditHeaderProps {
  onBack: () => void;
}

export function PetProfileEditHeader({ onBack }: PetProfileEditHeaderProps) {
  return (
    <View style={styles.editHeader}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Go back"
        onPress={onBack}
        style={({ pressed }) => [styles.backButton, pressed && styles.pressed]}>
        <Ionicons name="arrow-back" size={22} color={AuthColors.text} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  flowBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    marginBottom: 16,
  },
  stepCircle: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: AuthColors.onboardingPrimary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumber: {
    fontSize: 14,
    fontWeight: '700',
    color: AuthColors.background,
  },
  flowTitle: {
    ...AuthTypography.label,
    fontSize: 16,
    ...withAppFont('700'),
    color: AuthColors.onboardingPrimary,
  },
  cardHeader: {
    alignItems: 'center',
    marginBottom: 20,
  },
  title: {
    ...AuthTypography.label,
    fontSize: 20,
    ...withAppFont('700'),
    color: AuthColors.text,
    textAlign: 'center',
  },
  subtitle: {
    ...AuthTypography.subheadingSm,
    color: AuthColors.onboardingTextMuted,
    textAlign: 'center',
    marginTop: 6,
  },
  editHeader: {
    marginBottom: 8,
  },
  backButton: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: -4,
  },
  pressed: {
    opacity: 0.7,
  },
});
