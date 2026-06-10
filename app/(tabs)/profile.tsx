import { router } from 'expo-router';
import { StyleSheet, Text } from 'react-native';

import { AppHeader } from '@/components/AppHeader';
import { EmptyState } from '@/components/EmptyState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PetCard } from '@/components/PetCard';
import { PrimaryButton } from '@/components/PrimaryButton';
import { Card } from '@/components/SafeScreen';
import { ScreenLayout } from '@/components/ScreenLayout';
import { Colors, DISCLAIMER, Spacing, Typography } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { isSupabaseConfigured } from '@/lib/supabase';

export default function ProfileScreen() {
  const { pet, loading, remoteSyncPending } = usePet();

  if (!loading && !pet) {
    return (
      <ScreenLayout scrollable={false}>
        <EmptyState
          title="No profile yet"
          message="Create your pet profile to personalize Neo."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </ScreenLayout>
    );
  }

  return (
    <ScreenLayout loading={loading} loadingMessage="Loading profile...">
      <OfflineBanner visible={remoteSyncPending} />

      {pet ? (
        <>
          <AppHeader title="Profile" subtitle="Your pet's details and app settings." />

          <PetCard pet={pet} />

          <PrimaryButton
            title="Edit Pet Profile"
            variant="outline"
            onPress={() => router.push('/pet-profile')}
            style={styles.button}
          />

          <Card style={styles.infoCard}>
            <Text style={styles.infoTitle}>Storage</Text>
            <Text style={styles.infoText}>
              {isSupabaseConfigured
                ? remoteSyncPending
                  ? 'Cloud sync pending. Your latest changes are stored on this device.'
                  : 'Connected to Supabase with local offline backup.'
                : 'Using local storage on this device. Add Supabase keys to enable cloud sync.'}
            </Text>
          </Card>

          <Card style={styles.disclaimerCard}>
            <Text style={styles.disclaimerTitle}>Safety Disclaimer</Text>
            <Text style={styles.disclaimerText}>{DISCLAIMER}</Text>
          </Card>
        </>
      ) : null}
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  button: {
    marginTop: Spacing.lg,
  },
  infoCard: {
    marginTop: Spacing.lg,
  },
  infoTitle: {
    ...Typography.label,
    color: Colors.text,
    marginBottom: 6,
  },
  infoText: {
    ...Typography.body,
    color: Colors.textSecondary,
  },
  disclaimerCard: {
    marginTop: Spacing.md,
    backgroundColor: Colors.disclaimerBg,
  },
  disclaimerTitle: {
    ...Typography.label,
    color: Colors.text,
    marginBottom: 6,
  },
  disclaimerText: {
    ...Typography.caption,
    color: Colors.textSecondary,
  },
});
