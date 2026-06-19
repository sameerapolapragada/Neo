import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import type { MemoryEntryType } from '@/types';

interface QuickAddTypeToggleProps {
  value: MemoryEntryType;
  onChange: (value: MemoryEntryType) => void;
}

export function QuickAddTypeToggle({ value, onChange }: QuickAddTypeToggleProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ selected: value === 'memory' }}
        onPress={() => onChange('memory')}
        style={({ pressed }) => [
          styles.segment,
          styles.segmentLeft,
          value === 'memory' && styles.segmentActive,
          pressed && styles.pressed,
        ]}>
        <Ionicons
          name="camera-outline"
          size={16}
          color={value === 'memory' ? AuthColors.background : AuthColors.quickAddLabel}
        />
        <Text style={[styles.segmentText, value === 'memory' && styles.segmentTextActive]}>
          Memory
        </Text>
      </Pressable>

      <Pressable
        accessibilityRole="button"
        accessibilityState={{ selected: value === 'milestone' }}
        onPress={() => onChange('milestone')}
        style={({ pressed }) => [
          styles.segment,
          styles.segmentRight,
          value === 'milestone' && styles.segmentActive,
          pressed && styles.pressed,
        ]}>
        <Ionicons
          name="ribbon-outline"
          size={16}
          color={value === 'milestone' ? AuthColors.background : AuthColors.quickAddLabel}
        />
        <Text style={[styles.segmentText, value === 'milestone' && styles.segmentTextActive]}>
          Milestone
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    backgroundColor: AuthColors.quickAddField,
    borderRadius: 16,
    padding: 4,
    marginBottom: 22,
  },
  segment: {
    flex: 1,
    minHeight: 44,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  segmentLeft: {
    marginRight: 2,
  },
  segmentRight: {
    marginLeft: 2,
  },
  segmentActive: {
    backgroundColor: AuthColors.quickAddToggleActive,
  },
  segmentText: {
    fontSize: 14,
    fontWeight: '700',
    color: AuthColors.quickAddLabel,
  },
  segmentTextActive: {
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.92,
  },
});
