import { Ionicons } from '@expo/vector-icons';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface WellnessCheckInCardHeaderProps {
  petName: string;
  onBack: () => void;
}

export function WellnessCheckInCardHeader({ petName, onBack }: WellnessCheckInCardHeaderProps) {
  function showInfo() {
    Alert.alert(
      'Weekly Wellness',
      'Rate how your pet has been this week across appetite, energy, mood, exercise, and sleep.',
    );
  }

  return (
    <View style={styles.wrap}>
      <View style={styles.headerRow}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Go back"
          onPress={onBack}
          style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
          <Ionicons name="arrow-back" size={22} color={AuthColors.text} />
        </Pressable>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Wellness information"
          onPress={showInfo}
          style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
          <Ionicons name="information-circle-outline" size={22} color={AuthColors.textMuted} />
        </Pressable>
      </View>

      <Text style={styles.title}>Weekly Wellness Check-In</Text>
      <Text style={styles.subtitle}>How has {petName} been this week?</Text>
    </View>
  );
}

export function WellnessCheckInFooter({ onOpenHistory }: { onOpenHistory?: () => void }) {
  return (
    <View style={styles.footerBlock}>
      <View style={styles.footer}>
        <Ionicons name="sparkles" size={14} color={AuthColors.textMuted} />
        <Text style={styles.footerText}>Takes less than 20 seconds!</Text>
        <Ionicons name="time-outline" size={16} color={AuthColors.primary} />
      </View>

      {onOpenHistory ? (
        <Pressable
          accessibilityRole="button"
          onPress={onOpenHistory}
          style={({ pressed }) => [styles.historyLink, pressed && styles.pressed]}>
          <Text style={styles.historyLinkText}>View Wellness History</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 18,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  sideButton: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
    textAlign: 'center',
  },
  subtitle: {
    ...AuthTypography.subheadingSm,
    color: AuthColors.textMuted,
    textAlign: 'center',
    marginTop: 4,
  },
  footerBlock: {
    marginTop: 14,
    gap: 10,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  footerText: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.textMuted,
  },
  historyLink: {
    alignItems: 'center',
    paddingVertical: 4,
  },
  historyLinkText: {
    ...AuthTypography.label,
    fontSize: 14,
    color: AuthColors.primary,
  },
  pressed: {
    opacity: 0.7,
  },
});
