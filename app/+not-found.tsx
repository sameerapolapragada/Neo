import { router } from 'expo-router';
import { Pressable, StyleSheet, Text } from 'react-native';

import { PrimaryButton } from '@/components/PrimaryButton';
import { ScreenLayout } from '@/components/ScreenLayout';
import { Colors, Typography } from '@/constants/theme';

export default function NotFoundScreen() {
  return (
    <ScreenLayout contentContainerStyle={styles.content}>
      <Text style={styles.emoji}>🐾</Text>
      <Text style={styles.title}>This screen doesn't exist</Text>
      <Text style={styles.message}>Let's get you back to your pet's story.</Text>
      <PrimaryButton title="Go Home" onPress={() => router.replace('/(tabs)')} />
      <Pressable
        accessibilityRole="button"
        onPress={() => router.replace('/onboarding')}
        style={({ pressed }) => [styles.secondaryAction, pressed && styles.pressed]}>
        <Text style={styles.secondaryText}>Back to onboarding</Text>
      </Pressable>
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  content: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  emoji: {
    fontSize: 48,
    marginBottom: 16,
  },
  title: {
    ...Typography.title,
    color: Colors.text,
    textAlign: 'center',
    marginBottom: 8,
  },
  message: {
    ...Typography.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: 24,
  },
  secondaryAction: {
    marginTop: 16,
    minHeight: 44,
    justifyContent: 'center',
  },
  secondaryText: {
    ...Typography.label,
    color: Colors.primary,
  },
  pressed: {
    opacity: 0.85,
  },
});
