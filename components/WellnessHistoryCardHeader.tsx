import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import type { WellnessHistoryRange } from '@/utils/wellnessAnalytics';

interface WellnessHistoryCardHeaderProps {
  onBack: () => void;
  onFilter: () => void;
}

export function WellnessHistoryCardHeader({ onBack, onFilter }: WellnessHistoryCardHeaderProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Go back"
        onPress={onBack}
        style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
        <Ionicons name="arrow-back" size={22} color={AuthColors.text} />
      </Pressable>

      <Text style={styles.title}>Wellness History</Text>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Filter metrics"
        onPress={onFilter}
        style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
        <Ionicons name="reorder-three-outline" size={22} color={AuthColors.text} />
      </Pressable>
    </View>
  );
}

interface WellnessHistoryRangeSelectorProps {
  value: WellnessHistoryRange;
  onChange: (value: WellnessHistoryRange) => void;
}

export function WellnessHistoryRangeSelector({
  value,
  onChange,
}: WellnessHistoryRangeSelectorProps) {
  const options: { key: WellnessHistoryRange; label: string }[] = [
    { key: 'weekly', label: 'Week' },
    { key: 'monthly', label: 'Month' },
    { key: 'yearly', label: 'Year' },
  ];

  return (
    <View style={styles.rangeWrap}>
      {options.map((option) => {
        const selected = value === option.key;

        return (
          <Pressable
            key={option.key}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(option.key)}
            style={({ pressed }) => [
              styles.rangeSegment,
              selected && styles.rangeSegmentActive,
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.rangeText, selected && styles.rangeTextActive]}>
              {option.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

interface WellnessHistoryPeriodNavigatorProps {
  label: string;
  onPrevious: () => void;
  onNext: () => void;
  canGoPrevious: boolean;
  canGoNext: boolean;
}

export function WellnessHistoryPeriodNavigator({
  label,
  onPrevious,
  onNext,
  canGoPrevious,
  canGoNext,
}: WellnessHistoryPeriodNavigatorProps) {
  return (
    <View style={styles.periodRow}>
      <Pressable
        accessibilityRole="button"
        disabled={!canGoPrevious}
        onPress={onPrevious}
        style={({ pressed }) => [
          styles.periodButton,
          !canGoPrevious && styles.periodButtonDisabled,
          pressed && canGoPrevious && styles.pressed,
        ]}>
        <Ionicons
          name="chevron-back"
          size={18}
          color={canGoPrevious ? AuthColors.text : AuthColors.border}
        />
      </Pressable>

      <Text style={styles.periodLabel}>{label}</Text>

      <Pressable
        accessibilityRole="button"
        disabled={!canGoNext}
        onPress={onNext}
        style={({ pressed }) => [
          styles.periodButton,
          !canGoNext && styles.periodButtonDisabled,
          pressed && canGoNext && styles.pressed,
        ]}>
        <Ionicons
          name="chevron-forward"
          size={18}
          color={canGoNext ? AuthColors.text : AuthColors.border}
        />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  sideButton: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
  },
  rangeWrap: {
    flexDirection: 'row',
    backgroundColor: AuthColors.surface,
    borderRadius: 999,
    padding: 4,
    marginBottom: 16,
  },
  rangeSegment: {
    flex: 1,
    minHeight: 36,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rangeSegmentActive: {
    backgroundColor: AuthColors.primary,
  },
  rangeText: {
    fontSize: 14,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  rangeTextActive: {
    color: AuthColors.background,
  },
  periodRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  periodButton: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  periodButtonDisabled: {
    opacity: 0.4,
  },
  periodLabel: {
    ...AuthTypography.label,
    fontSize: 16,
    color: AuthColors.text,
  },
  pressed: {
    opacity: 0.75,
  },
});
