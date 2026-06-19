import { StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthShadow } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

interface LifeStatsRowProps {
  memories: number;
  milestones: number;
  checkIns: number;
  embedded?: boolean;
}

export function LifeStatsRow({
  memories,
  milestones,
  checkIns,
  embedded = false,
}: LifeStatsRowProps) {
  const items = [
    { value: memories, label: 'Memories' },
    { value: milestones, label: 'Milestones' },
    { value: checkIns, label: 'Check-ins' },
  ];

  return (
    <View style={[styles.row, embedded ? styles.rowEmbedded : null]}>
      {items.map((item) => (
        <View key={item.label} style={[styles.card, embedded ? styles.cardEmbedded : null]}>
          <Text style={styles.value}>{item.value}</Text>
          <Text style={styles.label}>{item.label}</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 24,
  },
  rowEmbedded: {
    marginBottom: 0,
  },
  card: {
    flex: 1,
    backgroundColor: AuthColors.surfaceWarm,
    borderRadius: 20,
    paddingVertical: 16,
    paddingHorizontal: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: AuthColors.border,
    ...AuthShadow.soft,
  },
  cardEmbedded: {
    backgroundColor: AuthColors.field,
  },
  value: {
    fontSize: 30,
    lineHeight: 34,
    ...withAppFont('700'),
    color: AuthColors.text,
    marginBottom: 4,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.4,
    color: AuthColors.textMuted,
    textTransform: 'uppercase',
  },
});
