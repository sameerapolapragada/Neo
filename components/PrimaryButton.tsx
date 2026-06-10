import {
  ActivityIndicator,
  Pressable,
  PressableProps,
  StyleSheet,
  Text,
} from 'react-native';

import { Colors, Typography } from '@/constants/theme';

interface PrimaryButtonProps extends PressableProps {
  title: string;
  loading?: boolean;
  variant?: 'primary' | 'secondary' | 'outline';
}

export function PrimaryButton({
  title,
  loading = false,
  variant = 'primary',
  disabled,
  style,
  ...props
}: PrimaryButtonProps) {
  const isDisabled = disabled || loading;

  return (
    <Pressable
      accessibilityRole="button"
      disabled={isDisabled}
      style={({ pressed }) => [
        styles.base,
        variant === 'primary' && styles.primary,
        variant === 'secondary' && styles.secondary,
        variant === 'outline' && styles.outline,
        isDisabled && styles.disabled,
        pressed && !isDisabled && styles.pressed,
        typeof style === 'function' ? style({ pressed }) : style,
      ]}
      {...props}>
      {loading ? (
        <ActivityIndicator color={variant === 'outline' ? Colors.primary : '#FFFFFF'} />
      ) : (
        <Text
          style={[
            styles.label,
            variant === 'outline' && styles.outlineLabel,
            variant === 'secondary' && styles.secondaryLabel,
          ]}>
          {title}
        </Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
    paddingVertical: 14,
  },
  primary: {
    backgroundColor: Colors.primary,
  },
  secondary: {
    backgroundColor: Colors.accent,
  },
  outline: {
    backgroundColor: Colors.card,
    borderWidth: 1.5,
    borderColor: Colors.primary,
  },
  disabled: {
    opacity: 0.5,
  },
  pressed: {
    opacity: 0.85,
  },
  label: {
    ...Typography.subtitle,
    color: '#FFFFFF',
    fontSize: 16,
  },
  secondaryLabel: {
    color: '#FFFFFF',
  },
  outlineLabel: {
    color: Colors.primary,
  },
});
