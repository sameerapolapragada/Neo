import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { Card } from '@/components/SafeScreen';
import { Colors, Typography } from '@/constants/theme';
import type { FutureSnapshot, Memory } from '@/types';

interface TimelineItemProps {
  entry:
    | { type: 'memory'; data: Memory }
    | { type: 'snapshot'; data: FutureSnapshot };
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export function TimelineItem({ entry }: TimelineItemProps) {
  if (entry.type === 'memory') {
    const { data } = entry;
    return (
      <Card style={styles.card}>
        <View style={styles.header}>
          <Text style={styles.badge}>Memory</Text>
          <Text style={styles.date}>{formatDate(data.created_at)}</Text>
        </View>
        <Text style={styles.title}>{data.title}</Text>
        <Text style={styles.body}>{data.description}</Text>
        {data.photo_uri ? (
          <Image source={{ uri: data.photo_uri }} style={styles.photo} contentFit="cover" />
        ) : null}
      </Card>
    );
  }

  const { data } = entry;
  return (
    <Card style={styles.card}>
      <View style={styles.header}>
        <Text style={[styles.badge, styles.snapshotBadge]}>Future Snapshot</Text>
        <Text style={styles.date}>{formatDate(data.created_at)}</Text>
      </View>
      <Text style={styles.title}>Lifestyle vision generated</Text>
      <Text style={styles.body} numberOfLines={4}>
        {data.today}
      </Text>
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 12,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  badge: {
    ...Typography.label,
    color: Colors.accent,
    backgroundColor: '#EEF6EF',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    overflow: 'hidden',
  },
  snapshotBadge: {
    color: Colors.primary,
    backgroundColor: Colors.disclaimerBg,
  },
  date: {
    ...Typography.caption,
    color: Colors.textMuted,
  },
  title: {
    ...Typography.subtitle,
    color: Colors.text,
    marginBottom: 6,
  },
  body: {
    ...Typography.body,
    color: Colors.textSecondary,
  },
  photo: {
    width: '100%',
    height: 180,
    borderRadius: 12,
    marginTop: 12,
  },
});
