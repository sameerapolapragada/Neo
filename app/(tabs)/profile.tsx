import { router } from 'expo-router';
import { Alert, Platform, Pressable, ScrollView, StyleSheet, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { EmptyState } from '@/components/EmptyState';
import { LoadingState } from '@/components/LoadingState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PetProfileDetailView } from '@/components/PetProfileDetailView';
import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { usePet } from '@/context/PetContext';
import { database } from '@/lib/database';
import { auth } from '@/lib/auth';
import { showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';

function confirmLogOut() {
  Alert.alert('Log out', 'Are you sure you want to log out of your account?', [
    { text: 'Cancel', style: 'cancel' },
    {
      text: 'Log Out',
      style: 'destructive',
      onPress: async () => {
        await auth.signOut();
        router.replace('/login');
      },
    },
  ]);
}

export default function ProfileScreen() {
  const { pet, memories, weightEntries, wellnessCheckIns, loading, remoteSyncPending, refresh, markRemoteSyncPending, setPet } =
    usePet();

  async function handleVetSave(fields: { vet_name?: string; vet_clinic?: string }) {
    if (!pet) return;

    try {
      const { pet: savedPet, remoteFailed } = await database.savePet({
        id: pet.id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        age: pet.age,
        weight: pet.weight,
        photo_uri: pet.photo_uri,
        birthday: pet.birthday,
        gender: pet.gender,
        adoption_date: pet.adoption_date,
        microchip_id: pet.microchip_id,
        vet_name: 'vet_name' in fields ? fields.vet_name : pet.vet_name,
        vet_clinic: 'vet_clinic' in fields ? fields.vet_clinic : pet.vet_clinic,
      });

      setPet(savedPet);
      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      await refresh();
    } catch (error) {
      showSaveError('Save veterinary info', error);
    }
  }

  if (loading) {
    return (
      <SafeScreen style={styles.screen}>
        <LoadingState message="Loading profile..." />
      </SafeScreen>
    );
  }

  if (!pet) {
    return (
      <SafeScreen style={styles.screen}>
        <EmptyState
          title="No profile yet"
          message="Create your pet profile to personalize Neo."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Log out"
          onPress={confirmLogOut}
          style={({ pressed }) => [styles.emptyLogOut, pressed && styles.pressed]}>
          <Ionicons name="log-out-outline" size={20} color={AuthColors.error} />
          <Text style={styles.logOutLabel}>Log Out</Text>
        </Pressable>
      </SafeScreen>
    );
  }

  return (
    <SafeScreen style={styles.screen} edges={[]}>
      <OfflineBanner visible={remoteSyncPending} />

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <PetProfileDetailView
          pet={pet}
          memories={memories}
          weightEntries={weightEntries}
          wellnessCheckIns={wellnessCheckIns}
          onEdit={() => router.push('/pet-profile')}
          onWeightPress={() => router.push('/(tabs)/weight-tracker')}
          onVetSave={handleVetSave}
          onLogOut={confirmLogOut}
        />
      </ScrollView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.emptyTimelineBackground,
  },
  content: {
    flexGrow: 1,
    paddingBottom: Platform.OS === 'ios' ? 110 : 90,
  },
  emptyLogOut: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 24,
    marginHorizontal: 24,
    minHeight: 52,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: AuthColors.border,
    backgroundColor: AuthColors.surface,
  },
  logOutLabel: {
    ...AuthTypography.label,
    fontSize: 16,
    color: AuthColors.error,
  },
  pressed: {
    opacity: 0.85,
  },
});
