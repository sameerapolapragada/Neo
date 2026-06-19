import { useEffect, useMemo, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { router } from 'expo-router';

import { EmptyState } from '@/components/EmptyState';
import { LoadingState } from '@/components/LoadingState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { SafeScreen } from '@/components/SafeScreen';
import { TimelineMonthGroup } from '@/components/TimelineMonthGroup';
import { TimelineScreenHeader } from '@/components/TimelineScreenHeader';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { formatTimelineMonth } from '@/utils/timelineDate';
import type { Memory, TimelineEntry } from '@/types';

function groupTimelineEntries(entries: TimelineEntry[]) {
  const groups: { key: string; label: string; entries: TimelineEntry[] }[] = [];
  const indexByKey = new Map<string, number>();

  for (const entry of entries) {
    const key = entry.data.created_at.slice(0, 7);
    const label = formatTimelineMonth(entry.data.created_at);

    if (!indexByKey.has(key)) {
      indexByKey.set(key, groups.length);
      groups.push({ key, label, entries: [] });
    }

    groups[indexByKey.get(key)!].entries.push(entry);
  }

  return groups;
}

export default function TimelineScreen() {
  const { pet, memories, loading, remoteSyncPending } = usePet();
  const { horizontalPadding } = useResponsive();
  const [snapshots, setSnapshots] = useState<
    Awaited<ReturnType<typeof database.getFutureSnapshots>>
  >([]);
  const [snapshotsLoading, setSnapshotsLoading] = useState(false);

  useEffect(() => {
    if (pet) {
      setSnapshotsLoading(true);
      database
        .getFutureSnapshots(pet.id)
        .then(setSnapshots)
        .finally(() => setSnapshotsLoading(false));
    }
  }, [pet, memories]);

  const entries = useMemo<TimelineEntry[]>(() => {
    const combined: TimelineEntry[] = [
      ...memories.map((memory) => ({ type: 'memory' as const, data: memory })),
      ...snapshots.map((snapshot) => ({ type: 'snapshot' as const, data: snapshot })),
    ];

    return combined.sort(
      (a, b) =>
        new Date(b.data.created_at).getTime() - new Date(a.data.created_at).getTime(),
    );
  }, [memories, snapshots]);

  const monthGroups = useMemo(() => groupTimelineEntries(entries), [entries]);

  function handleMemoryPress(memory: Memory) {
    router.push(`/memory/${memory.id}`);
  }

  if (!loading && !pet) {
    return (
      <SafeScreen>
        <EmptyState
          title="No timeline yet"
          message="Create a pet profile to start your memory timeline."
        />
      </SafeScreen>
    );
  }

  if (loading || snapshotsLoading) {
    return (
      <SafeScreen>
        <LoadingState message="Loading timeline..." />
      </SafeScreen>
    );
  }

  return (
    <SafeScreen edges={['top']}>
      <ScrollView
        contentContainerStyle={[styles.content, { paddingHorizontal: horizontalPadding }]}
        showsVerticalScrollIndicator={false}>
        <TimelineScreenHeader />
        <OfflineBanner visible={remoteSyncPending} />

        {entries.length === 0 ? (
          <EmptyState
            emoji="📖"
            title="Your timeline is empty"
            message="Add a memory or generate a future snapshot to begin."
          />
        ) : (
          <View style={styles.list}>
            {monthGroups.map((group) => (
              <TimelineMonthGroup
                key={group.key}
                label={group.label}
                entries={group.entries}
                onMemoryPress={handleMemoryPress}
              />
            ))}
          </View>
        )}
      </ScrollView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  content: {
    paddingTop: Spacing.sm,
    paddingBottom: Spacing.xxl,
  },
  list: {
    marginTop: Spacing.md,
  },
});
