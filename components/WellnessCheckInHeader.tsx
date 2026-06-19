import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

interface WellnessCheckInHeaderProps {
  petName: string;
  weekLabel: string;
  streak: number;
  average: number;
  completed: number;
  total: number;
}

export function WellnessCheckInHeader({
  petName,
  weekLabel,
  streak,
  average,
  completed,
  total,
}: WellnessCheckInHeaderProps) {
  const progress = total === 0 ? 0 : completed / total;

  return (
    <View style={styles.wrap}>
      <View style={styles.circleOne} />
      <View style={styles.circleTwo} />
      <View style={styles.circleThree} />

      <View style={styles.topRow}>
        <View style={styles.titleRow}>
          <Text style={styles.eyebrow}>WEEKLY CHECK-IN</Text>
          <View style={styles.durationBadge}>
            <Ionicons name="time-outline" size={12} color="rgba(255,255,255,0.92)" />
            <Text style={styles.durationText}>≈ 20 sec</Text>
          </View>
        </View>

        <View style={styles.progressRing}>
          <View style={styles.progressInner}>
            <Text style={styles.progressScore}>{average.toFixed(1)}</Text>
          </View>
          <Text style={styles.progressMeta}>
            {completed}/{total} done
          </Text>
        </View>
      </View>

      <Text style={styles.title}>{petName}&apos;s Wellness</Text>
      <Text style={styles.week}>{weekLabel}</Text>
      <Text style={styles.streak}>🔥 {streak} week streak</Text>

      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { width: `${Math.round(progress * 100)}%` }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: AuthColors.quickAddToggleActive,
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 28,
    overflow: 'hidden',
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
  },
  circleOne: {
    position: 'absolute',
    top: -36,
    right: -20,
    width: 140,
    height: 140,
    borderRadius: 70,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  circleTwo: {
    position: 'absolute',
    top: 40,
    right: 60,
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: 'rgba(255,255,255,0.06)',
  },
  circleThree: {
    position: 'absolute',
    bottom: -30,
    left: -20,
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 10,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
    paddingRight: 12,
  },
  eyebrow: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 0.8,
    color: 'rgba(255,255,255,0.82)',
  },
  durationBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(255,255,255,0.14)',
    borderRadius: 999,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  durationText: {
    fontSize: 11,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.92)',
  },
  progressRing: {
    alignItems: 'center',
    minWidth: 72,
  },
  progressInner: {
    width: 58,
    height: 58,
    borderRadius: 29,
    borderWidth: 3,
    borderColor: 'rgba(255,255,255,0.35)',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  progressScore: {
    fontSize: 18,
    ...withAppFont('700'),
    color: AuthColors.background,
  },
  progressMeta: {
    marginTop: 4,
    fontSize: 11,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.82)',
  },
  title: {
    fontSize: 34,
    lineHeight: 38,
    ...withAppFont('700'),
    color: AuthColors.background,
    marginBottom: 6,
  },
  week: {
    fontSize: 15,
    ...withAppFont('600'),
    color: 'rgba(255,255,255,0.88)',
    marginBottom: 8,
  },
  streak: {
    fontSize: 14,
    ...withAppFont('600'),
    color: 'rgba(255,255,255,0.92)',
    marginBottom: 14,
  },
  progressTrack: {
    height: 4,
    borderRadius: 999,
    backgroundColor: 'rgba(255,255,255,0.18)',
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 999,
    backgroundColor: 'rgba(255,255,255,0.72)',
  },
});
