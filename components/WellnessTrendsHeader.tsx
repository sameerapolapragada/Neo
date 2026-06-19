import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';
import {
  formatTrendDelta,
  getOverallAverage,
  getOverallDelta,
  getWeekCountLabel,
} from '@/utils/wellnessAnalytics';
import type { WellnessCheckIn } from '@/types';

export type WellnessTrendRange = 'weekly' | 'monthly';

interface WellnessTrendsHeaderProps {
  checkIns: WellnessCheckIn[];
  range: WellnessTrendRange;
  onRangeChange: (range: WellnessTrendRange) => void;
}

export function WellnessTrendsHeader({
  checkIns,
  range,
  onRangeChange,
}: WellnessTrendsHeaderProps) {
  const average = getOverallAverage(checkIns);
  const delta = getOverallDelta(checkIns);
  const weekLabel = getWeekCountLabel(checkIns);
  const deltaLabel = formatTrendDelta(delta);

  return (
    <View style={styles.wrap}>
      <View style={styles.circleOne} />
      <View style={styles.circleTwo} />

      <View style={styles.contentRow}>
        <View style={styles.copy}>
          <Text style={styles.eyebrow}>WELLNESS TRENDS</Text>
          <View style={styles.scoreRow}>
            <Text style={styles.score}>{average.toFixed(1)}</Text>
            <Text style={styles.scoreMax}>/ 5.0</Text>
          </View>
          <Text style={styles.subtitle}>Overall wellness · {weekLabel}</Text>
          <Text style={[styles.delta, delta >= 0 ? styles.deltaUp : styles.deltaDown]}>
            {delta >= 0 ? '↑' : '↓'} {deltaLabel} from start
          </Text>
        </View>

        <View style={styles.rings}>
          <View style={[styles.ring, styles.ringOuter]} />
          <View style={[styles.ring, styles.ringMiddle]} />
          <View style={[styles.ring, styles.ringInner]} />
        </View>
      </View>

      <View style={styles.rangeToggle}>
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ selected: range === 'weekly' }}
          onPress={() => onRangeChange('weekly')}
          style={[styles.rangeSegment, range === 'weekly' && styles.rangeSegmentActive]}>
          <Text style={[styles.rangeText, range === 'weekly' && styles.rangeTextActive]}>
            Weekly
          </Text>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ selected: range === 'monthly' }}
          onPress={() => onRangeChange('monthly')}
          style={[styles.rangeSegment, range === 'monthly' && styles.rangeSegmentActive]}>
          <Text style={[styles.rangeText, range === 'monthly' && styles.rangeTextActive]}>
            Monthly
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: AuthColors.quickAddToggleActive,
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 28,
    overflow: 'hidden',
  },
  circleOne: {
    position: 'absolute',
    top: -30,
    right: -10,
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  circleTwo: {
    position: 'absolute',
    bottom: -40,
    left: -20,
    width: 140,
    height: 140,
    borderRadius: 70,
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  contentRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  copy: {
    flex: 1,
    paddingRight: 12,
  },
  eyebrow: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 0.8,
    color: 'rgba(255,255,255,0.82)',
    marginBottom: 8,
  },
  scoreRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 4,
    marginBottom: 4,
  },
  score: {
    fontSize: 42,
    lineHeight: 44,
    ...withAppFont('700'),
    color: AuthColors.background,
  },
  scoreMax: {
    fontSize: 18,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.72)',
    marginBottom: 6,
  },
  subtitle: {
    ...AuthTypography.subheadingSm,
    color: 'rgba(255,255,255,0.88)',
    marginBottom: 6,
  },
  delta: {
    fontSize: 14,
    fontWeight: '700',
  },
  deltaUp: {
    color: AuthColors.success,
  },
  deltaDown: {
    color: AuthColors.error,
  },
  rings: {
    width: 78,
    height: 78,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ring: {
    position: 'absolute',
    borderRadius: 999,
    borderWidth: 5,
    borderColor: 'transparent',
  },
  ringOuter: {
    width: 78,
    height: 78,
    borderTopColor: AuthColors.primary,
    borderRightColor: AuthColors.primary,
    transform: [{ rotate: '-20deg' }],
  },
  ringMiddle: {
    width: 58,
    height: 58,
    borderTopColor: AuthColors.accent,
    borderLeftColor: AuthColors.accent,
    transform: [{ rotate: '35deg' }],
  },
  ringInner: {
    width: 38,
    height: 38,
    borderTopColor: AuthColors.accentWarm,
    borderRightColor: AuthColors.accentWarm,
    transform: [{ rotate: '-10deg' }],
  },
  rangeToggle: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderRadius: 999,
    padding: 4,
  },
  rangeSegment: {
    flex: 1,
    minHeight: 34,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rangeSegmentActive: {
    backgroundColor: AuthColors.card,
  },
  rangeText: {
    fontSize: 13,
    fontWeight: '700',
    color: 'rgba(255,255,255,0.72)',
  },
  rangeTextActive: {
    color: AuthColors.text,
  },
});
