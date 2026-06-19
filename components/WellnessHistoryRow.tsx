import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { WELLNESS_BAR_COLORS, WELLNESS_METRICS } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import {
  computeAverageScore,
  formatCheckInDate,
  summarizeCheckIn,
} from '@/utils/wellnessDate';
import type { WellnessCheckIn } from '@/types';

interface WellnessHistoryRowProps {
  checkIn: WellnessCheckIn;
  onPress?: () => void;
}

export function WellnessHistoryRow({ checkIn, onPress }: WellnessHistoryRowProps) {
  const average = computeAverageScore(checkIn.ratings);
  const summary = summarizeCheckIn(checkIn.ratings);

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}>
      <View style={styles.iconCircle}>
        <Ionicons name="calendar-outline" size={18} color={AuthColors.quickAddLabel} />
      </View>

      <View style={styles.content}>
        <Text style={styles.date}>{formatCheckInDate(checkIn.week_start)}</Text>
        <Text style={styles.summary}>{summary}</Text>
      </View>

      <View style={styles.bars}>
        {WELLNESS_METRICS.map((metric) => {
          const rating = checkIn.ratings[metric.id] ?? 0;
          const height = 10 + rating * 6;

          return (
            <View
              key={metric.id}
              style={[
                styles.bar,
                {
                  height,
                  backgroundColor: WELLNESS_BAR_COLORS[metric.id],
                },
              ]}
            />
          );
        })}
      </View>

      <Text style={styles.score}>{average.toFixed(1)}</Text>
      <Ionicons name="chevron-forward" size={18} color={AuthColors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 14,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    marginBottom: 10,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: AuthColors.quickAddField,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    flex: 1,
    minWidth: 0,
  },
  date: {
    fontSize: 16,
    fontWeight: '700',
    color: AuthColors.text,
    marginBottom: 2,
  },
  summary: {
    fontSize: 13,
    color: AuthColors.textMuted,
  },
  bars: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 4,
    height: 40,
    marginRight: 4,
  },
  bar: {
    width: 8,
    borderRadius: 999,
  },
  score: {
    fontSize: 16,
    ...withAppFont('700'),
    color: AuthColors.text,
    minWidth: 32,
    textAlign: 'right',
  },
  pressed: {
    opacity: 0.92,
  },
});
