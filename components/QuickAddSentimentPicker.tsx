import { Pressable, StyleSheet, Text, View } from 'react-native';

import { MILESTONE_SENTIMENTS } from '@/constants/memoryForm';
import { AuthColors } from '@/constants/authTheme';
import type { MilestoneSentiment } from '@/types';

interface QuickAddSentimentPickerProps {
  value?: MilestoneSentiment;
  onChange: (sentiment: MilestoneSentiment) => void;
  variant?: 'default' | 'quickAdd';
}

export function QuickAddSentimentPicker({
  value,
  onChange,
  variant = 'default',
}: QuickAddSentimentPickerProps) {
  const isQuickAdd = variant === 'quickAdd';

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, isQuickAdd && styles.labelQuickAdd]}>How did it feel?</Text>
      <View style={styles.row}>
        {MILESTONE_SENTIMENTS.map((item) => {
          const selected = value === item.label;

          return (
            <Pressable
              key={item.label}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              onPress={() => onChange(item.label)}
              style={({ pressed }) => [
                styles.chip,
                isQuickAdd ? styles.chipQuickAdd : styles.chipDefault,
                selected && (isQuickAdd ? styles.chipQuickAddSelected : styles.chipSelected),
                pressed && styles.pressed,
              ]}>
              <Text style={styles.emoji}>{item.emoji}</Text>
              <Text
                style={[
                  styles.chipText,
                  isQuickAdd && styles.chipTextQuickAdd,
                  selected && styles.chipTextSelected,
                ]}>
                {item.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 16,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.8,
    color: AuthColors.textMuted,
    marginBottom: 10,
    textTransform: 'uppercase',
  },
  labelQuickAdd: {
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
  },
  row: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  chipDefault: {
    backgroundColor: AuthColors.field,
    borderWidth: 1,
    borderColor: AuthColors.border,
  },
  chipQuickAdd: {
    backgroundColor: AuthColors.quickAddField,
    borderWidth: 1,
    borderColor: AuthColors.quickAddField,
  },
  chipSelected: {
    backgroundColor: AuthColors.primary,
    borderColor: AuthColors.primary,
  },
  chipQuickAddSelected: {
    backgroundColor: AuthColors.onboardingPrimary,
    borderColor: AuthColors.onboardingPrimary,
  },
  emoji: {
    fontSize: 14,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  chipTextQuickAdd: {
    color: AuthColors.quickAddLabel,
  },
  chipTextSelected: {
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.9,
  },
});
