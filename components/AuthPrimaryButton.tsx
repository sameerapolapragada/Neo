import { Pressable, PressableProps, StyleSheet, Text } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface AuthPrimaryButtonProps extends PressableProps {
  title: string;
  variant?: 'primary' | 'onboarding' | 'ghost';
}

export function AuthPrimaryButton({
  title,
  variant = 'primary',
  disabled,
  style,
  ...props
}: AuthPrimaryButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      style={({ pressed }) => [
        styles.base,
        variant === 'onboarding'
          ? styles.onboarding
          : variant === 'primary'
            ? styles.primary
            : styles.ghost,
        disabled && styles.disabled,
        pressed && !disabled && styles.pressed,
        typeof style === 'function' ? style({ pressed, hovered: false }) : style,
      ]}
      {...props}>
      <Text style={[styles.label, variant === 'ghost' && styles.ghostLabel]}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 54,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  primary: {
    backgroundColor: AuthColors.primary,
  },
  onboarding: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  disabled: {
    opacity: 0.5,
  },
  pressed: {
    opacity: 0.88,
  },
  label: {
    ...AuthTypography.button,
    color: AuthColors.background,
  },
  ghostLabel: {
    color: AuthColors.primaryDark,
  },
});
