import { useMemo, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { WellnessAllMetricsChart } from '@/components/WellnessAllMetricsChart';
import {
  WellnessHistoryCardHeader,
  WellnessHistoryPeriodNavigator,
  WellnessHistoryRangeSelector,
} from '@/components/WellnessHistoryCardHeader';
import { WellnessInsightsCarousel } from '@/components/WellnessInsightsCarousel';
import { WellnessMetricFilters } from '@/components/WellnessMetricFilters';
import { WELLNESS_METRICS } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import {
  buildMetricInsights,
  filterCheckInsForPeriod,
  formatPeriodLabel,
  getPeriodChartTickLabels,
  hasWellnessHistory,
  type WellnessHistoryRange,
} from '@/utils/wellnessAnalytics';
import type { WellnessCheckIn, WellnessMetricId } from '@/types';

interface WellnessHistoryViewProps {
  checkIns: WellnessCheckIn[];
  onBack: () => void;
}

export function WellnessHistoryView({ checkIns, onBack }: WellnessHistoryViewProps) {
  const [range, setRange] = useState<WellnessHistoryRange>('monthly');
  const [periodOffset, setPeriodOffset] = useState(0);
  const [showFilters, setShowFilters] = useState(false);
  const [selectedMetrics, setSelectedMetrics] = useState<WellnessMetricId[]>(
    WELLNESS_METRICS.map((metric) => metric.id),
  );

  const filteredCheckIns = useMemo(
    () => filterCheckInsForPeriod(checkIns, range, periodOffset),
    [checkIns, periodOffset, range],
  );

  const insights = useMemo(() => buildMetricInsights(filteredCheckIns), [filteredCheckIns]);
  const tickLabels = useMemo(
    () => getPeriodChartTickLabels(range, periodOffset),
    [periodOffset, range],
  );
  const periodLabel = useMemo(
    () => formatPeriodLabel(range, periodOffset),
    [periodOffset, range],
  );
  const hasHistory = hasWellnessHistory(checkIns);

  function handleRangeChange(nextRange: WellnessHistoryRange) {
    setRange(nextRange);
    setPeriodOffset(0);
  }

  function handleToggleMetric(metricId: WellnessMetricId) {
    setSelectedMetrics((current) => {
      if (current.includes(metricId)) {
        if (current.length === 1) return current;
        return current.filter((id) => id !== metricId);
      }
      return [...current, metricId];
    });
  }

  if (!hasHistory) {
    return (
      <View style={styles.emptyWrap}>
        <WellnessHistoryCardHeader onBack={onBack} onFilter={() => {}} />
        <Text style={styles.emptyTitle}>No wellness history yet</Text>
        <Text style={styles.emptyMessage}>
          Complete your first weekly check-in to unlock trends and insights.
        </Text>
      </View>
    );
  }

  return (
    <>
      <WellnessHistoryCardHeader
        onBack={onBack}
        onFilter={() => setShowFilters((current) => !current)}
      />

      <WellnessHistoryRangeSelector value={range} onChange={handleRangeChange} />

      <WellnessHistoryPeriodNavigator
        label={periodLabel}
        canGoPrevious={periodOffset > -12}
        canGoNext={periodOffset < 0}
        onPrevious={() => setPeriodOffset((current) => current - 1)}
        onNext={() => setPeriodOffset((current) => current + 1)}
      />

      <WellnessAllMetricsChart
        checkIns={filteredCheckIns}
        selectedMetrics={selectedMetrics}
        tickLabels={tickLabels}
      />

      {showFilters ? (
        <WellnessMetricFilters selected={selectedMetrics} onToggle={handleToggleMetric} />
      ) : null}

      <WellnessInsightsCarousel insights={insights} />
    </>
  );
}

export function getDefaultSelectedMetrics(): WellnessMetricId[] {
  return WELLNESS_METRICS.map((metric) => metric.id);
}

const styles = StyleSheet.create({
  emptyWrap: {
    paddingBottom: 8,
  },
  emptyTitle: {
    fontSize: 18,
    ...withAppFont('700'),
    color: AuthColors.text,
    marginBottom: 8,
  },
  emptyMessage: {
    fontSize: 14,
    lineHeight: 21,
    color: AuthColors.textMuted,
  },
});
