import DateTimePicker, { DateTimePickerEvent } from '@react-native-community/datetimepicker';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { OfflineBanner } from '@/components/OfflineBanner';
import {
  PetProfileCalendarTrailing,
  PetProfileChevron,
  PetProfileFieldCard,
  PetProfileTextInput,
  PetProfileValueText,
  PetProfileWeightSuffix,
} from '@/components/PetProfileFieldCard';
import { PetProfilePhotoPicker } from '@/components/PetProfilePhotoPicker';
import { PetProfileSaveButton } from '@/components/PetProfileSaveButton';
import {
  PetProfileCardHeader,
  PetProfileEditHeader,
  PetProfileFlowBadge,
} from '@/components/PetProfileStepHeader';
import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors, AuthShadow, AuthTypography } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { drafts } from '@/services/drafts';
import { showPermissionAlert, showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import {
  computeAgeFromBirthday,
  formatProfileDateShort,
  formatWeight,
  parseWeight,
  parseWeightUnit,
  toProfileDateIso,
} from '@/utils/petProfile';
import { hasErrors, validatePetProfile, type ValidationErrors } from '@/utils/validation';
import type { Pet, PetGender, PetProfileDraft, Species, WeightUnit } from '@/types';

type DateField = 'birthday' | 'adoption_date';

const SPECIES_OPTIONS: Species[] = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Guinea Pig', 'Other'];
const GENDER_OPTIONS: PetGender[] = ['Male', 'Female', 'Neutered', 'Spayed', 'Unknown'];

function createEmptyDraft(): PetProfileDraft {
  return {
    name: '',
    species: 'Dog',
    breed: '',
    birthday: '',
    gender: 'Male',
    adoption_date: '',
    weightValue: '',
    weightUnit: 'lbs',
    microchip_id: '',
  };
}

function toDraft(pet: Pet): PetProfileDraft {
  return {
    name: pet.name,
    species: pet.species,
    breed: pet.breed,
    birthday: pet.birthday ?? '',
    gender: pet.gender ?? 'Unknown',
    adoption_date: pet.adoption_date ?? '',
    weightValue: pet.weight ? parseWeight(pet.weight) : '',
    weightUnit: parseWeightUnit(pet.weight),
    microchip_id: pet.microchip_id ?? '',
    photo_uri: pet.photo_uri,
  };
}

function normalizeDraft(draft: Partial<PetProfileDraft> & Record<string, unknown>): PetProfileDraft {
  const empty = createEmptyDraft();

  if ('birthday' in draft || !('ageValue' in draft)) {
    return {
      name: String(draft.name ?? empty.name),
      species: (draft.species as Species) ?? empty.species,
      breed: String(draft.breed ?? empty.breed),
      birthday: String(draft.birthday ?? empty.birthday),
      gender: (draft.gender as PetGender) ?? empty.gender,
      adoption_date: String(draft.adoption_date ?? empty.adoption_date),
      weightValue: String(draft.weightValue ?? empty.weightValue),
      weightUnit: (draft.weightUnit as WeightUnit) ?? empty.weightUnit,
      microchip_id: String(draft.microchip_id ?? empty.microchip_id),
      photo_uri: draft.photo_uri as string | undefined,
    };
  }

  return empty;
}

function parseProfileDate(iso?: string): Date {
  if (!iso) return new Date();
  const parsed = new Date(iso);
  return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
}

interface PickerModalProps<T extends string> {
  visible: boolean;
  title: string;
  options: T[];
  selected: T;
  onSelect: (value: T) => void;
  onClose: () => void;
}

function PickerModal<T extends string>({
  visible,
  title,
  options,
  selected,
  onSelect,
  onClose,
}: PickerModalProps<T>) {
  return (
    <Modal transparent visible={visible} animationType="fade">
      <Pressable style={styles.modalBackdrop} onPress={onClose} />
      <View style={styles.pickerModal}>
        <Text style={styles.pickerTitle}>{title}</Text>
        {options.map((option) => {
          const isSelected = option === selected;

          return (
            <Pressable
              key={option}
              accessibilityRole="button"
              accessibilityState={{ selected: isSelected }}
              onPress={() => {
                onSelect(option);
                onClose();
              }}
              style={({ pressed }) => [
                styles.pickerOption,
                isSelected && styles.pickerOptionSelected,
                pressed && styles.pressed,
              ]}>
              <Text style={[styles.pickerOptionText, isSelected && styles.pickerOptionTextSelected]}>
                {option}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </Modal>
  );
}

export default function PetProfileScreen() {
  const { pet, refresh, markRemoteSyncPending } = usePet();
  const { horizontalPadding } = useResponsive();
  const [form, setForm] = useState<PetProfileDraft>(createEmptyDraft());
  const [errors, setErrors] = useState<ValidationErrors<PetProfileDraft>>({});
  const [saving, setSaving] = useState(false);
  const [showOfflineNotice, setShowOfflineNotice] = useState(false);
  const [activeDateField, setActiveDateField] = useState<DateField | null>(null);
  const [showSpeciesModal, setShowSpeciesModal] = useState(false);
  const [showGenderModal, setShowGenderModal] = useState(false);
  const [showBreedModal, setShowBreedModal] = useState(false);
  const [breedDraft, setBreedDraft] = useState('');

  const cardPadding = Math.max(horizontalPadding, 20);

  useEffect(() => {
    async function loadDraft() {
      if (pet) {
        setForm(toDraft(pet));
        return;
      }

      const draft = await drafts.getPetProfile();
      if (draft) {
        setForm(normalizeDraft(draft as Partial<PetProfileDraft> & Record<string, unknown>));
      }
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

  function handleDateChange(event: DateTimePickerEvent, selectedDate?: Date) {
    if (Platform.OS === 'android') {
      setActiveDateField(null);
    }

    if (event.type === 'dismissed' || !selectedDate || !activeDateField) return;
    updateField(activeDateField, toProfileDateIso(selectedDate));
  }

  function openBreedModal() {
    setBreedDraft(form.breed);
    setShowBreedModal(true);
  }

  function saveBreed() {
    updateField('breed', breedDraft.trim());
    setShowBreedModal(false);
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
        age: computeAgeFromBirthday(form.birthday),
        weight: formatWeight(form.weightValue, form.weightUnit),
        photo_uri: form.photo_uri,
        birthday: form.birthday,
        gender: form.gender,
        adoption_date: form.adoption_date,
        microchip_id: form.microchip_id.trim() || undefined,
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

  const activeDateValue = activeDateField ? form[activeDateField] : '';

  const isCreateFlow = !pet;

  return (
    <SafeScreen style={styles.screen} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView
          contentContainerStyle={[styles.scrollContent, { paddingHorizontal: cardPadding }]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}>
          <OfflineBanner visible={showOfflineNotice} />

          {isCreateFlow ? <PetProfileFlowBadge /> : <PetProfileEditHeader onBack={() => router.back()} />}

          <View style={styles.card}>
            <PetProfileCardHeader
              title={isCreateFlow ? 'Create Your Pet Profile' : 'Edit Your Pet Profile'}
              subtitle={
                isCreateFlow
                  ? 'Tell us about your furry friend'
                  : 'Update your pet\u2019s details'
              }
            />

            <PetProfilePhotoPicker uri={form.photo_uri} onPick={pickPhoto} />

            <View style={styles.form}>
              <PetProfileFieldCard label="Pet Name" error={errors.name}>
                <PetProfileTextInput
                  value={form.name}
                  onChangeText={(name) => updateField('name', name)}
                  placeholder="Buddy"
                  autoCapitalize="words"
                />
              </PetProfileFieldCard>

              <PetProfileFieldCard
                label="Species"
                onPress={() => setShowSpeciesModal(true)}
                trailing={<PetProfileChevron />}>
                <PetProfileValueText value={form.species} />
              </PetProfileFieldCard>

              <PetProfileFieldCard
                label="Breed"
                error={errors.breed}
                onPress={openBreedModal}
                trailing={<PetProfileChevron />}>
                <PetProfileValueText value={form.breed || 'Select breed'} muted={!form.breed} />
              </PetProfileFieldCard>

              <PetProfileFieldCard
                label="Birth Date"
                error={errors.birthday}
                onPress={() => setActiveDateField('birthday')}
                trailing={<PetProfileCalendarTrailing />}>
                <PetProfileValueText
                  value={formatProfileDateShort(form.birthday)}
                  muted={!form.birthday}
                />
              </PetProfileFieldCard>

              <PetProfileFieldCard
                label="Gender"
                onPress={() => setShowGenderModal(true)}
                trailing={<PetProfileChevron />}>
                <PetProfileValueText value={form.gender} />
              </PetProfileFieldCard>

              <PetProfileFieldCard
                label="Adoption Date"
                error={errors.adoption_date}
                onPress={() => setActiveDateField('adoption_date')}
                trailing={<PetProfileCalendarTrailing />}>
                <PetProfileValueText
                  value={formatProfileDateShort(form.adoption_date)}
                  muted={!form.adoption_date}
                />
              </PetProfileFieldCard>

              <PetProfileFieldCard
                label="Current Weight"
                error={errors.weightValue}
                trailing={<PetProfileWeightSuffix unit={form.weightUnit} />}>
                <PetProfileTextInput
                  value={form.weightValue}
                  onChangeText={(weightValue) => updateField('weightValue', weightValue)}
                  placeholder="42"
                  keyboardType="decimal-pad"
                />
              </PetProfileFieldCard>

              <PetProfileFieldCard label="Microchip Number (Optional)">
                <PetProfileTextInput
                  value={form.microchip_id}
                  onChangeText={(microchip_id) => updateField('microchip_id', microchip_id)}
                  placeholder="985 113 002 123 456"
                  autoCapitalize="characters"
                />
              </PetProfileFieldCard>
            </View>

            <PetProfileSaveButton loading={saving} onPress={handleSave} />
          </View>
        </ScrollView>
      </KeyboardAvoidingView>

      {activeDateField ? (
        Platform.OS === 'ios' ? (
          <Modal transparent animationType="slide" visible>
            <Pressable style={styles.modalBackdrop} onPress={() => setActiveDateField(null)} />
            <View style={styles.modalSheet}>
              <View style={styles.modalHeader}>
                <Pressable onPress={() => setActiveDateField(null)}>
                  <Text style={styles.modalAction}>Done</Text>
                </Pressable>
              </View>
              <DateTimePicker
                value={parseProfileDate(activeDateValue)}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                onChange={handleDateChange}
              />
            </View>
          </Modal>
        ) : (
          <DateTimePicker
            value={parseProfileDate(activeDateValue)}
            mode="date"
            display="default"
            maximumDate={new Date()}
            onChange={handleDateChange}
          />
        )
      ) : null}

      <PickerModal
        visible={showSpeciesModal}
        title="Select species"
        options={SPECIES_OPTIONS}
        selected={form.species}
        onSelect={(species) => updateField('species', species)}
        onClose={() => setShowSpeciesModal(false)}
      />

      <PickerModal
        visible={showGenderModal}
        title="Select gender"
        options={GENDER_OPTIONS}
        selected={form.gender}
        onSelect={(gender) => updateField('gender', gender)}
        onClose={() => setShowGenderModal(false)}
      />

      <Modal transparent visible={showBreedModal} animationType="fade">
        <Pressable style={styles.modalBackdrop} onPress={() => setShowBreedModal(false)} />
        <View style={styles.pickerModal}>
          <Text style={styles.pickerTitle}>Select breed</Text>
          <PetProfileTextInput
            value={breedDraft}
            onChangeText={setBreedDraft}
            placeholder="Golden Retriever"
            autoCapitalize="words"
            autoFocus
          />
          <Pressable
            accessibilityRole="button"
            onPress={saveBreed}
            style={({ pressed }) => [styles.breedDone, pressed && styles.pressed]}>
            <Text style={styles.breedDoneText}>Done</Text>
          </Pressable>
        </View>
      </Modal>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.profileBackground,
  },
  flex: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingVertical: Spacing.lg,
  },
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 20,
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 28,
    ...AuthShadow.card,
  },
  form: {
    marginTop: 0,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(46, 58, 63, 0.35)',
  },
  modalSheet: {
    backgroundColor: AuthColors.card,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingBottom: 24,
  },
  modalHeader: {
    alignItems: 'flex-end',
    paddingHorizontal: 20,
    paddingTop: 12,
  },
  modalAction: {
    ...AuthTypography.label,
    color: AuthColors.primaryDark,
    fontSize: 16,
  },
  pickerModal: {
    position: 'absolute',
    left: 24,
    right: 24,
    top: '28%',
    backgroundColor: AuthColors.card,
    borderRadius: 20,
    padding: 20,
    gap: 8,
    borderWidth: 1,
    borderColor: AuthColors.border,
  },
  pickerTitle: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
    marginBottom: 8,
  },
  pickerOption: {
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
  pickerOptionSelected: {
    backgroundColor: AuthColors.primarySoft,
  },
  pickerOptionText: {
    ...AuthTypography.body,
    color: AuthColors.text,
  },
  pickerOptionTextSelected: {
    fontWeight: '700',
    color: AuthColors.primaryDark,
  },
  breedDone: {
    alignSelf: 'flex-end',
    paddingVertical: 8,
    paddingHorizontal: 4,
    marginTop: 8,
  },
  breedDoneText: {
    ...AuthTypography.label,
    color: AuthColors.primaryDark,
    fontSize: 16,
  },
  pressed: {
    opacity: 0.88,
  },
});
