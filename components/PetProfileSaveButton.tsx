import { Pressable, StyleSheet, Text } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface PetProfileSaveButtonProps {
  loading?: boolean;
  onPress: () => void;
}

export function PetProfileSaveButton({ loading, onPress }: PetProfileSaveButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      disabled={loading}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        loading && styles.disabled,
        pressed && !loading && styles.pressed,
      ]}>
      <Text style={styles.label}>{loading ? 'Saving...' : 'Save Profile'}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 52,
    borderRadius: 14,
    backgroundColor: AuthColors.onboardingPrimary,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  label: {
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
