import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

export type WellnessView = 'check-in' | 'history';

interface WellnessViewToggleProps {
  value: WellnessView;
  onChange: (value: WellnessView) => void;
}

export function WellnessViewToggle({ value, onChange }: WellnessViewToggleProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ selected: value === 'check-in' }}
        onPress={() => onChange('check-in')}
        style={({ pressed }) => [
          styles.segment,
          value === 'check-in' && styles.segmentActive,
          pressed && styles.pressed,
        ]}>
        <Text style={[styles.segmentText, value === 'check-in' && styles.segmentTextActive]}>
          Check-In
        </Text>
      </Pressable>

      <Pressable
        accessibilityRole="button"
        accessibilityState={{ selected: value === 'history' }}
        onPress={() => onChange('history')}
        style={({ pressed }) => [
          styles.segment,
          value === 'history' && styles.segmentActive,
          pressed && styles.pressed,
        ]}>
        <Text style={[styles.segmentText, value === 'history' && styles.segmentTextActive]}>
          History
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    backgroundColor: AuthColors.quickAddField,
    borderRadius: 999,
    padding: 4,
    marginHorizontal: 20,
    marginTop: -22,
    marginBottom: 18,
    zIndex: 2,
  },
  segment: {
    flex: 1,
    minHeight: 40,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
  },
  segmentActive: {
    backgroundColor: AuthColors.background,
  },
  segmentText: {
    fontSize: 15,
    fontWeight: '700',
    color: AuthColors.quickAddLabel,
  },
  segmentTextActive: {
    color: AuthColors.text,
  },
  pressed: {
    opacity: 0.92,
  },
});
