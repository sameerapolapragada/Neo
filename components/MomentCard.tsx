import { StyleSheet, Text, View } from 'react-native';

import { Card } from '@/components/SafeScreen';
import { Colors, Typography } from '@/constants/theme';

interface MomentCardProps {
  title: string;
  items: string[];
  accent?: 'green' | 'orange' | 'neutral';
}

export function MomentCard({ title, items, accent = 'neutral' }: MomentCardProps) {
  const accentColor =
    accent === 'green' ? Colors.accent : accent === 'orange' ? Colors.primary : Colors.textSecondary;

  return (
    <Card style={styles.card}>
      <Text style={[styles.title, { color: accentColor }]}>{title}</Text>
      {items.map((item) => (
        <View key={item} style={styles.row}>
          <Text style={styles.bullet}>•</Text>
          <Text style={styles.item}>{item}</Text>
        </View>
      ))}
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 12,
  },
  title: {
    ...Typography.subtitle,
    marginBottom: 10,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 6,
    gap: 8,
  },
  bullet: {
    ...Typography.body,
    color: Colors.textSecondary,
    lineHeight: 22,
  },
  item: {
    ...Typography.body,
    color: Colors.text,
    flex: 1,
  },
});
