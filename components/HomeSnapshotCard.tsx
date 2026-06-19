import { StyleSheet, Text, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';

interface HomeSnapshotCardProps {
  timeframe: string;
  content: string;
}

export function HomeSnapshotCard({ timeframe, content }: HomeSnapshotCardProps) {
  return (
    <View style={styles.card}>
      <View style={styles.content}>
        <Text style={styles.title}>Latest Snapshot</Text>
        <Text style={styles.timeframe}>{timeframe}</Text>
        <Text style={styles.preview} numberOfLines={3}>
          {content}
        </Text>
      </View>

      <View style={styles.art}>
        <View style={styles.calendar}>
          <View style={styles.calendarHeader} />
          <View style={styles.calendarBody}>
            <View style={styles.calendarDot} />
            <View style={styles.calendarDot} />
            <View style={styles.calendarDot} />
            <View style={styles.calendarDot} />
          </View>
        </View>
        <Text style={styles.leaf}>🌿</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#E8EDE4',
    borderRadius: 22,
    padding: 18,
    flexDirection: 'row',
    overflow: 'hidden',
    marginBottom: 18,
  },
  content: {
    flex: 1,
    paddingRight: 12,
  },
  title: {
    ...Typography.subtitle,
    color: Colors.text,
    marginBottom: 4,
  },
  timeframe: {
    ...Typography.label,
    color: Colors.textSecondary,
    marginBottom: 8,
  },
  preview: {
    ...Typography.body,
    color: Colors.text,
    lineHeight: 22,
  },
  art: {
    width: 78,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  calendar: {
    width: 54,
    height: 58,
    borderRadius: 10,
    backgroundColor: Colors.card,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#DDD5CC',
  },
  calendarHeader: {
    height: 14,
    backgroundColor: Colors.primary,
  },
  calendarBody: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 4,
    padding: 6,
  },
  calendarDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#D8D0C8',
  },
  leaf: {
    position: 'absolute',
    right: -4,
    bottom: -2,
    fontSize: 22,
    opacity: 0.55,
  },
});
