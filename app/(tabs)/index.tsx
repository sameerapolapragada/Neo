import { router } from 'expo-router';
import { useMemo } from 'react';
import { Platform, ScrollView, StyleSheet, View } from 'react-native';

import { EmptyState } from '@/components/EmptyState';
import { HomeLandingScreen } from '@/components/HomeLandingScreen';
import { LifeProfilePanel } from '@/components/LifeProfilePanel';
import { LifeTimelineFeed } from '@/components/LifeTimelineFeed';
import { LoadingState } from '@/components/LoadingState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import type { Memory, TimelineEntry } from '@/types';

export default function HomeScreen() {
  const { pet, memories, weightEntries, loading, remoteSyncPending } = usePet();
  const { horizontalPadding } = useResponsive();

  const timelineEntries = useMemo<TimelineEntry[]>(
    () =>
      memories
        .map((memory) => ({ type: 'memory' as const, data: memory }))
        .sort(
          (a, b) =>
            new Date(b.data.created_at).getTime() - new Date(a.data.created_at).getTime(),
        ),
    [memories],
  );

  function handleMemoryPress(memory: Memory) {
    router.push(`/memory/${memory.id}`);
  }

  const isEmptyTimeline = timelineEntries.length === 0;

  if (loading) {
    return (
      <SafeScreen style={styles.screen}>
        <LoadingState message="Loading your pet's story..." />
      </SafeScreen>
    );
  }

  if (!pet) {
    return (
      <SafeScreen style={styles.screen}>
        <EmptyState
          title="No pet profile yet"
          message="Create a profile to start building your pet's memory story."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </SafeScreen>
    );
  }

  if (isEmptyTimeline) {
    return (
      <SafeScreen style={styles.landingScreen} edges={[]}>
        <OfflineBanner visible={remoteSyncPending} />
        <HomeLandingScreen
          variant="home"
          onPrimaryAction={() => router.push('/(tabs)/add')}
        />
      </SafeScreen>
    );
  }

  return (
    <SafeScreen style={styles.screen} edges={['top']}>
      <ScrollView
        contentContainerStyle={[styles.content, { paddingHorizontal: horizontalPadding }]}
        showsVerticalScrollIndicator={false}>
        <OfflineBanner visible={remoteSyncPending} />
        <LifeProfilePanel pet={pet} weightEntries={weightEntries} />
        <LifeTimelineFeed entries={timelineEntries} onMemoryPress={handleMemoryPress} />
      </ScrollView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.emptyTimelineBackground,
  },
  landingScreen: {
    backgroundColor: AuthColors.emptyTimelineBackground,
  },
  content: {
    paddingTop: Spacing.md,
    paddingBottom: Platform.OS === 'ios' ? 130 : 110,
  },
});
