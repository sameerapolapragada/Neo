import { StyleSheet, Text, View } from 'react-native';

import { Colors, DISCLAIMER, Typography } from '@/constants/theme';

interface AppHeaderProps {
  title: string;
  subtitle?: string;
  showDisclaimer?: boolean;
}

export function AppHeader({ title, subtitle, showDisclaimer = false }: AppHeaderProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      {showDisclaimer ? (
        <View style={styles.disclaimerBox}>
          <Text style={styles.disclaimer}>{DISCLAIMER}</Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 20,
  },
  title: {
    ...Typography.title,
    color: Colors.text,
  },
  subtitle: {
    ...Typography.body,
    color: Colors.textSecondary,
    marginTop: 6,
  },
  disclaimerBox: {
    marginTop: 12,
    backgroundColor: Colors.disclaimerBg,
    borderRadius: 12,
    padding: 12,
  },
  disclaimer: {
    ...Typography.caption,
    color: Colors.textSecondary,
  },
});
