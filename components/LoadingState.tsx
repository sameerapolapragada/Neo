import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';

import { AppLogo } from '@/components/AppLogo';
import { Colors, Typography } from '@/constants/theme';

interface LoadingStateProps {
  message?: string;
  showLogo?: boolean;
}

export function LoadingState({
  message = 'Loading...',
  showLogo = true,
}: LoadingStateProps) {
  return (
    <View style={styles.container} accessibilityRole="progressbar">
      {showLogo ? <AppLogo width={160} style={styles.logo} /> : null}
      <ActivityIndicator size="large" color={Colors.primary} />
      <Text style={styles.message}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    gap: 16,
  },
  logo: {
    marginBottom: 4,
  },
  message: {
    ...Typography.body,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});
