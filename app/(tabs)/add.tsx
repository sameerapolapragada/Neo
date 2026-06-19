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

import { EmptyState } from '@/components/EmptyState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { QuickAddBoxCaption, QuickAddBoxInput, QuickAddLabeledBox } from '@/components/QuickAddLabeledBox';
import { QuickAddCategoryPicker } from '@/components/QuickAddCategoryPicker';
import { QuickAddDateRow } from '@/components/QuickAddDateRow';
import { QuickAddHeader } from '@/components/QuickAddHeader';
import { QuickAddMilestonePhotoField } from '@/components/QuickAddMilestonePhotoField';
import { QuickAddPhotoDropzone } from '@/components/QuickAddPhotoDropzone';
import { QuickAddSaveButton } from '@/components/QuickAddSaveButton';
import { QuickAddSentimentPicker } from '@/components/QuickAddSentimentPicker';
import { QuickAddSuggestedMilestones } from '@/components/QuickAddSuggestedMilestones';
import { QuickAddTypeToggle } from '@/components/QuickAddTypeToggle';
import { SafeScreen } from '@/components/SafeScreen';
import {
  CAPTION_MAX_LENGTH,
  NOTES_MAX_LENGTH,
} from '@/constants/memoryForm';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { drafts } from '@/services/drafts';
import {
  showPermissionAlert,
  showRemoteFallbackNotice,
  showSaveError,
} from '@/utils/feedback';
import {
  formatQuickAddDate,
  parseMemoryDate,
  toMemoryDateIso,
} from '@/utils/memoryDate';
import { hasErrors, validateMemoryForm, type ValidationErrors } from '@/utils/validation';
import type { MemoryCategory, MemoryDraft, MemoryEntryType } from '@/types';

function createEmptyDraft(entryType: MemoryEntryType = 'memory'): MemoryDraft {
  return {
    entry_type: entryType,
    category: 'Memory',
    title: '',
    description: '',
    photo_uris: [],
    memory_date: toMemoryDateIso(new Date()),
  };
}

function normalizeDraft(draft: Partial<MemoryDraft> & { photo_uri?: string }): MemoryDraft {
  const empty = createEmptyDraft(draft.entry_type ?? 'memory');

  return {
    entry_type: draft.entry_type ?? empty.entry_type,
    category: draft.category ?? empty.category,
    title: draft.title ?? empty.title,
    description: draft.description ?? empty.description,
    photo_uris:
      draft.photo_uris ?? (draft.photo_uri ? [draft.photo_uri] : empty.photo_uris),
    memory_date: draft.memory_date ?? empty.memory_date,
    sentiment: draft.sentiment,
  };
}

function mapSuggestedToCategory(label: string): MemoryCategory {
  switch (label) {
    case 'Birthday':
      return 'Birthday';
    case 'Special Moment':
      return 'Favorite Thing';
    default:
      return 'Memory';
  }
}

export default function AddTabScreen() {
  const { pet, refresh, markRemoteSyncPending, remoteSyncPending } = usePet();
  const { horizontalPadding } = useResponsive();
  const [form, setForm] = useState<MemoryDraft>(createEmptyDraft());
  const [errors, setErrors] = useState<ValidationErrors<MemoryDraft>>({});
  const [saving, setSaving] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);

  useEffect(() => {
    drafts.getMemory().then((draft) => {
      if (draft) {
        setForm(normalizeDraft(draft));
      }
    });
  }, []);

  useEffect(() => {
    drafts.saveMemory(form);
  }, [form]);

  function updateField<K extends keyof MemoryDraft>(key: K, value: MemoryDraft[K]) {
    setForm((current) => ({ ...current, [key]: value }));
    if (errors[key]) {
      setErrors((current) => {
        const next = { ...current };
        delete next[key];
        return next;
      });
    }
  }

  function handleTypeChange(entryType: MemoryEntryType) {
    setForm((current) => ({
      ...createEmptyDraft(entryType),
      title: current.title,
      description: current.description,
      photo_uris: current.photo_uris,
      memory_date: current.memory_date,
      category: entryType === 'milestone' ? 'Memory' : current.category,
    }));
    setErrors({});
  }

  function handleSuggestedMilestone(title: string, label: string) {
    updateField('title', title);
    updateField('category', mapSuggestedToCategory(label));
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
      aspect: form.entry_type === 'milestone' ? [1, 1] : [4, 3],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      updateField('photo_uris', [result.assets[0].uri]);
    }
  }

  function handleDateChange(event: DateTimePickerEvent, selectedDate?: Date) {
    if (Platform.OS === 'android') {
      setShowDatePicker(false);
    }

    if (event.type === 'dismissed' || !selectedDate) return;
    updateField('memory_date', toMemoryDateIso(selectedDate));
  }

  async function handleSave() {
    if (!pet) return;

    const nextErrors = validateMemoryForm(form);
    setErrors(nextErrors);
    if (hasErrors(nextErrors)) return;

    setSaving(true);
    try {
      const { remoteFailed } = await database.saveMemory(pet.id, {
        title: form.title.trim(),
        description: form.description.trim(),
        photo_uri: form.photo_uris[0],
        entry_type: form.entry_type,
        category: form.category,
        sentiment: form.sentiment,
        created_at: form.memory_date,
      });

      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      await drafts.clearMemory();
      setForm(createEmptyDraft(form.entry_type));
      await refresh();
      router.replace('/(tabs)');
    } catch (error) {
      showSaveError('Memory save', error);
    } finally {
      setSaving(false);
    }
  }

  if (!pet) {
    return (
      <SafeScreen style={styles.screen}>
        <EmptyState
          title="Add a pet first"
          message="Create a pet profile before saving memories."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </SafeScreen>
    );
  }

  const selectedDate = parseMemoryDate(form.memory_date);
  const isMilestone = form.entry_type === 'milestone';
  const saveLabel = isMilestone ? 'Save Milestone' : 'Save Memory';

  return (
    <SafeScreen style={styles.screen} edges={['top']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView
          contentContainerStyle={[styles.content, { paddingHorizontal: horizontalPadding }]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}>
          <OfflineBanner visible={remoteSyncPending} />

          <QuickAddTypeToggle value={form.entry_type} onChange={handleTypeChange} />

          <QuickAddHeader
            entryType={form.entry_type}
            category={form.category}
            title={form.title}
          />

          {isMilestone ? (
            <>
              <QuickAddSuggestedMilestones
                variant="quickAdd"
                selectedTitle={form.title}
                onSelect={handleSuggestedMilestone}
              />

              <QuickAddLabeledBox label="MILESTONE TITLE" error={errors.title}>
                <QuickAddBoxInput
                  value={form.title}
                  onChangeText={(title) => updateField('title', title)}
                  placeholder="Name this milestone..."
                  autoCapitalize="words"
                />
              </QuickAddLabeledBox>

              <QuickAddDateRow
                value={formatQuickAddDate(form.memory_date)}
                onPress={() => setShowDatePicker(true)}
              />

              <QuickAddLabeledBox label="NOTES" error={errors.description}>
                <QuickAddBoxCaption
                  value={form.description}
                  maxLength={NOTES_MAX_LENGTH}
                  onChangeText={(description) => updateField('description', description)}
                  placeholder="Tell the story behind this milestone — what happened, how it felt, what you want to remember..."
                />
              </QuickAddLabeledBox>

              <QuickAddMilestonePhotoField photoUri={form.photo_uris[0]} onPress={pickPhoto} />

              <QuickAddSentimentPicker
                variant="quickAdd"
                value={form.sentiment}
                onChange={(sentiment) => updateField('sentiment', sentiment)}
              />
            </>
          ) : (
            <>
              <QuickAddPhotoDropzone photoUri={form.photo_uris[0]} onPick={pickPhoto} />

              <QuickAddLabeledBox label="MEMORY TITLE" error={errors.title}>
                <QuickAddBoxInput
                  value={form.title}
                  onChangeText={(title) => updateField('title', title)}
                  placeholder="Give this moment a name..."
                  autoCapitalize="words"
                />
              </QuickAddLabeledBox>

              <QuickAddLabeledBox label="CAPTION" error={errors.description}>
                <QuickAddBoxCaption
                  value={form.description}
                  maxLength={CAPTION_MAX_LENGTH}
                  onChangeText={(description) => updateField('description', description)}
                  placeholder="What made this moment special? Write as much or as little as you'd like..."
                />
              </QuickAddLabeledBox>

              <QuickAddDateRow
                value={formatQuickAddDate(form.memory_date)}
                onPress={() => setShowDatePicker(true)}
              />

              <QuickAddCategoryPicker
                variant="quickAdd"
                value={form.category}
                onChange={(category) => updateField('category', category)}
              />
            </>
          )}

          <QuickAddSaveButton
            label={saveLabel}
            loading={saving}
            onPress={handleSave}
            variant="quickAdd"
          />
        </ScrollView>
      </KeyboardAvoidingView>

      {showDatePicker ? (
        Platform.OS === 'ios' ? (
          <Modal transparent animationType="slide" visible>
            <Pressable style={styles.modalBackdrop} onPress={() => setShowDatePicker(false)} />
            <View style={styles.modalSheet}>
              <View style={styles.modalHeader}>
                <Pressable onPress={() => setShowDatePicker(false)}>
                  <Text style={styles.modalAction}>Done</Text>
                </Pressable>
              </View>
              <DateTimePicker
                value={selectedDate}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                onChange={handleDateChange}
              />
            </View>
          </Modal>
        ) : (
          <DateTimePicker
            value={selectedDate}
            mode="date"
            display="default"
            maximumDate={new Date()}
            onChange={handleDateChange}
          />
        )
      ) : null}
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.quickAddBackground,
  },
  flex: {
    flex: 1,
  },
  content: {
    paddingTop: Spacing.sm,
    paddingBottom: Platform.OS === 'ios' ? 130 : 110,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(45, 38, 64, 0.35)',
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
    color: AuthColors.onboardingPrimary,
    fontSize: 16,
  },
});
