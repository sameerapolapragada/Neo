import { router } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';

import {
  getMemoryTimelineDotColor,
  LifePhotoMemoryCard,
  LifeTextMilestoneCard,
} from '@/components/LifeTimelineCards';
import { LifeTimelineEmptyState } from '@/components/LifeTimelineEmptyState';
import { LifeTimelineQuickActions } from '@/components/LifeTimelineQuickActions';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import {
  formatTimelineMonth,
  getTimelineMonthKey,
} from '@/utils/timelineDate';
import type { Memory, TimelineEntry } from '@/types';

type FeedItem = { id: string; date: string; entry: TimelineEntry };

interface LifeTimelineFeedProps {
  entries: TimelineEntry[];
  onMemoryPress?: (memory: Memory) => void;
}

export function LifeTimelineFeed({ entries, onMemoryPress }: LifeTimelineFeedProps) {
  const feedItems: FeedItem[] = entries.map((entry) => ({
    id: `${entry.type}-${entry.data.id}`,
    date: entry.data.created_at,
    entry,
  }));

  feedItems.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  if (entries.length === 0) {
    return <LifeTimelineEmptyState onAddMemory={() => router.push('/(tabs)/add')} />;
  }

  return (
    <View style={styles.wrap}>
      <LifeTimelineQuickActions />
      <Text style={styles.title}>Life Timeline</Text>

      <View style={styles.track}>
        <View style={styles.line} />

        <View style={styles.items}>
          {feedItems.map((item, index) => {
            const monthKey = getTimelineMonthKey(item.date);
            const previousMonthKey =
              index > 0 ? getTimelineMonthKey(feedItems[index - 1].date) : null;
            const showSectionLabel = monthKey !== previousMonthKey;
            const memory = item.entry.data as Memory;
            const dotColor = getMemoryTimelineDotColor(memory);

            return (
              <View key={item.id} style={styles.section}>
                {showSectionLabel ? (
                  <Text style={styles.sectionLabel}>{formatTimelineMonth(item.date)}</Text>
                ) : null}

                <View style={styles.itemRow}>
                  <View style={[styles.dot, { backgroundColor: dotColor }]} />
                  <View style={styles.cardWrap}>
                    {renderFeedItem(item, onMemoryPress)}
                  </View>
                </View>
              </View>
            );
          })}
        </View>
      </View>
    </View>
  );
}

function renderFeedItem(item: FeedItem, onMemoryPress?: (memory: Memory) => void) {
  const memory = item.entry.data as Memory;
  const handlePress = onMemoryPress ? () => onMemoryPress(memory) : undefined;

  if (memory.photo_uri) {
    return <LifePhotoMemoryCard memory={memory} onPress={handlePress} />;
  }

  const isMilestone = memory.entry_type === 'milestone';

  return (
    <LifeTextMilestoneCard
      title={memory.title}
      description={memory.description}
      date={memory.created_at}
      icon={isMilestone ? 'ribbon-outline' : 'calendar-outline'}
      onPress={handlePress}
    />
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 12,
  },
  title: {
    ...AuthTypography.heading4,
    color: AuthColors.text,
    marginBottom: 14,
  },
  track: {
    position: 'relative',
    paddingLeft: 24,
  },
  line: {
    position: 'absolute',
    left: 4,
    top: 8,
    bottom: 8,
    width: 2,
    backgroundColor: AuthColors.profileFieldBorder,
  },
  items: {
    gap: 14,
  },
  section: {
    gap: 10,
  },
  sectionLabel: {
    ...AuthTypography.subheadingSm,
    color: AuthColors.onboardingTextMuted,
    marginLeft: 8,
    marginBottom: 2,
  },
  itemRow: {
    position: 'relative',
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  cardWrap: {
    flex: 1,
  },
  dot: {
    position: 'absolute',
    left: -24,
    top: 24,
    width: 10,
    height: 10,
    borderRadius: 5,
    borderWidth: 2,
    borderColor: AuthColors.emptyTimelineBackground,
    zIndex: 1,
  },
});
