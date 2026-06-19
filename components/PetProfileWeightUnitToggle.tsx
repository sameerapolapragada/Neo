import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import type { WeightUnit } from '@/types';

interface PetProfileWeightUnitToggleProps {
  value: WeightUnit;
  onChange: (unit: WeightUnit) => void;
}

export function PetProfileWeightUnitToggle({ value, onChange }: PetProfileWeightUnitToggleProps) {
  return (
    <View style={styles.wrap}>
      {(['kg', 'lbs'] as const).map((unit) => {
        const selected = value === unit;

        return (
          <Pressable
            key={unit}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(unit)}
            style={({ pressed }) => [
              styles.unit,
              selected && styles.unitSelected,
              pressed && styles.pressed,
            ]}>
            <Text style={[styles.unitText, selected && styles.unitTextSelected]}>{unit}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    backgroundColor: AuthColors.card,
    borderRadius: 999,
    padding: 3,
    borderWidth: 1,
    borderColor: AuthColors.border,
  },
  unit: {
    minWidth: 42,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    alignItems: 'center',
  },
  unitSelected: {
    backgroundColor: AuthColors.primary,
  },
  unitText: {
    fontSize: 13,
    fontWeight: '700',
    color: AuthColors.textMuted,
    textTransform: 'lowercase',
  },
  unitTextSelected: {
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.88,
  },
});
