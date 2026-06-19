import { router, useLocalSearchParams } from 'expo-router';
import { useMemo, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { EmptyState } from '@/components/EmptyState';
import { LoadingState } from '@/components/LoadingState';
import { MemoryDetailView } from '@/components/MemoryDetailView';
import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import { confirmDeleteMemory } from '@/utils/memoryActions';

function sortMemoriesChronologically<T extends { created_at: string }>(items: T[]): T[] {
  return [...items].sort(
    (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
  );
}

export default function MemoryDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { pet, memories, loading, refresh, markRemoteSyncPending } = usePet();
  const { horizontalPadding } = useResponsive();
  const [liked, setLiked] = useState(false);

  const sortedMemories = useMemo(() => sortMemoriesChronologically(memories), [memories]);
  const currentIndex = useMemo(
    () => sortedMemories.findIndex((memory) => memory.id === id),
    [id, sortedMemories],
  );
  const memory = currentIndex >= 0 ? sortedMemories[currentIndex] : null;

  function navigateToIndex(nextIndex: number) {
    const nextMemory = sortedMemories[nextIndex];
    if (!nextMemory) return;
    setLiked(false);
    router.replace(`/memory/${nextMemory.id}`);
  }

  async function handleDelete() {
    if (!pet || !memory) return;

    confirmDeleteMemory(async () => {
      try {
        const { remoteFailed } = await database.deleteMemory(pet.id, memory.id);
        markRemoteSyncPending(remoteFailed);
        showRemoteFallbackNotice(remoteFailed);
        await refresh();
        router.back();
      } catch (error) {
        showSaveError('Delete memory', error);
      }
    });
  }

  if (loading) {
    return (
      <SafeScreen style={styles.screen}>
        <LoadingState message="Loading memory..." />
      </SafeScreen>
    );
  }

  if (!memory) {
    return (
      <SafeScreen style={styles.screen}>
        <EmptyState
          title="Memory not found"
          message="This memory may have been deleted."
          actionLabel="Go Back"
          onAction={() => router.back()}
        />
      </SafeScreen>
    );
  }

  return (
    <SafeScreen style={styles.screen} edges={['top', 'bottom']}>
      <ScrollView
        contentContainerStyle={[styles.content, { paddingHorizontal: horizontalPadding }]}
        showsVerticalScrollIndicator={false}>
        <MemoryDetailView
          memory={memory}
          currentIndex={currentIndex}
          totalCount={sortedMemories.length}
          liked={liked}
          onBack={() => router.back()}
          onEdit={() => router.push(`/add-memory?id=${memory.id}`)}
          onDelete={handleDelete}
          onToggleLike={() => setLiked((current) => !current)}
          onPrevious={() => navigateToIndex(currentIndex - 1)}
          onNext={() => navigateToIndex(currentIndex + 1)}
        />
      </ScrollView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.screenBackground,
  },
  content: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingVertical: Spacing.lg,
  },
});
