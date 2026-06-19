import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { WELLNESS_INSIGHT_TINTS, WELLNESS_METRICS } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import type { WellnessMetricId } from '@/types';

interface WellnessMetricFiltersProps {
  selected: WellnessMetricId[];
  onToggle: (metricId: WellnessMetricId) => void;
}

export function WellnessMetricFilters({ selected, onToggle }: WellnessMetricFiltersProps) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>Show Metrics</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.row}>
        {WELLNESS_METRICS.map((metric) => {
          const active = selected.includes(metric.id);

          return (
            <Pressable
              key={metric.id}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => onToggle(metric.id)}
              style={({ pressed }) => [
                styles.chip,
                { backgroundColor: WELLNESS_INSIGHT_TINTS[metric.id] },
                !active && styles.chipInactive,
                pressed && styles.pressed,
              ]}>
              <Text style={styles.chipEmoji}>{metric.emoji}</Text>
              <Text style={[styles.chipText, !active && styles.chipTextInactive]}>
                {metric.title}
              </Text>
            </Pressable>
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
    marginBottom: 10,
  },
  row: {
    gap: 8,
    paddingRight: 8,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  chipInactive: {
    opacity: 0.45,
  },
  chipEmoji: {
    fontSize: 14,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '700',
    color: AuthColors.text,
  },
  chipTextInactive: {
    color: AuthColors.quickAddLabel,
  },
  pressed: {
    opacity: 0.9,
  },
});
