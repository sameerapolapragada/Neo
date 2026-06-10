import { router } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';

import { AppHeader } from '@/components/AppHeader';
import { EmptyState } from '@/components/EmptyState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PetCard } from '@/components/PetCard';
import { PrimaryButton } from '@/components/PrimaryButton';
import { Card } from '@/components/SafeScreen';
import { ScreenLayout } from '@/components/ScreenLayout';
import { SnapshotCard } from '@/components/SnapshotCard';
import { Colors, Spacing, Typography } from '@/constants/theme';
import { usePet } from '@/context/PetContext';

export default function HomeScreen() {
  const { pet, latestSnapshot, loading, remoteSyncPending } = usePet();

  if (!loading && !pet) {
    return (
      <ScreenLayout scrollable={false}>
        <EmptyState
          title="No pet profile yet"
          message="Create a profile to start building your pet's memory story."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </ScreenLayout>
    );
  }

  return (
    <ScreenLayout loading={loading} loadingMessage="Loading your pet's story...">
      <OfflineBanner visible={remoteSyncPending} />

      {pet ? (
        <>
          <AppHeader title={`Hi, ${pet.name}!`} subtitle="Every pet has a story." />

          <PetCard pet={pet} />

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Latest Future Snapshot</Text>
            {latestSnapshot ? (
              <SnapshotCard label="Today" content={latestSnapshot.today} />
            ) : (
              <Card>
                <EmptyState
                  emoji="✨"
                  title="No snapshot yet"
                  message="Answer a few lifestyle questions to generate your first future snapshot."
                  actionLabel="Generate Snapshot"
                  onAction={() => router.push('/(tabs)/snapshot')}
                />
              </Card>
            )}
          </View>

          <View style={styles.actions}>
            <PrimaryButton
              title="Generate Future Snapshot"
              onPress={() => router.push('/(tabs)/snapshot')}
            />
            <PrimaryButton
              title="Discover Missing Moments"
              variant="secondary"
              onPress={() => router.push('/(tabs)/moments')}
            />
            <PrimaryButton
              title="Add Memory"
              variant="outline"
              onPress={() => router.push('/(tabs)/timeline')}
            />
          </View>
        </>
      ) : null}
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  section: {
    marginTop: Spacing.lg,
  },
  sectionTitle: {
    ...Typography.subtitle,
    color: Colors.text,
    marginBottom: Spacing.md,
  },
  actions: {
    marginTop: Spacing.lg,
    gap: Spacing.sm,
  },
});
