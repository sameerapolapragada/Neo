import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppHeader } from '@/components/AppHeader';
import { EmptyState } from '@/components/EmptyState';
import { MomentCard } from '@/components/MomentCard';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PrimaryButton } from '@/components/PrimaryButton';
import { ScreenLayout } from '@/components/ScreenLayout';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { database } from '@/lib/database';
import { generateMissingMoments } from '@/services/ai';
import { showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import type { MissingMoments } from '@/types';

export default function MomentsScreen() {
  const { pet, latestMoments, loading, refresh, markRemoteSyncPending, remoteSyncPending } =
    usePet();
  const [result, setResult] = useState<MissingMoments | null>(latestMoments);
  const [generating, setGenerating] = useState(false);

  useEffect(() => {
    setResult(latestMoments);
  }, [latestMoments]);

  async function handleGenerate() {
    if (!pet) return;

    setGenerating(true);
    try {
      const content = await generateMissingMoments(pet);
      const { moments, remoteFailed } = await database.saveMissingMoments(pet.id, content);
      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      setResult(moments);
      await refresh();
    } catch (error) {
      showSaveError('Missing moments analysis', error);
    } finally {
      setGenerating(false);
    }
  }

  if (!loading && !pet) {
    return (
      <ScreenLayout scrollable={false}>
        <EmptyState
          title="Add a pet first"
          message="Create a pet profile to discover missing moments."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </ScreenLayout>
    );
  }

  return (
    <ScreenLayout loading={loading} loadingMessage="Loading moments...">
      <OfflineBanner visible={remoteSyncPending} />

      <AppHeader
        title="Missing Moments"
        subtitle="Spot lifestyle memories you may be creating—and ones worth capturing this week."
        showDisclaimer
      />

      <PrimaryButton
        title={result ? 'Refresh Analysis' : 'Discover Missing Moments'}
        loading={generating}
        onPress={handleGenerate}
      />

      {result ? (
        <View style={styles.results}>
          <MomentCard
            title="Moments Being Created"
            items={result.moments_being_created}
            accent="green"
          />
          <MomentCard
            title="Moments Potentially Missing"
            items={result.moments_potentially_missing}
            accent="orange"
          />
          <MomentCard
            title="Suggestions for This Week"
            items={result.suggestions}
            accent="neutral"
          />
        </View>
      ) : (
        <View style={styles.results}>
          <EmptyState
            emoji="💡"
            title="Discover what's missing"
            message="Neo will suggest simple, free ways to capture more meaningful moments this week."
          />
        </View>
      )}
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  results: {
    marginTop: Spacing.lg,
  },
});
