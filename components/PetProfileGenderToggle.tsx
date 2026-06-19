import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import type { PetGender } from '@/types';

const OPTIONS: { value: PetGender; label: string; symbol: string }[] = [
  { value: 'Male', label: 'Male', symbol: '♂' },
  { value: 'Female', label: 'Female', symbol: '♀' },
  { value: 'Neutered', label: 'Neutered', symbol: '♂' },
  { value: 'Spayed', label: 'Spayed', symbol: '♀' },
  { value: 'Unknown', label: 'Unknown', symbol: '?' },
];

interface PetProfileGenderToggleProps {
  value: PetGender;
  onChange: (gender: PetGender) => void;
}

export function PetProfileGenderToggle({ value, onChange }: PetProfileGenderToggleProps) {
  return (
    <View style={styles.row}>
      {OPTIONS.map((option) => {
        const selected = value === option.value;

        return (
          <Pressable
            key={option.value}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(option.value)}
            style={({ pressed }) => [
              styles.pill,
              selected && styles.pillSelected,
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.symbol, selected && styles.pillTextSelected]}>{option.symbol}</Text>
            <Text style={[styles.label, selected && styles.pillTextSelected]}>{option.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 8,
  },
  pill: {
    flex: 1,
    minHeight: 38,
    borderRadius: 999,
    backgroundColor: AuthColors.card,
    borderWidth: 1,
    borderColor: AuthColors.border,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    paddingHorizontal: 8,
  },
  pillSelected: {
    backgroundColor: AuthColors.primary,
    borderColor: AuthColors.primary,
  },
  symbol: {
    fontSize: 14,
    color: AuthColors.textMuted,
    fontWeight: '700',
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  pillTextSelected: {
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.88,
  },
});
