import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import type { Species } from '@/types';

const SPECIES_OPTIONS = [
  { value: 'Dog' as const, emoji: '🐕', label: 'Dog' },
  { value: 'Cat' as const, emoji: '🐈', label: 'Cat' },
  { value: 'Bird' as const, emoji: '🐦', label: 'Bird' },
  { value: 'Other' as const, emoji: '🐾', label: 'Other' },
];

interface PetProfileSpeciesPickerProps {
  value: Species;
  onChange: (species: Species) => void;
}

export function PetProfileSpeciesPicker({ value, onChange }: PetProfileSpeciesPickerProps) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>SPECIES</Text>
      <View style={styles.row}>
        {SPECIES_OPTIONS.map((option) => {
          const selected =
            option.value === value ||
            (option.value === 'Other' &&
              !SPECIES_OPTIONS.some((item) => item.value === value && item.value !== 'Other'));

          return (
            <Pressable
              key={option.value}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              onPress={() => onChange(option.value)}
              style={({ pressed }) => [
                styles.card,
                selected && styles.cardSelected,
                pressed && styles.pressed,
              ]}>
              <Text style={styles.emoji}>{option.emoji}</Text>
              <Text style={[styles.cardLabel, selected && styles.cardLabelSelected]}>
                {option.label}
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
    marginBottom: 18,
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 1,
    color: AuthColors.textMuted,
    marginBottom: 10,
  },
  row: {
    flexDirection: 'row',
    gap: 10,
  },
  card: {
    flex: 1,
    minHeight: 88,
    borderRadius: 18,
    borderWidth: 1.5,
    borderColor: AuthColors.border,
    backgroundColor: AuthColors.card,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    gap: 6,
  },
  cardSelected: {
    borderColor: AuthColors.primary,
    backgroundColor: AuthColors.surface,
  },
  emoji: {
    fontSize: 24,
  },
  cardLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  cardLabelSelected: {
    color: AuthColors.primaryDark,
  },
  pressed: {
    opacity: 0.88,
  },
});
