import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { WellnessSparkline } from '@/components/WellnessMiniChart';
import { AuthColors } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';
import {
  formatWeightTrend,
  getProfileWeightValue,
  getWeightSparklinePoints,
} from '@/utils/profileStats';
import type { Pet, WeightEntry } from '@/types';

function normalizeSparkline(points: number[]): number[] {
  if (points.length === 0) return [];
  const min = Math.min(...points);
  const max = Math.max(...points);
  const range = Math.max(max - min, 0.1);
  return points.map((point) => 1 + ((point - min) / range) * 4);
}

interface ProfileWeightTrackerCardProps {
  pet: Pet;
  entries: WeightEntry[];
  onPress: () => void;
}

export function ProfileWeightTrackerCard({ pet, entries, onPress }: ProfileWeightTrackerCardProps) {
  const weight = getProfileWeightValue(entries, pet);
  const trend = formatWeightTrend(entries);
  const points = normalizeSparkline(getWeightSparklinePoints(entries));

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel="Open weight tracker"
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}>
      <View style={styles.topRow}>
        <View style={styles.left}>
          <View style={styles.iconBadge}>
            <Ionicons name="scale-outline" size={18} color={AuthColors.background} />
          </View>
          <View>
            <Text style={styles.eyebrow}>WEIGHT TRACKER</Text>
            <Text style={styles.weight}>{weight}</Text>
            {trend ? <Text style={styles.trend}>{trend}</Text> : null}
          </View>
        </View>

        <View style={styles.historyButton}>
          <Text style={styles.historyLabel}>View History</Text>
        </View>
      </View>

      {points.length > 1 ? (
        <View style={styles.chartRow}>
          <View style={styles.chartWrap}>
            <WellnessSparkline points={points} color="rgba(255,255,255,0.92)" height={42} filled={false} />
          </View>
          <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.72)" />
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: AuthColors.onboardingPrimary,
    borderRadius: 18,
    padding: 16,
    marginBottom: 18,
  },
  pressed: {
    opacity: 0.94,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: 12,
  },
  left: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    flex: 1,
  },
  iconBadge: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: 'rgba(255,255,255,0.16)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  eyebrow: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 0.8,
    color: 'rgba(255,255,255,0.82)',
    marginBottom: 4,
  },
  weight: {
    fontSize: 28,
    lineHeight: 32,
    ...withAppFont('700'),
    color: AuthColors.background,
  },
  trend: {
    marginTop: 4,
    fontSize: 13,
    color: 'rgba(255,255,255,0.88)',
  },
  historyButton: {
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: 'rgba(255,255,255,0.16)',
  },
  historyLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: AuthColors.background,
  },
  chartRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 14,
  },
  chartWrap: {
    flex: 1,
  },
});
