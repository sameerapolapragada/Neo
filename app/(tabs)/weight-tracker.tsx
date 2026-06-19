import { router } from 'expo-router';
import { Platform, ScrollView, StyleSheet } from 'react-native';

import { EmptyState } from '@/components/EmptyState';
import { LoadingState } from '@/components/LoadingState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { SafeScreen } from '@/components/SafeScreen';
import { WeightTrackerView } from '@/components/WeightTrackerView';
import { AuthColors } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import { formatWeight } from '@/utils/petProfile';
import type { WeightUnit } from '@/types';

export default function WeightTrackerScreen() {
  const {
    pet,
    weightEntries,
    loading,
    refresh,
    markRemoteSyncPending,
    remoteSyncPending,
  } = usePet();
  const { horizontalPadding } = useResponsive();

  async function handleAddWeight(value: string, unit: WeightUnit, recordedAt: string) {
    if (!pet) return;

    try {
      const { remoteFailed } = await database.saveWeightEntry(pet.id, {
        weight: formatWeight(value, unit) ?? `${value} ${unit}`,
        recorded_at: recordedAt,
      });
      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      await refresh();
    } catch (error) {
      showSaveError('Save weight', error);
      throw error;
    }
  }

  async function handleDeleteEntry(entryId: string) {
    if (!pet) return;

    try {
      const { remoteFailed } = await database.deleteWeightEntry(pet.id, entryId);
      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      await refresh();
    } catch (error) {
      showSaveError('Delete weight entry', error);
    }
  }

  if (loading) {
    return (
      <SafeScreen style={styles.screen}>
        <LoadingState message="Loading weight tracker..." />
      </SafeScreen>
    );
  }

  if (!pet) {
    return (
      <SafeScreen style={styles.screen}>
        <EmptyState
          title="Add a pet first"
          message="Create a pet profile to start tracking weight."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </SafeScreen>
    );
  }

  return (
    <SafeScreen style={styles.screen} edges={['top']}>
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingHorizontal: horizontalPadding },
        ]}
        showsVerticalScrollIndicator={false}>
        <OfflineBanner visible={remoteSyncPending} />

        <WeightTrackerView
          pet={pet}
          entries={weightEntries}
          onBack={() => router.back()}
          onAddWeight={handleAddWeight}
          onDeleteEntry={handleDeleteEntry}
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
    paddingTop: Spacing.sm,
    paddingBottom: Platform.OS === 'ios' ? 130 : 110,
  },
});
