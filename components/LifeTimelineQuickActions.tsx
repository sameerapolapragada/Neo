import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

export function LifeTimelineQuickActions() {
  return (
    <View style={styles.row}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Weekly wellness check-in"
        onPress={() => router.push('/(tabs)/moments')}
        style={({ pressed }) => [styles.button, styles.wellnessButton, pressed && styles.pressed]}>
        <View style={[styles.iconBadge, styles.wellnessIcon]}>
          <Ionicons name="heart-outline" size={18} color={AuthColors.background} />
        </View>
        <Text style={styles.label}>Weekly Wellness</Text>
      </Pressable>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Weight update"
        onPress={() => router.push('/(tabs)/weight-tracker')}
        style={({ pressed }) => [styles.button, styles.weightButton, pressed && styles.pressed]}>
        <View style={[styles.iconBadge, styles.weightIcon]}>
          <Ionicons name="scale-outline" size={18} color={AuthColors.background} />
        </View>
        <Text style={styles.label}>Weight Update</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 16,
  },
  button: {
    flex: 1,
    minHeight: 72,
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  wellnessButton: {
    backgroundColor: AuthColors.timelineWellnessSoft,
  },
  weightButton: {
    backgroundColor: AuthColors.timelineWeightSoft,
  },
  iconBadge: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
  },
  wellnessIcon: {
    backgroundColor: AuthColors.timelineWellness,
  },
  weightIcon: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  label: {
    ...AuthTypography.label,
    fontSize: 13,
    lineHeight: 18,
    color: AuthColors.text,
    textAlign: 'center',
  },
  pressed: {
    opacity: 0.92,
  },
});
