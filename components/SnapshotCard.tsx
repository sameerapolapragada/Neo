import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import { Colors, Typography } from '@/constants/theme';

export type SnapshotTimeframe = 'today' | 'six_months' | 'two_years' | 'five_years';

const TIMEFRAME_ART: Record<
  SnapshotTimeframe,
  { emoji: string; backgroundColor: string }
> = {
  today: { emoji: '🐕', backgroundColor: AuthColors.primarySoft },
  six_months: { emoji: '🌿', backgroundColor: AuthColors.accentSoft },
  two_years: { emoji: '🤝', backgroundColor: AuthColors.primarySoft },
  five_years: { emoji: '💛', backgroundColor: AuthColors.accentSoft },
};

interface SnapshotCardProps {
  label: string;
  content: string;
  timeframe: SnapshotTimeframe;
  photoUri?: string;
}

export function SnapshotCard({ label, content, timeframe, photoUri }: SnapshotCardProps) {
  const art = TIMEFRAME_ART[timeframe];
  const showPhoto = Boolean(photoUri) && (timeframe === 'today' || timeframe === 'five_years');

  return (
    <View style={styles.card}>
      <View style={styles.textColumn}>
        <Text style={styles.label}>{label}</Text>
        <Text style={styles.content}>{content}</Text>
      </View>

      <View style={[styles.artCircle, { backgroundColor: art.backgroundColor }]}>
        {showPhoto ? (
          <Image source={{ uri: photoUri }} style={styles.artImage} contentFit="cover" />
        ) : (
          <Text style={styles.artEmoji}>{art.emoji}</Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.card,
    borderRadius: 20,
    padding: 16,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: AuthColors.border,
    shadowColor: AuthColors.text,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  textColumn: {
    flex: 1,
    paddingRight: 12,
  },
  label: {
    ...Typography.label,
    fontSize: 15,
    color: Colors.snapshotBlue,
    marginBottom: 8,
  },
  content: {
    ...Typography.body,
    color: Colors.text,
    lineHeight: 22,
  },
  artCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  artImage: {
    width: 72,
    height: 72,
  },
  artEmoji: {
    fontSize: 34,
  },
});
