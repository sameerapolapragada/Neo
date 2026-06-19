import { StyleSheet, Text, View } from 'react-native';

import { WellnessLineChart } from '@/components/WellnessMiniChart';
import { WELLNESS_BAR_COLORS, WELLNESS_METRICS } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import { getMetricPoints } from '@/utils/wellnessAnalytics';
import type { WellnessCheckIn, WellnessMetricId } from '@/types';

interface WellnessAllMetricsChartProps {
  checkIns: WellnessCheckIn[];
  selectedMetrics?: WellnessMetricId[];
  tickLabels: string[];
}

export function WellnessAllMetricsChart({
  checkIns,
  selectedMetrics,
  tickLabels,
}: WellnessAllMetricsChartProps) {
  const activeMetrics = WELLNESS_METRICS.filter(
    (metric) => !selectedMetrics || selectedMetrics.includes(metric.id),
  );

  const series = activeMetrics.map((metric) => ({
    label: metric.title,
    color: WELLNESS_BAR_COLORS[metric.id],
    points: getMetricPoints(checkIns, metric.id, 8).map((point) => point.value),
  }));

  const hasData = series.some((entry) => entry.points.length > 0);

  return (
    <View style={styles.wrap}>
      {hasData ? (
        <>
          <WellnessLineChart series={series} tickLabels={tickLabels} />
          <View style={styles.legend}>
            {WELLNESS_METRICS.map((metric) => (
              <View key={metric.id} style={styles.legendItem}>
                <View
                  style={[styles.legendSwatch, { backgroundColor: WELLNESS_BAR_COLORS[metric.id] }]}
                />
                <Text style={styles.legendText}>{metric.title}</Text>
              </View>
            ))}
          </View>
        </>
      ) : (
        <View style={styles.empty}>
          <Text style={styles.emptyText}>Complete a check-in to see trends here.</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 4,
  },
  legend: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    marginTop: 14,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  legendSwatch: {
    width: 10,
    height: 10,
    borderRadius: 2,
  },
  legendText: {
    fontSize: 12,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  empty: {
    minHeight: 160,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: AuthColors.surface,
    borderRadius: 16,
    padding: 16,
  },
  emptyText: {
    fontSize: 14,
    color: AuthColors.textMuted,
    textAlign: 'center',
  },
});
