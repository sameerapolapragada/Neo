import { StyleSheet, Text, View } from 'react-native';

import { PrimaryButton } from '@/components/PrimaryButton';
import { Colors, Typography } from '@/constants/theme';
import { useResponsive } from '@/hooks/useResponsive';

interface EmptyStateProps {
  emoji?: string;
  title: string;
  message: string;
  actionLabel?: string;
  onAction?: () => void;
}

export function EmptyState({
  emoji = '🐾',
  title,
  message,
  actionLabel,
  onAction,
}: EmptyStateProps) {
  const { horizontalPadding, isSmall } = useResponsive();

  return (
    <View
      style={[
        styles.container,
        { paddingHorizontal: horizontalPadding },
        isSmall && styles.compact,
      ]}>
      <Text style={[styles.emoji, isSmall && styles.emojiSmall]}>{emoji}</Text>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.message}>{message}</Text>
      {actionLabel && onAction ? (
        <PrimaryButton title={actionLabel} onPress={onAction} style={styles.button} />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
  },
  compact: {
    paddingVertical: 28,
  },
  emoji: {
    fontSize: 48,
    marginBottom: 16,
  },
  emojiSmall: {
    fontSize: 40,
    marginBottom: 12,
  },
  title: {
    ...Typography.subtitle,
    color: Colors.text,
    textAlign: 'center',
    marginBottom: 8,
  },
  message: {
    ...Typography.body,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
  button: {
    marginTop: 20,
    alignSelf: 'stretch',
  },
});
