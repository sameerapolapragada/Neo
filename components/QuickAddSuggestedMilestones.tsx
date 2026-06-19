import { Pressable, StyleSheet, Text, View } from 'react-native';

import { SUGGESTED_MILESTONES } from '@/constants/memoryForm';
import { AuthColors } from '@/constants/authTheme';

interface QuickAddSuggestedMilestonesProps {
  selectedTitle: string;
  onSelect: (title: string, category: string) => void;
  variant?: 'card' | 'quickAdd';
}

export function QuickAddSuggestedMilestones({
  selectedTitle,
  onSelect,
  variant = 'card',
}: QuickAddSuggestedMilestonesProps) {
  const isQuickAdd = variant === 'quickAdd';

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, isQuickAdd && styles.labelQuickAdd]}>Suggested Milestones</Text>
      <View style={styles.row}>
        {SUGGESTED_MILESTONES.map((item) => {
          const fullTitle = item.label;
          const selected = selectedTitle === fullTitle;

          return (
            <Pressable
              key={item.label}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              onPress={() => onSelect(fullTitle, item.label)}
              style={({ pressed }) => [
                styles.chip,
                isQuickAdd ? styles.chipQuickAdd : styles.chipCard,
                selected && (isQuickAdd ? styles.chipQuickAddSelected : styles.chipCardSelected),
                pressed && styles.pressed,
              ]}>
              <Text
                style={[
                  styles.chipText,
                  isQuickAdd && styles.chipTextQuickAdd,
                  selected && styles.chipTextSelected,
                ]}>
                {isQuickAdd ? `${item.emoji} ${item.label}` : item.label}
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
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.text,
    marginBottom: 10,
  },
  labelQuickAdd: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
  },
  row: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  chipCard: {
    backgroundColor: AuthColors.background,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  chipCardSelected: {
    backgroundColor: AuthColors.onboardingPrimary,
    borderColor: AuthColors.onboardingPrimary,
  },
  chipQuickAdd: {
    backgroundColor: AuthColors.quickAddField,
    borderWidth: 1,
    borderColor: AuthColors.quickAddField,
  },
  chipQuickAddSelected: {
    backgroundColor: AuthColors.onboardingPrimary,
    borderColor: AuthColors.onboardingPrimary,
  },
  chipText: {
    fontSize: 14,
    fontWeight: '600',
    color: AuthColors.text,
  },
  chipTextQuickAdd: {
    color: AuthColors.quickAddLabel,
  },
  chipTextSelected: {
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.92,
  },
});
