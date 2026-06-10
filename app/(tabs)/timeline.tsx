import * as ImagePicker from 'expo-image-picker';
import { useEffect, useMemo, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';

import { AppHeader } from '@/components/AppHeader';
import { EmptyState } from '@/components/EmptyState';
import { FormField } from '@/components/FormField';
import { ImageUploadPreview } from '@/components/ImageUploadPreview';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PrimaryButton } from '@/components/PrimaryButton';
import { Card } from '@/components/SafeScreen';
import { ScreenLayout } from '@/components/ScreenLayout';
import { TimelineItem } from '@/components/TimelineItem';
import { Colors, Spacing, Typography } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { database } from '@/lib/database';
import { drafts } from '@/services/drafts';
import {
  showPermissionAlert,
  showRemoteFallbackNotice,
  showSaveError,
} from '@/utils/feedback';
import { hasErrors, validateMemoryForm, type ValidationErrors } from '@/utils/validation';
import type { MemoryDraft, TimelineEntry } from '@/types';

const emptyDraft: MemoryDraft = {
  title: '',
  description: '',
};

export default function TimelineScreen() {
  const { pet, memories, loading, refresh, markRemoteSyncPending, remoteSyncPending } = usePet();
  const [snapshots, setSnapshots] = useState<
    Awaited<ReturnType<typeof database.getFutureSnapshots>>
  >([]);
  const [snapshotsLoading, setSnapshotsLoading] = useState(false);
  const [form, setForm] = useState<MemoryDraft>(emptyDraft);
  const [errors, setErrors] = useState<ValidationErrors<MemoryDraft>>({});
  const [saving, setSaving] = useState(false);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    if (pet) {
      setSnapshotsLoading(true);
      database
        .getFutureSnapshots(pet.id)
        .then(setSnapshots)
        .finally(() => setSnapshotsLoading(false));
    }
  }, [pet, memories]);

  useEffect(() => {
    drafts.getMemory().then((draft) => {
      if (draft) {
        setForm(draft);
        setShowForm(true);
      }
    });
  }, []);

  useEffect(() => {
    if (showForm) {
      drafts.saveMemory(form);
    }
  }, [form, showForm]);

  const entries = useMemo<TimelineEntry[]>(() => {
    const combined: TimelineEntry[] = [
      ...memories.map((memory) => ({ type: 'memory' as const, data: memory })),
      ...snapshots.map((snapshot) => ({ type: 'snapshot' as const, data: snapshot })),
    ];

    return combined.sort(
      (a, b) =>
        new Date(b.data.created_at).getTime() - new Date(a.data.created_at).getTime(),
    );
  }, [memories, snapshots]);

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

  async function pickPhoto() {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      showPermissionAlert('photos');
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      updateField('photo_uri', result.assets[0].uri);
    }
  }

  async function handleSaveMemory() {
    if (!pet) return;

    const nextErrors = validateMemoryForm(form);
    setErrors(nextErrors);
    if (hasErrors(nextErrors)) return;

    setSaving(true);
    try {
      const { remoteFailed } = await database.saveMemory(pet.id, {
        title: form.title.trim(),
        description: form.description.trim(),
        photo_uri: form.photo_uri,
      });

      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      setForm(emptyDraft);
      setErrors({});
      setShowForm(false);
      await drafts.clearMemory();
      await refresh();
      const updatedSnapshots = await database.getFutureSnapshots(pet.id);
      setSnapshots(updatedSnapshots);
    } catch (error) {
      showSaveError('Memory save', error);
    } finally {
      setSaving(false);
    }
  }

  if (!loading && !pet) {
    return (
      <ScreenLayout scrollable={false}>
        <EmptyState
          title="No timeline yet"
          message="Create a pet profile to start your memory timeline."
        />
      </ScreenLayout>
    );
  }

  return (
    <ScreenLayout
      loading={loading}
      loadingMessage="Loading timeline..."
      keyboardAvoiding
      scrollViewProps={{ keyboardDismissMode: 'interactive' }}>
      <OfflineBanner visible={remoteSyncPending} />

      <AppHeader
        title="Memory Timeline"
        subtitle="Chronological memories and future snapshots in one place."
      />

      {!showForm ? (
        <PrimaryButton title="Add Memory" onPress={() => setShowForm(true)} />
      ) : (
        <Card style={styles.formCard}>
          <Text style={styles.formTitle}>New Memory</Text>
          <FormField
            label="Memory title"
            required
            value={form.title}
            onChangeText={(title) => updateField('title', title)}
            placeholder="First beach day"
            error={errors.title}
          />
          <FormField
            label="Memory description"
            required
            value={form.description}
            onChangeText={(description) => updateField('description', description)}
            placeholder="What made this moment special?"
            error={errors.description}
            multiline
            style={styles.textArea}
          />
          <ImageUploadPreview
            uri={form.photo_uri}
            onPick={pickPhoto}
            onRemove={() => updateField('photo_uri', undefined)}
            aspect="wide"
            hint="Add an optional memory photo"
            pickLabel="Add Photo"
            changeLabel="Change Photo"
          />
          <View style={styles.formActions}>
            <PrimaryButton title="Save Memory" loading={saving} onPress={handleSaveMemory} />
            <PrimaryButton
              title="Cancel"
              variant="outline"
              onPress={() => {
                setShowForm(false);
                setForm(emptyDraft);
                setErrors({});
                drafts.clearMemory();
              }}
            />
          </View>
        </Card>
      )}

      <View style={styles.list}>
        {snapshotsLoading ? (
          <EmptyState emoji="⏳" title="Loading entries" message="Fetching your timeline..." />
        ) : entries.length === 0 ? (
          <EmptyState
            emoji="📖"
            title="Your timeline is empty"
            message="Add a memory or generate a future snapshot to begin."
          />
        ) : (
          entries.map((entry) => (
            <TimelineItem key={`${entry.type}-${entry.data.id}`} entry={entry} />
          ))
        )}
      </View>
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  formCard: {
    marginTop: Spacing.md,
    marginBottom: Spacing.lg,
    gap: Spacing.sm,
  },
  formTitle: {
    ...Typography.subtitle,
    color: Colors.text,
    marginBottom: Spacing.sm,
  },
  textArea: {
    minHeight: 96,
    textAlignVertical: 'top',
  },
  formActions: {
    gap: Spacing.sm,
    marginTop: Spacing.sm,
  },
  list: {
    marginTop: Spacing.lg,
  },
});
