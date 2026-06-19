import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { MEMORY_CATEGORIES } from '@/constants/memoryForm';
import { AuthColors } from '@/constants/authTheme';
import type { MemoryCategory } from '@/types';

interface QuickAddCategoryPickerProps {
  value: MemoryCategory;
  onChange: (category: MemoryCategory) => void;
  variant?: 'card' | 'quickAdd';
}

export function QuickAddCategoryPicker({
  value,
  onChange,
  variant = 'card',
}: QuickAddCategoryPickerProps) {
  const isQuickAdd = variant === 'quickAdd';

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, isQuickAdd && styles.labelQuickAdd]}>Category</Text>
      <View style={styles.chipGrid}>
        {MEMORY_CATEGORIES.map((category) => {
          const selected = value === category.value;

          return (
            <Pressable
              key={category.value}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              onPress={() => onChange(category.value)}
              style={({ pressed }) => [
                styles.chip,
                isQuickAdd ? styles.chipQuickAdd : styles.chipCard,
                selected &&
                  (isQuickAdd ? styles.chipQuickAddSelected : styles.chipCardSelected),
                pressed && styles.pressed,
              ]}>
              {isQuickAdd ? (
                <Text style={styles.chipEmoji}>{category.emoji}</Text>
              ) : null}
              <Text
                style={[
                  styles.chipText,
                  isQuickAdd && styles.chipTextQuickAdd,
                  selected &&
                    (isQuickAdd ? styles.chipTextQuickAddSelected : styles.chipTextSelected),
                ]}>
                {category.value}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

export function QuickAddDateField({
  label,
  value,
  onPress,
}: {
  label: string;
  value: string;
  onPress: () => void;
}) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        onPress={onPress}
        style={({ pressed }) => [styles.dateField, pressed && styles.pressed]}>
        <Text style={styles.floatingLabel}>{label}</Text>
        <View style={styles.dateRow}>
          <Text style={styles.dateValue}>{value}</Text>
          <Ionicons name="calendar-outline" size={20} color={AuthColors.onboardingTextMuted} />
        </View>
      </Pressable>
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
  chipGrid: {
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
  chipCard: {
    backgroundColor: AuthColors.weightBadgeBackground,
  },
  chipCardSelected: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  chipQuickAdd: {
    backgroundColor: AuthColors.quickAddField,
  },
  chipQuickAddSelected: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  chipEmoji: {
    fontSize: 14,
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
  chipTextQuickAddSelected: {
    color: AuthColors.background,
  },
  dateField: {
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    borderRadius: 12,
    backgroundColor: AuthColors.background,
    paddingHorizontal: 14,
    paddingTop: 16,
    paddingBottom: 12,
    minHeight: 56,
  },
  floatingLabel: {
    position: 'absolute',
    top: -9,
    left: 10,
    paddingHorizontal: 4,
    backgroundColor: AuthColors.background,
    fontSize: 12,
    fontWeight: '500',
    color: AuthColors.onboardingTextMuted,
  },
  dateRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dateValue: {
    fontSize: 15,
    fontWeight: '600',
    color: AuthColors.text,
  },
  pressed: {
    opacity: 0.92,
  },
});
