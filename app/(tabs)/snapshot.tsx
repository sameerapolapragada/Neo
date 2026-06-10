import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';

import { AppHeader } from '@/components/AppHeader';
import { EmptyState } from '@/components/EmptyState';
import { FormField } from '@/components/FormField';
import { FormPicker } from '@/components/FormPicker';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PrimaryButton } from '@/components/PrimaryButton';
import { ScreenLayout } from '@/components/ScreenLayout';
import { SnapshotCard } from '@/components/SnapshotCard';
import { FREQUENCY_OPTIONS, Colors, Spacing, Typography } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { database } from '@/lib/database';
import { generateFutureSnapshot } from '@/services/ai';
import { drafts } from '@/services/drafts';
import { showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import { hasErrors, validateSnapshotForm, type ValidationErrors } from '@/utils/validation';
import type { FutureSnapshot, SnapshotDraft } from '@/types';

const emptyDraft: SnapshotDraft = {
  play_frequency: 'Weekly',
  new_environments: 'Weekly',
  enrichment: 'Weekly',
  socialization: 'Weekly',
  favorite_activities: '',
};

export default function SnapshotScreen() {
  const { pet, refresh, markRemoteSyncPending, remoteSyncPending } = usePet();
  const [form, setForm] = useState<SnapshotDraft>(emptyDraft);
  const [errors, setErrors] = useState<ValidationErrors<SnapshotDraft>>({});
  const [result, setResult] = useState<FutureSnapshot | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    drafts.getSnapshot().then((draft) => {
      if (draft) setForm(draft);
    });
  }, []);

  useEffect(() => {
    drafts.saveSnapshot(form);
  }, [form]);

  function updateField<K extends keyof SnapshotDraft>(key: K, value: SnapshotDraft[K]) {
    setForm((current) => ({ ...current, [key]: value }));
    if (errors[key]) {
      setErrors((current) => {
        const next = { ...current };
        delete next[key];
        return next;
      });
    }
  }

  async function handleSubmit() {
    if (!pet) return;

    const nextErrors = validateSnapshotForm(form);
    setErrors(nextErrors);
    if (hasErrors(nextErrors)) return;

    setLoading(true);
    try {
      const { answers, remoteFailed: answersFailed } = await database.saveLifestyleAnswers(
        pet.id,
        {
          ...form,
          favorite_activities: form.favorite_activities.trim(),
        },
      );
      const content = await generateFutureSnapshot(pet, answers);
      const { snapshot, remoteFailed: snapshotFailed } = await database.saveFutureSnapshot(
        pet.id,
        answers.id,
        content,
      );

      const remoteFailed = answersFailed || snapshotFailed;
      markRemoteSyncPending(remoteFailed);
      showRemoteFallbackNotice(remoteFailed);
      setResult(snapshot);
      await drafts.clearSnapshot();
      await refresh();
    } catch (error) {
      showSaveError('Snapshot generation', error);
    } finally {
      setLoading(false);
    }
  }

  if (!pet) {
    return (
      <ScreenLayout scrollable={false}>
        <EmptyState
          title="Add a pet first"
          message="Create a pet profile before generating a future snapshot."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </ScreenLayout>
    );
  }

  return (
    <ScreenLayout keyboardAvoiding scrollViewProps={{ keyboardDismissMode: 'interactive' }}>
      <OfflineBanner visible={remoteSyncPending} />

      <AppHeader
        title="Future Snapshot"
        subtitle="Answer a few lifestyle questions to imagine your pet's story over time."
        showDisclaimer
      />

      <FormPicker
        label="How often do you play together?"
        value={form.play_frequency}
        options={FREQUENCY_OPTIONS}
        onValueChange={(play_frequency) => updateField('play_frequency', play_frequency)}
      />
      <FormPicker
        label="How often does your pet experience new environments?"
        value={form.new_environments}
        options={FREQUENCY_OPTIONS}
        onValueChange={(new_environments) => updateField('new_environments', new_environments)}
      />
      <FormPicker
        label="How often do you do enrichment, puzzles, or training?"
        value={form.enrichment}
        options={FREQUENCY_OPTIONS}
        onValueChange={(enrichment) => updateField('enrichment', enrichment)}
      />
      <FormPicker
        label="How often does your pet socialize?"
        value={form.socialization}
        options={FREQUENCY_OPTIONS}
        onValueChange={(socialization) => updateField('socialization', socialization)}
      />

      <FormField
        label="What are your pet's favorite activities?"
        required
        value={form.favorite_activities}
        onChangeText={(favorite_activities) => updateField('favorite_activities', favorite_activities)}
        placeholder="Fetch, park walks, snuggle time..."
        error={errors.favorite_activities}
        multiline
        style={styles.textArea}
      />

      <PrimaryButton title="Generate Snapshot" loading={loading} onPress={handleSubmit} />

      {result ? (
        <View style={styles.results}>
          <Text style={styles.resultsTitle}>Your Future Snapshot</Text>
          <SnapshotCard label="Today" content={result.today} />
          <SnapshotCard label="6 Months From Now" content={result.six_months} />
          <SnapshotCard label="2 Years From Now" content={result.two_years} />
          <SnapshotCard label="5 Years From Now" content={result.five_years} />
        </View>
      ) : (
        <View style={styles.results}>
          <EmptyState
            emoji="🔮"
            title="Ready when you are"
            message="Fill out the questions above and tap Generate Snapshot to see your pet's lifestyle story."
          />
        </View>
      )}
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  textArea: {
    minHeight: 96,
    textAlignVertical: 'top',
  },
  results: {
    marginTop: Spacing.xl,
  },
  resultsTitle: {
    ...Typography.subtitle,
    color: Colors.text,
    marginBottom: Spacing.md,
  },
});
