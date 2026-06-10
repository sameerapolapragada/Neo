import { StyleSheet, Text, View } from 'react-native';

import { Card } from '@/components/SafeScreen';
import { Colors, Typography } from '@/constants/theme';

interface SnapshotCardProps {
  label: string;
  content: string;
}

export function SnapshotCard({ label, content }: SnapshotCardProps) {
  return (
    <Card style={styles.card}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.content}>{content}</Text>
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 12,
  },
  label: {
    ...Typography.label,
    color: Colors.primary,
    marginBottom: 8,
  },
  content: {
    ...Typography.body,
    color: Colors.text,
  },
});
