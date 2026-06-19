import { StyleSheet, Text, View } from 'react-native';

import { WellnessHistoryRow } from '@/components/WellnessHistoryRow';
import { AuthColors } from '@/constants/authTheme';
import type { WellnessCheckIn } from '@/types';

interface WellnessPreviousCheckInsProps {
  checkIns: WellnessCheckIn[];
  excludeWeekStart?: string;
}

export function WellnessPreviousCheckIns({
  checkIns,
  excludeWeekStart,
}: WellnessPreviousCheckInsProps) {
  const rows = checkIns
    .filter((checkIn) => checkIn.week_start.slice(0, 10) !== excludeWeekStart)
    .sort((a, b) => new Date(b.week_start).getTime() - new Date(a.week_start).getTime())
    .slice(0, 6);

  if (rows.length === 0) return null;

  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>Previous Check-ins</Text>
      {rows.map((checkIn) => (
        <WellnessHistoryRow key={checkIn.id} checkIn={checkIn} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginTop: 8,
    paddingBottom: 8,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
});
