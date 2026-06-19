import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { WellnessSparkline } from '@/components/WellnessMiniChart';
import { WELLNESS_BAR_COLORS, WELLNESS_INSIGHT_TINTS } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import { formatTrendDelta } from '@/utils/wellnessAnalytics';
import type { WellnessMetricInsight } from '@/utils/wellnessAnalytics';

const FEATURED_ORDER = ['energy', 'sleep', 'exercise'] as const;

export function WellnessInsightsCarousel({ insights }: { insights: WellnessMetricInsight[] }) {
  const featured = FEATURED_ORDER.map((id) => insights.find((insight) => insight.id === id)).filter(
    (insight): insight is WellnessMetricInsight => Boolean(insight && insight.points.length > 0),
  );

  if (featured.length === 0) return null;

  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>Insights</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.row}>
        {featured.map((insight) => {
          const color = WELLNESS_BAR_COLORS[insight.id];
          const points = insight.points.map((point) => point.value);

          return (
            <View
              key={insight.id}
              style={[styles.card, { backgroundColor: WELLNESS_INSIGHT_TINTS[insight.id] }]}>
              <View style={styles.cardTop}>
                <Text style={styles.emoji}>{insight.emoji}</Text>
                <View style={[styles.badge, { backgroundColor: `${color}22` }]}>
                  <Text style={[styles.badgeText, { color }]}>
                    {formatTrendDelta(insight.delta)}
                  </Text>
                </View>
              </View>

              <Text style={styles.title}>{insight.title}</Text>
              <Text style={[styles.status, { color }]}>{insight.status}</Text>

              <WellnessSparkline points={points} color={color} height={36} filled={false} />
            </View>
          );
        })}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 18,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  row: {
    gap: 12,
    paddingRight: 8,
  },
  card: {
    width: 156,
    borderRadius: 18,
    paddingHorizontal: 14,
    paddingVertical: 14,
  },
  cardTop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  emoji: {
    fontSize: 18,
  },
  badge: {
    borderRadius: 999,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  title: {
    fontSize: 15,
    ...withAppFont('700'),
    color: AuthColors.text,
    marginBottom: 2,
  },
  status: {
    fontSize: 13,
    fontWeight: '600',
    marginBottom: 8,
  },
});
