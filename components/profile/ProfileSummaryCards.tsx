import { StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import {
  countCheckIns,
  countMemories,
  countMilestones,
  formatShortAge,
  formatSinceLabel,
  getProfileWeightValue,
} from '@/utils/profileStats';
import type { Memory, Pet, WellnessCheckIn, WeightEntry } from '@/types';

interface ProfileSummaryCardsProps {
  pet: Pet;
  weightEntries: WeightEntry[];
  memories: Memory[];
  checkIns: WellnessCheckIn[];
}

export function ProfileQuickStats({ pet, weightEntries }: Pick<ProfileSummaryCardsProps, 'pet' | 'weightEntries'>) {
  const stats = [
    { emoji: '🎂', value: formatShortAge(pet), label: 'Age' },
    { emoji: '⚖️', value: getProfileWeightValue(weightEntries, pet), label: 'Weight' },
    { emoji: '🏠', value: formatSinceLabel(pet.adoption_date, pet.created_at), label: 'Since' },
  ];

  return (
    <View style={styles.quickStats}>
      {stats.map((stat) => (
        <View key={stat.label} style={styles.quickStatCard}>
          <Text style={styles.quickStatEmoji}>{stat.emoji}</Text>
          <Text style={styles.quickStatValue}>{stat.value}</Text>
          <Text style={styles.quickStatLabel}>{stat.label}</Text>
        </View>
      ))}
    </View>
  );
}

export function ProfileActivitySummary({ memories, checkIns }: Pick<ProfileSummaryCardsProps, 'memories' | 'checkIns'>) {
  const items = [
    { label: 'Memories', value: countMemories(memories), color: AuthColors.onboardingPrimary },
    { label: 'Milestones', value: countMilestones(memories), color: AuthColors.accentWarm },
    { label: 'Check-ins', value: countCheckIns(checkIns), color: '#5B8DEF' },
  ];

  return (
    <View style={styles.activityCard}>
      {items.map((item, index) => (
        <View
          key={item.label}
          style={[styles.activityItem, index < items.length - 1 && styles.activityDivider]}>
          <Text style={[styles.activityValue, { color: item.color }]}>{item.value}</Text>
          <Text style={styles.activityLabel}>{item.label}</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  quickStats: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 12,
    marginBottom: 14,
  },
  quickStatCard: {
    flex: 1,
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingVertical: 12,
    paddingHorizontal: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    shadowColor: AuthColors.text,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  quickStatEmoji: {
    fontSize: 18,
    marginBottom: 6,
  },
  quickStatValue: {
    ...AuthTypography.label,
    fontSize: 16,
    lineHeight: 20,
    color: AuthColors.text,
    textAlign: 'center',
  },
  quickStatLabel: {
    ...AuthTypography.subheadingSm,
    marginTop: 4,
    fontSize: 12,
    color: AuthColors.textMuted,
  },
  activityCard: {
    flexDirection: 'row',
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingVertical: 16,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  activityItem: {
    flex: 1,
    alignItems: 'center',
  },
  activityDivider: {
    borderRightWidth: StyleSheet.hairlineWidth,
    borderRightColor: AuthColors.profileFieldBorder,
  },
  activityValue: {
    ...AuthTypography.heading3,
    marginBottom: 4,
  },
  activityLabel: {
    ...AuthTypography.subheadingSm,
    fontSize: 13,
    color: AuthColors.textMuted,
  },
});
