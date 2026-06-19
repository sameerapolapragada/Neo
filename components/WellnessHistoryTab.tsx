import { useMemo, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { WellnessAllMetricsChart } from '@/components/WellnessAllMetricsChart';
import { WellnessInsightsCarousel } from '@/components/WellnessInsightsCarousel';
import { WellnessMetricDetailSection } from '@/components/WellnessMetricDetailCard';
import { WellnessMetricFilters } from '@/components/WellnessMetricFilters';
import { EmptyState } from '@/components/EmptyState';
import { WELLNESS_METRICS } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import {
  buildMetricInsights,
  formatChartDateRange,
  getChartTickLabels,
  getRecentCompleteCheckIns,
  hasWellnessHistory,
} from '@/utils/wellnessAnalytics';
import type { WellnessCheckIn, WellnessMetricId } from '@/types';

interface WellnessHistoryTabProps {
  checkIns: WellnessCheckIn[];
  range?: 'weekly' | 'monthly';
}

export function WellnessHistoryTab({ checkIns, range = 'weekly' }: WellnessHistoryTabProps) {
  const [selectedMetrics, setSelectedMetrics] = useState<WellnessMetricId[]>(
    WELLNESS_METRICS.map((metric) => metric.id),
  );

  const historyCheckIns = useMemo(
    () => getRecentCompleteCheckIns(checkIns, range === 'monthly' ? 12 : 8),
    [checkIns, range],
  );
  const insights = useMemo(() => buildMetricInsights(historyCheckIns), [historyCheckIns]);
  const tickLabels = useMemo(() => getChartTickLabels(historyCheckIns), [historyCheckIns]);
  const dateRange = useMemo(() => formatChartDateRange(historyCheckIns), [historyCheckIns]);

  function handleToggleMetric(metricId: WellnessMetricId) {
    setSelectedMetrics((current) => {
      if (current.includes(metricId)) {
        if (current.length === 1) return current;
        return current.filter((id) => id !== metricId);
      }
      return [...current, metricId];
    });
  }

  if (!hasWellnessHistory(checkIns)) {
    return (
      <View style={styles.emptyWrap}>
        <EmptyState
          title="No wellness history yet"
          message="Complete your first weekly check-in to unlock trends and insights."
        />
      </View>
    );
  }

  return (
    <>
      <WellnessInsightsCarousel insights={insights} />

      <WellnessMetricFilters selected={selectedMetrics} onToggle={handleToggleMetric} />

      <View style={styles.chartCard}>
        <View style={styles.chartHeader}>
          <Text style={styles.chartTitle}>All Metrics</Text>
          <Text style={styles.chartRange}>{dateRange}</Text>
        </View>

        <WellnessAllMetricsChart
          checkIns={historyCheckIns}
          selectedMetrics={selectedMetrics}
          tickLabels={tickLabels}
        />
      </View>

      <WellnessMetricDetailSection checkIns={historyCheckIns} />
    </>
  );
}

const styles = StyleSheet.create({
  emptyWrap: {
    paddingTop: 24,
  },
  chartCard: {
    backgroundColor: AuthColors.background,
    borderRadius: 18,
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 14,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  chartHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  chartTitle: {
    fontSize: 17,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  chartRange: {
    fontSize: 13,
    color: AuthColors.quickAddLabel,
  },
});
