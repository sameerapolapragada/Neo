import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors } from '@/constants/authTheme';
import {
  formatTimelineDate,
  formatTimelineSnapshotDate,
} from '@/utils/timelineDate';
import type { FutureSnapshot, Memory } from '@/types';

interface TimelineItemProps {
  entry:
    | { type: 'memory'; data: Memory }
    | { type: 'snapshot'; data: FutureSnapshot };
  onMemoryPress?: (memory: Memory) => void;
}

export function TimelineItem({ entry, onMemoryPress }: TimelineItemProps) {
  if (entry.type === 'memory') {
    const { data } = entry;

    const content = (
      <>
        {data.photo_uri ? (
          <Image source={{ uri: data.photo_uri }} style={styles.thumbnail} contentFit="cover" />
        ) : (
          <View style={[styles.thumbnail, styles.placeholder]}>
            <Ionicons name="image-outline" size={22} color={AuthColors.textMuted} />
          </View>
        )}

        <View style={styles.content}>
          <Text style={styles.title} numberOfLines={2}>
            {data.title}
          </Text>
          <Text style={styles.date}>{formatTimelineDate(data.created_at)}</Text>
        </View>
      </>
    );

    if (!onMemoryPress) {
      return <View style={styles.card}>{content}</View>;
    }

    return (
      <Pressable
        accessibilityRole="button"
        onPress={() => onMemoryPress(data)}
        style={({ pressed }) => [styles.card, pressed && styles.pressed]}>
        {content}
      </Pressable>
    );
  }

  const { data } = entry;

  return (
    <View style={styles.card}>
      <View style={[styles.thumbnail, styles.snapshotThumb]}>
        <Ionicons name="camera-outline" size={24} color={AuthColors.primary} />
      </View>

      <View style={styles.content}>
        <Text style={styles.title}>Future Snapshot</Text>
        <Text style={styles.date}>{formatTimelineSnapshotDate(data.created_at)}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: AuthColors.card,
    borderRadius: 16,
    padding: 12,
    borderWidth: 1,
    borderColor: AuthColors.border,
    shadowColor: AuthColors.text,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 2,
  },
  thumbnail: {
    width: 64,
    height: 64,
    borderRadius: 14,
    backgroundColor: AuthColors.surface,
  },
  placeholder: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  snapshotThumb: {
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 32,
    backgroundColor: AuthColors.primarySoft,
  },
  content: {
    flex: 1,
    paddingLeft: 14,
  },
  title: {
    fontSize: 16,
    ...withAppFont('600'),
    color: AuthColors.text,
    marginBottom: 4,
  },
  date: {
    fontSize: 14,
    color: AuthColors.textMuted,
  },
  pressed: {
    opacity: 0.92,
  },
});
