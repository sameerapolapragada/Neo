import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { ProfileComingSoonSection } from '@/components/profile/ProfileComingSoonSection';
import { ProfileHeroSection } from '@/components/profile/ProfileHeroSection';
import { ProfileRecordsSection } from '@/components/profile/ProfileRecordsSection';
import { ProfileSectionCard } from '@/components/profile/ProfileSectionCard';
import { ProfileVeterinarySection } from '@/components/profile/ProfileVeterinarySection';
import {
  ProfileActivitySummary,
  ProfileQuickStats,
} from '@/components/profile/ProfileSummaryCards';
import { ProfileWeightTrackerCard } from '@/components/profile/ProfileWeightTrackerCard';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import {
  countMemories,
  formatBioPlaceholder,
  formatDualWeight,
  formatMicrochipNumber,
  formatProfileDate,
  getProfileWeightValue,
} from '@/utils/profileStats';
import type { Memory, Pet, WellnessCheckIn, WeightEntry } from '@/types';

interface PetProfileDetailViewProps {
  pet: Pet;
  memories: Memory[];
  weightEntries: WeightEntry[];
  wellnessCheckIns: WellnessCheckIn[];
  onEdit: () => void;
  onWeightPress: () => void;
  onVetSave: (fields: { vet_name?: string; vet_clinic?: string }) => Promise<void>;
  onLogOut?: () => void;
}

function formatEntryCount(count: number, singular: string, plural: string): string {
  return `${count} ${count === 1 ? singular : plural}`;
}

export function PetProfileDetailView({
  pet,
  memories,
  weightEntries,
  wellnessCheckIns,
  onEdit,
  onWeightPress,
  onVetSave,
  onLogOut,
}: PetProfileDetailViewProps) {
  const savedMemories = countMemories(memories);

  return (
    <View style={styles.wrap}>
      <ProfileHeroSection pet={pet} onEdit={onEdit} />

      <View style={styles.body}>
        <ProfileQuickStats pet={pet} weightEntries={weightEntries} />
        <ProfileActivitySummary memories={memories} checkIns={wellnessCheckIns} />

        <ProfileWeightTrackerCard pet={pet} entries={weightEntries} onPress={onWeightPress} />

        <ProfileSectionCard
          title="IDENTITY"
          rows={[
            { emoji: '🐾', label: 'Name', value: pet.name },
            { emoji: '🐕', label: 'Species', value: pet.species },
            { emoji: '⭐', label: 'Breed', value: pet.breed || '—' },
          ]}
        />

        <ProfileSectionCard
          title="KEY DATES"
          rows={[
            {
              emoji: '🎂',
              label: 'Birthday',
              value: pet.birthday ? formatProfileDate(pet.birthday) : '—',
            },
            {
              emoji: '🏠',
              label: 'Adoption Date',
              value: pet.adoption_date ? formatProfileDate(pet.adoption_date) : '—',
            },
          ]}
        />

        <ProfileSectionCard
          title="HEALTH"
          rows={[
            { emoji: '♂️', label: 'Gender', value: pet.gender ?? '—' },
            { emoji: '⚖️', label: 'Weight', value: formatDualWeight(getProfileWeightValue(weightEntries, pet)) },
            {
              emoji: '💻',
              label: 'Microchip',
              value: formatMicrochipNumber(pet.microchip_id),
            },
          ]}
        />

        <ProfileSectionCard title="BIO" rows={[]} bodyText={formatBioPlaceholder(pet)} />

        <ProfileVeterinarySection
          vetName={pet.vet_name}
          vetClinic={pet.vet_clinic}
          onSave={onVetSave}
        />

        <ProfileRecordsSection
          rows={[
            {
              label: 'Weight Log',
              detail: formatEntryCount(weightEntries.length, 'entry', 'entries'),
              onPress: onWeightPress,
            },
            {
              label: 'Saved Memories',
              detail: formatEntryCount(savedMemories, 'saved', 'saved'),
            },
            {
              label: 'Reminders',
              detail: '0 active',
            },
          ]}
        />

        <ProfileComingSoonSection petName={pet.name} />

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Edit profile"
          onPress={onEdit}
          style={({ pressed }) => [styles.editProfileButton, pressed && styles.pressed]}>
          <Ionicons name="pencil-outline" size={18} color={AuthColors.text} />
          <Text style={styles.editProfileLabel}>Edit Profile</Text>
        </Pressable>

        {onLogOut ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Log out"
            onPress={onLogOut}
            style={({ pressed }) => [styles.logOutButton, pressed && styles.pressed]}>
            <Ionicons name="log-out-outline" size={18} color={AuthColors.error} />
            <Text style={styles.logOutLabel}>Log Out</Text>
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    backgroundColor: AuthColors.emptyTimelineBackground,
  },
  body: {
    paddingHorizontal: 20,
    paddingTop: 4,
    paddingBottom: 24,
  },
  editProfileButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    minHeight: 54,
    borderRadius: 16,
    backgroundColor: AuthColors.quickAddField,
    marginBottom: 12,
  },
  editProfileLabel: {
    ...AuthTypography.button,
    fontSize: 16,
    color: AuthColors.text,
  },
  logOutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    minHeight: 52,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: AuthColors.border,
    backgroundColor: AuthColors.background,
  },
  logOutLabel: {
    ...AuthTypography.button,
    fontSize: 16,
    color: AuthColors.error,
  },
  pressed: {
    opacity: 0.88,
  },
});
