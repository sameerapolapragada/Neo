import { Image } from 'expo-image';
import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';
import type { Memory } from '@/types';

interface RecentMemoryCardProps {
  memory: Memory;
  onPress: () => void;
}

function formatMemoryDate(iso: string): string {
  const date = new Date(iso);
  const today = new Date();

  if (
    date.getFullYear() === today.getFullYear() &&
    date.getMonth() === today.getMonth() &&
    date.getDate() === today.getDate()
  ) {
    return 'Today';
  }

  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

export function RecentMemoryCard({ memory, onPress }: RecentMemoryCardProps) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}>
      {memory.photo_uri ? (
        <Image source={{ uri: memory.photo_uri }} style={styles.thumbnail} contentFit="cover" />
      ) : (
        <View style={[styles.thumbnail, styles.thumbnailPlaceholder]}>
          <Text style={styles.thumbnailEmoji}>📷</Text>
        </View>
      )}

      <View style={styles.info}>
        <Text style={styles.title}>{memory.title}</Text>
        <Text style={styles.date}>{formatMemoryDate(memory.created_at)}</Text>
      </View>

      <Ionicons name="chevron-forward" size={18} color={Colors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    paddingVertical: 8,
  },
  thumbnail: {
    width: 56,
    height: 56,
    borderRadius: 14,
    backgroundColor: '#ECE7E2',
  },
  thumbnailPlaceholder: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  thumbnailEmoji: {
    fontSize: 22,
  },
  info: {
    flex: 1,
    gap: 4,
  },
  title: {
    ...Typography.label,
    color: Colors.text,
    fontSize: 16,
  },
  date: {
    ...Typography.caption,
    color: Colors.textMuted,
  },
  pressed: {
    opacity: 0.85,
  },
});
