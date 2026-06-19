import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { formatShortAge, getProfileWeightValue } from '@/utils/profileStats';
import type { Pet, WeightEntry } from '@/types';

const DEFAULT_PHOTO = require('@/assets/images/pet-profile-default.jpg');

interface LifeProfilePanelProps {
  pet: Pet;
  weightEntries?: WeightEntry[];
}

export function LifeProfilePanel({ pet, weightEntries = [] }: LifeProfilePanelProps) {
  const weight = getProfileWeightValue(weightEntries, pet);
  const ageAndWeight = `${formatShortAge(pet)} • ${weight}`;

  return (
    <View style={styles.wrap}>
      <View style={styles.panel}>
        <View style={styles.identity}>
          {pet.photo_uri ? (
            <Image source={{ uri: pet.photo_uri }} style={styles.photo} contentFit="cover" />
          ) : (
            <Image source={DEFAULT_PHOTO} style={styles.photo} contentFit="cover" />
          )}

          <View style={styles.info}>
            <Text style={styles.name}>{pet.name}</Text>
            <Text style={styles.breed}>{pet.breed}</Text>
            <Text style={styles.meta}>{ageAndWeight}</Text>
          </View>
        </View>
      </View>

      <View style={styles.divider} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 20,
  },
  panel: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  identity: {
    flexDirection: 'row',
    flex: 1,
    alignItems: 'center',
    gap: 14,
    minWidth: 0,
  },
  photo: {
    width: 76,
    height: 76,
    borderRadius: 38,
    backgroundColor: AuthColors.surface,
  },
  info: {
    flex: 1,
    justifyContent: 'center',
    gap: 2,
    minWidth: 0,
  },
  name: {
    ...AuthTypography.heading4,
    color: AuthColors.text,
  },
  breed: {
    ...AuthTypography.body,
    fontSize: 14,
    lineHeight: 20,
    color: AuthColors.onboardingTextMuted,
  },
  meta: {
    ...AuthTypography.body,
    fontSize: 14,
    lineHeight: 20,
    color: AuthColors.onboardingTextMuted,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.profileFieldBorder,
    marginTop: 20,
  },
});
