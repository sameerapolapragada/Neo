import type { ComponentProps, ReactNode } from 'react';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { formatTimelineCardDate } from '@/utils/timelineDate';
import type { FutureSnapshot, Memory } from '@/types';

function TimelineRowCard({
  children,
  onPress,
  variant = 'default',
}: {
  children: ReactNode;
  onPress?: () => void;
  variant?: 'default' | 'weight' | 'wellness';
}) {
  const cardStyle = [
    styles.rowCard,
    variant === 'weight' && styles.rowCardWeight,
    variant === 'wellness' && styles.rowCardWellness,
  ];

  if (onPress) {
    return (
      <Pressable
        accessibilityRole="button"
        onPress={onPress}
        style={({ pressed }) => [...cardStyle, pressed && styles.pressed]}>
        {children}
      </Pressable>
    );
  }

  return <View style={cardStyle}>{children}</View>;
}

function TimelineTitleRow({
  title,
  date,
  subtitle,
}: {
  title: string;
  date: string;
  subtitle?: string;
}) {
  return (
    <View style={styles.copy}>
      <View style={styles.titleRow}>
        <Text style={styles.rowTitle} numberOfLines={1}>
          {title}
        </Text>
        <Text style={styles.rowDate}>{formatTimelineCardDate(date)}</Text>
      </View>
      {subtitle ? <Text style={styles.rowSubtitle}>{subtitle}</Text> : null}
    </View>
  );
}

export function LifePhotoMemoryCard({
  memory,
  onPress,
}: {
  memory: Memory;
  onPress?: () => void;
}) {
  return (
    <TimelineRowCard onPress={onPress}>
      {memory.photo_uri ? (
        <Image source={{ uri: memory.photo_uri }} style={styles.thumbnail} contentFit="cover" />
      ) : (
        <View style={[styles.thumbnail, styles.thumbnailFallback]}>
          <Text style={styles.thumbnailEmoji}>📷</Text>
        </View>
      )}
      <TimelineTitleRow title={memory.title} date={memory.created_at} />
    </TimelineRowCard>
  );
}

export function LifeTextMilestoneCard({
  title,
  description,
  date,
  icon = 'ribbon-outline',
  onPress,
}: {
  title: string;
  description: string;
  date: string;
  icon?: ComponentProps<typeof Ionicons>['name'];
  label?: string;
  onPress?: () => void;
}) {
  return (
    <TimelineRowCard onPress={onPress}>
      <View style={styles.thumbnail}>
        <View style={[styles.iconBadge, styles.iconBadgeWarm]}>
          <Ionicons name={icon} size={18} color={AuthColors.background} />
        </View>
      </View>
      <TimelineTitleRow title={title} date={date} subtitle={description || undefined} />
    </TimelineRowCard>
  );
}

export function LifeSnapshotCard({ snapshot }: { snapshot: FutureSnapshot }) {
  return (
    <LifeTextMilestoneCard
      title="Future Snapshot"
      description={snapshot.today}
      date={snapshot.created_at}
      icon="sparkles-outline"
    />
  );
}

export function LifeWellnessCard({
  date,
  onPress,
}: {
  date: string;
  onPress?: () => void;
}) {
  return (
    <TimelineRowCard onPress={onPress} variant="wellness">
      <View style={styles.thumbnail}>
        <View style={[styles.iconBadge, styles.iconBadgeWellness]}>
          <Ionicons name="shield-checkmark" size={18} color={AuthColors.background} />
        </View>
      </View>
      <TimelineTitleRow title="Weekly Wellness Check" date={date} />
    </TimelineRowCard>
  );
}

export function LifeWeightCard({
  weight,
  date,
  onPress,
}: {
  weight: string;
  date: string;
  onPress?: () => void;
}) {
  return (
    <TimelineRowCard onPress={onPress} variant="weight">
      <View style={styles.thumbnail}>
        <View style={[styles.iconBadge, styles.iconBadgeWeight]}>
          <Ionicons name="paw" size={18} color={AuthColors.background} />
        </View>
      </View>
      <TimelineTitleRow title="Weight Update" date={date} subtitle={weight} />
    </TimelineRowCard>
  );
}

export function getMemoryTimelineDotColor(memory: Memory): string {
  const title = memory.title.toLowerCase();
  const category = memory.category?.toLowerCase() ?? '';

  if (
    memory.entry_type === 'milestone' ||
    category.includes('birthday') ||
    title.includes('birthday')
  ) {
    return AuthColors.timelineBirthday;
  }

  return AuthColors.timelineMemory;
}

export function LifeAddMemoryPrompt({ onPress }: { onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.promptCard, pressed && styles.pressed]}>
      <View style={styles.promptPhoto}>
        <Text style={styles.promptEmoji}>🐕</Text>
        <Pressable style={styles.promptButton} onPress={onPress}>
          <Text style={styles.promptButtonText}>+ Add Memory</Text>
        </Pressable>
      </View>
      <View style={styles.promptBody}>
        <Text style={styles.promptTitle}>Start your life timeline</Text>
        <Text style={styles.promptDescription}>
          Capture your first memory, milestone, or everyday moment with a photo and a note.
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  rowCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  rowCardWeight: {
    backgroundColor: AuthColors.timelineWeightSoft,
    borderColor: 'transparent',
  },
  rowCardWellness: {
    backgroundColor: AuthColors.timelineWellnessSoft,
    borderColor: 'transparent',
  },
  thumbnail: {
    width: 52,
    height: 52,
    borderRadius: 12,
    backgroundColor: AuthColors.background,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  thumbnailFallback: {
    backgroundColor: AuthColors.weightBadgeBackground,
  },
  thumbnailEmoji: {
    fontSize: 22,
  },
  iconBadge: {
    width: 34,
    height: 34,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconBadgeWeight: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  iconBadgeWellness: {
    backgroundColor: AuthColors.timelineWellness,
  },
  iconBadgeWarm: {
    backgroundColor: AuthColors.timelineBirthday,
  },
  copy: {
    flex: 1,
    minWidth: 0,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
  },
  rowTitle: {
    flex: 1,
    fontSize: 16,
    lineHeight: 22,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  rowDate: {
    fontSize: 13,
    lineHeight: 18,
    color: AuthColors.onboardingTextMuted,
  },
  rowSubtitle: {
    ...AuthTypography.body,
    fontSize: 14,
    lineHeight: 20,
    color: AuthColors.onboardingTextMuted,
    marginTop: 2,
  },
  promptCard: {
    backgroundColor: AuthColors.card,
    borderRadius: 22,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: AuthColors.border,
  },
  promptPhoto: {
    height: 200,
    backgroundColor: AuthColors.primarySoft,
    alignItems: 'center',
    justifyContent: 'center',
  },
  promptEmoji: {
    fontSize: 64,
    opacity: 0.28,
  },
  promptButton: {
    position: 'absolute',
    backgroundColor: AuthColors.onboardingPrimary,
    borderRadius: 999,
    paddingHorizontal: 20,
    paddingVertical: 12,
  },
  promptButtonText: {
    color: AuthColors.background,
    ...withAppFont('700'),
    fontSize: 14,
  },
  promptBody: {
    backgroundColor: AuthColors.weightBadgeBackground,
    paddingHorizontal: 18,
    paddingVertical: 16,
  },
  promptTitle: {
    fontSize: 20,
    lineHeight: 26,
    ...withAppFont('700'),
    color: AuthColors.text,
    marginBottom: 6,
  },
  promptDescription: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.onboardingTextMuted,
  },
  pressed: {
    opacity: 0.92,
  },
});
