import { StyleSheet, Text, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';

interface OfflineBannerProps {
  visible: boolean;
  message?: string;
}

export function OfflineBanner({
  visible,
  message = 'Saved locally. Cloud sync will resume when connection is restored.',
}: OfflineBannerProps) {
  if (!visible) return null;

  return (
    <View style={styles.banner} accessibilityRole="text">
      <Text style={styles.text}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    backgroundColor: Colors.disclaimerBg,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  text: {
    ...Typography.caption,
    color: Colors.textSecondary,
  },
});
