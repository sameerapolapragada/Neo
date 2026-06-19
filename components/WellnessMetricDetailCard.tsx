import { StyleSheet, Text, View } from 'react-native';

import { WellnessSparkline } from '@/components/WellnessMiniChart';
import { WELLNESS_BAR_COLORS, WELLNESS_METRICS } from '@/constants/wellnessForm';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';
import {
  formatVsLast,
  getMetricAverage,
  getMetricDelta,
  getMetricLatestValue,
  getMetricPoints,
} from '@/utils/wellnessAnalytics';
import type { WellnessCheckIn } from '@/types';

interface WellnessMetricDetailCardProps {
  checkIns: WellnessCheckIn[];
  metricId: (typeof WELLNESS_METRICS)[number]['id'];
}

export function WellnessMetricDetailCard({ checkIns, metricId }: WellnessMetricDetailCardProps) {
  const metric = WELLNESS_METRICS.find((item) => item.id === metricId)!;
  const points = getMetricPoints(checkIns, metricId).map((point) => point.value);
  const latest = getMetricLatestValue(checkIns, metricId);
  const average = getMetricAverage(checkIns, metricId);
  const delta = getMetricDelta(checkIns, metricId);
  const color = WELLNESS_BAR_COLORS[metricId];

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <View style={styles.left}>
          <View style={styles.iconCircle}>
            <Text style={styles.emoji}>{metric.emoji}</Text>
          </View>
          <View>
            <Text style={styles.title}>{metric.title}</Text>
            <Text style={styles.subtitle}>8-week avg: {average > 0 ? average.toFixed(1) : '—'}</Text>
          </View>
        </View>

        <View style={styles.right}>
          <Text style={[styles.value, { color }]}>{latest ?? '—'}</Text>
          <Text
            style={[
              styles.delta,
              delta < 0 ? styles.deltaDown : { color },
            ]}>
            {latest != null ? formatVsLast(delta) : 'No data yet'}
          </Text>
        </View>
      </View>

      {points.length > 0 ? (
        <>
          <WellnessSparkline points={points} color={color} height={54} filled />
          <View style={styles.segments}>
            {Array.from({ length: 5 }).map((_, index) => (
              <View
                key={index}
                style={[
                  styles.segment,
                  latest != null && index < latest
                    ? { backgroundColor: color }
                    : styles.segmentEmpty,
                ]}
              />
            ))}
          </View>
        </>
      ) : (
        <View style={styles.emptyChart}>
          <Text style={styles.emptyText}>No history for this metric yet.</Text>
        </View>
      )}
    </View>
  );
}

export function WellnessMetricDetailSection({ checkIns }: { checkIns: WellnessCheckIn[] }) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>METRIC DETAIL</Text>
      {WELLNESS_METRICS.map((metric) => (
        <WellnessMetricDetailCard key={metric.id} checkIns={checkIns} metricId={metric.id} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: 8,
  },
  sectionLabel: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 18,
    padding: 16,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    marginBottom: 12,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    flex: 1,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: AuthColors.quickAddField,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emoji: {
    fontSize: 18,
  },
  title: {
    fontSize: 17,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  subtitle: {
    ...AuthTypography.subheadingSm,
    fontSize: 12,
    color: AuthColors.textMuted,
    marginTop: 2,
  },
  right: {
    alignItems: 'flex-end',
  },
  value: {
    fontSize: 28,
    ...withAppFont('700'),
    lineHeight: 30,
  },
  delta: {
    fontSize: 12,
    fontWeight: '700',
    marginTop: 2,
  },
  deltaDown: {
    color: AuthColors.error,
  },
  segments: {
    flexDirection: 'row',
    gap: 4,
    marginTop: 10,
  },
  segment: {
    flex: 1,
    height: 6,
    borderRadius: 999,
  },
  segmentEmpty: {
    backgroundColor: AuthColors.quickAddField,
  },
  emptyChart: {
    minHeight: 54,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: AuthColors.quickAddField,
    borderRadius: 12,
  },
  emptyText: {
    fontSize: 13,
    color: AuthColors.textMuted,
  },
});
