import { StyleSheet, Text, View } from 'react-native';

import { TimelineItem } from '@/components/TimelineItem';
import { AuthColors } from '@/constants/authTheme';
import { Typography } from '@/constants/theme';
import type { Memory, TimelineEntry } from '@/types';

interface TimelineMonthGroupProps {
  label: string;
  entries: TimelineEntry[];
  onMemoryPress?: (memory: Memory) => void;
}

export function TimelineMonthGroup({ label, entries, onMemoryPress }: TimelineMonthGroupProps) {
  return (
    <View style={styles.group}>
      <Text style={styles.monthLabel}>{label}</Text>

      <View style={styles.track}>
        <View style={styles.line} />

        <View style={styles.items}>
          {entries.map((entry) => (
            <View key={`${entry.type}-${entry.data.id}`} style={styles.itemRow}>
              <View style={styles.dot} />
              <TimelineItem entry={entry} onMemoryPress={onMemoryPress} />
            </View>
          ))}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  group: {
    marginBottom: 24,
  },
  monthLabel: {
    ...Typography.caption,
    color: AuthColors.textMuted,
    marginBottom: 12,
  },
  track: {
    position: 'relative',
    paddingLeft: 28,
  },
  line: {
    position: 'absolute',
    left: 5,
    top: 18,
    bottom: 18,
    width: 2,
    backgroundColor: AuthColors.primarySoft,
  },
  items: {
    gap: 14,
  },
  itemRow: {
    position: 'relative',
    justifyContent: 'center',
    minHeight: 64,
  },
  dot: {
    position: 'absolute',
    left: -23,
    top: '50%',
    marginTop: -6,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: AuthColors.primary,
    zIndex: 1,
  },
});
