import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';

import { AppHeader } from '@/components/AppHeader';
import { FormField } from '@/components/FormField';
import { FormPicker } from '@/components/FormPicker';
import { ImageUploadPreview } from '@/components/ImageUploadPreview';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PrimaryButton } from '@/components/PrimaryButton';
import { ScreenLayout } from '@/components/ScreenLayout';
import { SPECIES_OPTIONS } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { database } from '@/lib/database';
import { drafts } from '@/services/drafts';
import { showPermissionAlert, showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import { hasErrors, validatePetProfile, type ValidationErrors } from '@/utils/validation';
import type { PetProfileDraft, Species } from '@/types';

const emptyDraft: PetProfileDraft = {
  name: '',
  species: 'Dog',
  breed: '',
  age: '',
  weight: '',
};

export default function PetProfileScreen() {
  const { pet, refresh, markRemoteSyncPending } = usePet();
  const [form, setForm] = useState<PetProfileDraft>(emptyDraft);
  const [errors, setErrors] = useState<ValidationErrors<PetProfileDraft>>({});
  const [saving, setSaving] = useState(false);
  const [showOfflineNotice, setShowOfflineNotice] = useState(false);

  useEffect(() => {
    async function loadDraft() {
      if (pet) {
        setForm({
          name: pet.name,
          species: pet.species,
          breed: pet.breed,
          age: pet.age,
          weight: pet.weight ?? '',
          photo_uri: pet.photo_uri,
        });
        return;
      }

      const draft = await drafts.getPetProfile();
      if (draft) setForm(draft);
    }

    loadDraft();
  }, [pet]);

  useEffect(() => {
    drafts.savePetProfile(form);
  }, [form]);

  function updateField<K extends keyof PetProfileDraft>(key: K, value: PetProfileDraft[K]) {
    setForm((current) => ({ ...current, [key]: value }));
    if (errors[key]) {
      setErrors((current) => {
        const next = { ...current };
        delete next[key];
        return next;
      });
    }
  }

  async function pickPhoto() {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      showPermissionAlert('photos');
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      updateField('photo_uri', result.assets[0].uri);
    }
  }

  async function handleSave() {
    const nextErrors = validatePetProfile(form);
    setErrors(nextErrors);
    if (hasErrors(nextErrors)) return;

    setSaving(true);
    try {
      const { remoteFailed } = await database.savePet({
        id: pet?.id,
        name: form.name.trim(),
        species: form.species,
        breed: form.breed.trim(),
        age: form.age.trim(),
        weight: form.weight.trim() || undefined,
        photo_uri: form.photo_uri,
      });

      await drafts.clearPetProfile();
      markRemoteSyncPending(remoteFailed);
      setShowOfflineNotice(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      await refresh();
      router.replace('/(tabs)');
    } catch (error) {
      showSaveError('Save', error);
    } finally {
      setSaving(false);
    }
  }

  return (
    <ScreenLayout keyboardAvoiding scrollViewProps={{ keyboardDismissMode: 'interactive' }}>
      <OfflineBanner visible={showOfflineNotice} />

      <AppHeader
        title="Pet Profile"
        subtitle="Tell us about your companion so Neo can personalize lifestyle snapshots."
        showDisclaimer
      />

      <ImageUploadPreview
        uri={form.photo_uri}
        onPick={pickPhoto}
        onRemove={() => updateField('photo_uri', undefined)}
        hint="Tap to add a pet photo"
      />

      <FormField
        label="Pet name"
        required
        value={form.name}
        onChangeText={(name) => updateField('name', name)}
        placeholder="Luna"
        error={errors.name}
        autoCapitalize="words"
        returnKeyType="next"
      />

      <FormPicker
        label="Species"
        value={form.species}
        options={SPECIES_OPTIONS}
        onValueChange={(species: Species) => updateField('species', species)}
      />

      <FormField
        label="Breed"
        required
        value={form.breed}
        onChangeText={(breed) => updateField('breed', breed)}
        placeholder="Golden Retriever"
        error={errors.breed}
        autoCapitalize="words"
      />

      <FormField
        label="Age"
        required
        value={form.age}
        onChangeText={(age) => updateField('age', age)}
        placeholder="3 years"
        error={errors.age}
      />

      <FormField
        label="Weight (optional)"
        value={form.weight}
        onChangeText={(weight) => updateField('weight', weight)}
        placeholder="25 lbs"
        error={errors.weight}
      />

      <PrimaryButton title="Save Pet Profile" loading={saving} onPress={handleSave} />
    </ScreenLayout>
  );
}