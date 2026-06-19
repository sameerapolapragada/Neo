import { router } from 'expo-router';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, Platform, ScrollView, StyleSheet } from 'react-native';

import { AuthPrimaryButton } from '@/components/AuthPrimaryButton';
import { EmptyState } from '@/components/EmptyState';
import { LoadingState } from '@/components/LoadingState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { SafeScreen } from '@/components/SafeScreen';
import { WellnessCheckInHeader } from '@/components/WellnessCheckInHeader';
import { WellnessHistoryTab } from '@/components/WellnessHistoryTab';
import { WellnessMetricCard } from '@/components/WellnessMetricCard';
import { WellnessPreviousCheckIns } from '@/components/WellnessPreviousCheckIns';
import { WellnessTrendsHeader, type WellnessTrendRange } from '@/components/WellnessTrendsHeader';
import { WellnessViewToggle } from '@/components/WellnessViewToggle';
import { WELLNESS_METRICS, WELLNESS_METRIC_COUNT } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { showRemoteFallbackNotice } from '@/utils/feedback';
import {
  computeWellnessProgress,
  computeWellnessStreak,
  formatWeekRange,
  toWeekStartIso,
} from '@/utils/wellnessDate';
import type { WellnessMetricId, WellnessRatings } from '@/types';

type WellnessView = 'check-in' | 'history';

export default function WellnessScreen() {
  const {
    pet,
    wellnessCheckIns,
    loading,
    refresh,
    markRemoteSyncPending,
    remoteSyncPending,
  } = usePet();
  const { horizontalPadding } = useResponsive();
  const [view, setView] = useState<WellnessView>('check-in');
  const [trendRange, setTrendRange] = useState<WellnessTrendRange>('weekly');
  const [ratings, setRatings] = useState<WellnessRatings>({});
  const [saving, setSaving] = useState(false);

  const weekStart = useMemo(() => toWeekStartIso(), []);

  const currentCheckIn = useMemo(
    () =>
      wellnessCheckIns.find(
        (checkIn) => checkIn.week_start.slice(0, 10) === weekStart,
      ) ?? null,
    [wellnessCheckIns, weekStart],
  );

  useEffect(() => {
    setRatings(currentCheckIn?.ratings ?? {});
  }, [currentCheckIn]);

  const progress = useMemo(() => computeWellnessProgress(ratings), [ratings]);
  const streak = useMemo(
    () => computeWellnessStreak(wellnessCheckIns, weekStart),
    [wellnessCheckIns, weekStart],
  );
  const weekLabel = useMemo(() => formatWeekRange(weekStart), [weekStart]);
  const canSave = progress.completed === WELLNESS_METRIC_COUNT;

  const persistRatings = useCallback(
    async (nextRatings: WellnessRatings) => {
      if (!pet) return;

      setSaving(true);
      try {
        const { remoteFailed } = await database.saveWellnessCheckIn(
          pet.id,
          weekStart,
          nextRatings,
        );
        markRemoteSyncPending(remoteFailed);
        showRemoteFallbackNotice(remoteFailed);
        await refresh();
      } finally {
        setSaving(false);
      }
    },
    [markRemoteSyncPending, pet, refresh, weekStart],
  );

  function handleRatingChange(metricId: WellnessMetricId, value: number) {
    setRatings((current) => ({ ...current, [metricId]: value }));
  }

  async function handleSaveCheckIn() {
    if (!canSave) {
      Alert.alert(
        'Complete your check-in',
        'Please rate all five wellness areas before saving.',
      );
      return;
    }

    await persistRatings(ratings);
  }

  if (loading) {
    return (
      <SafeScreen style={styles.screen}>
        <LoadingState message="Loading wellness check-in..." />
      </SafeScreen>
    );
  }

  if (!pet) {
    return (
      <SafeScreen style={styles.screen}>
        <EmptyState
          title="Add a pet first"
          message="Create a pet profile to start weekly wellness check-ins."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </SafeScreen>
    );
  }

  return (
    <SafeScreen style={styles.screen} edges={['top']}>
      {view === 'check-in' ? (
        <WellnessCheckInHeader
          petName={pet.name}
          weekLabel={weekLabel}
          streak={streak}
          average={progress.average}
          completed={progress.completed}
          total={progress.total}
        />
      ) : (
        <WellnessTrendsHeader
          checkIns={wellnessCheckIns}
          range={trendRange}
          onRangeChange={setTrendRange}
        />
      )}

      <WellnessViewToggle value={view} onChange={setView} />

      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingHorizontal: horizontalPadding },
        ]}
        showsVerticalScrollIndicator={false}>
        <OfflineBanner visible={remoteSyncPending} />

        {view === 'check-in' ? (
          <>
            {WELLNESS_METRICS.map((metric) => (
              <WellnessMetricCard
                key={metric.id}
                metric={metric}
                value={ratings[metric.id]}
                onChange={(value) => handleRatingChange(metric.id, value)}
              />
            ))}

            <AuthPrimaryButton
              title={saving ? 'Saving...' : 'Save Check-In'}
              disabled={saving || !canSave}
              onPress={handleSaveCheckIn}
              variant="onboarding"
              style={styles.saveButton}
            />

            <WellnessPreviousCheckIns
              checkIns={wellnessCheckIns}
              excludeWeekStart={weekStart}
            />
          </>
        ) : (
          <WellnessHistoryTab checkIns={wellnessCheckIns} range={trendRange} />
        )}
      </ScrollView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.quickAddBackground,
  },
  content: {
    paddingBottom: Platform.OS === 'ios' ? 130 : 110,
  },
  saveButton: {
    borderRadius: 14,
    marginTop: 4,
    marginBottom: 8,
  },
});
