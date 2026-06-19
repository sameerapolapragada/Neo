import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';
import type { MemoryCategory, MemoryEntryType } from '@/types';

interface QuickAddHeaderProps {
  entryType: MemoryEntryType;
  category: MemoryCategory;
  title: string;
}

export function QuickAddHeader({ entryType, category, title }: QuickAddHeaderProps) {
  if (entryType === 'milestone') {
    return (
      <View style={styles.wrap}>
        <Text style={styles.label}>RECORD A MILESTONE</Text>
        <Text style={styles.milestoneTitle}>New Milestone</Text>
      </View>
    );
  }

  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>NEW MEMORY</Text>
      <View style={styles.titleRow}>
        <Text style={styles.title} numberOfLines={2}>
          {title.trim() || 'Untitled'}
        </Text>
        <View style={styles.badge}>
          <Ionicons name="camera-outline" size={12} color={AuthColors.quickAddLabel} />
          <Text style={styles.badgeText}>{category}</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 18,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.2,
    color: AuthColors.quickAddLabel,
    marginBottom: 8,
  },
  milestoneTitle: {
    fontSize: 34,
    lineHeight: 38,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: 12,
  },
  title: {
    flex: 1,
    fontSize: 34,
    lineHeight: 38,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: AuthColors.quickAddField,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginTop: 6,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: AuthColors.quickAddLabel,
  },
});
