import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import { Radius, Typography } from '@/constants/theme';

type HomeActionVariant = 'snapshot' | 'moments' | 'memory';

interface HomeActionButtonProps {
  title: string;
  variant: HomeActionVariant;
  onPress: () => void;
}

const variantStyles = {
  snapshot: {
    backgroundColor: AuthColors.primarySoft,
    icon: 'sparkles' as const,
    iconColor: AuthColors.primaryDark,
  },
  moments: {
    backgroundColor: AuthColors.accentSoft,
    icon: 'heart' as const,
    iconColor: AuthColors.accent,
  },
  memory: {
    backgroundColor: AuthColors.primarySoft,
    icon: 'add-circle' as const,
    iconColor: AuthColors.primary,
  },
};

export function HomeActionButton({ title, variant, onPress }: HomeActionButtonProps) {
  const config = variantStyles[variant];

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.button, { backgroundColor: config.backgroundColor }, pressed && styles.pressed]}>
      <Ionicons name={config.icon} size={22} color={config.iconColor} />
      <Text style={styles.label}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 54,
    borderRadius: Radius.full,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    paddingHorizontal: 18,
  },
  label: {
    ...Typography.label,
    color: AuthColors.text,
    fontSize: 16,
  },
  pressed: {
    opacity: 0.88,
  },
});
