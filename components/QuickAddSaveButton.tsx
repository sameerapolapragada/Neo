import { Pressable, StyleSheet, Text } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddSaveButtonProps {
  label: string;
  loading?: boolean;
  onPress: () => void;
  variant?: 'default' | 'quickAdd';
}

export function QuickAddSaveButton({
  label,
  loading,
  onPress,
  variant = 'default',
}: QuickAddSaveButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      disabled={loading}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        variant === 'quickAdd' ? styles.buttonQuickAdd : styles.buttonDefault,
        loading && styles.disabled,
        pressed && !loading && styles.pressed,
      ]}>
      <Text style={styles.text}>{loading ? 'Saving...' : label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 52,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  buttonDefault: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  buttonQuickAdd: {
    backgroundColor: AuthColors.quickAddToggleActive,
  },
  text: {
    ...AuthTypography.button,
    color: AuthColors.background,
  },
  disabled: {
    opacity: 0.6,
  },
  pressed: {
    opacity: 0.9,
  },
});
