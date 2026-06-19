import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { EmptyState } from '@/components/EmptyState';
import { OfflineBanner } from '@/components/OfflineBanner';
import { PrimaryButton } from '@/components/PrimaryButton';
import { ProfileScreenHeader } from '@/components/ProfileScreenHeader';
import { SafeScreen } from '@/components/SafeScreen';
import { SnapshotCard } from '@/components/SnapshotCard';
import { SnapshotResultsHeader } from '@/components/SnapshotResultsHeader';
import { SnapshotOptionButton, SnapshotProgressBar } from '@/components/SnapshotWizardUI';
import {
  SNAPSHOT_FREQUENCY_OPTIONS,
  SNAPSHOT_STEPS,
  fromStoredSnapshotDraft,
  toStoredSnapshotDraft,
} from '@/constants/snapshotQuestions';
import { Colors, Radius, Spacing, Typography } from '@/constants/theme';
import { usePet } from '@/context/PetContext';
import { useResponsive } from '@/hooks/useResponsive';
import { database } from '@/lib/database';
import { generateFutureSnapshot } from '@/services/ai';
import { drafts } from '@/services/drafts';
import { showRemoteFallbackNotice, showSaveError } from '@/utils/feedback';
import type { FutureSnapshot, SnapshotDraft } from '@/types';

const emptyDraft: SnapshotDraft = {
  play_frequency: 'Every day',
  new_environments: 'Every day',
  enrichment: 'Every day',
  socialization: 'Every day',
  favorite_activities: '',
};

export default function SnapshotScreen() {
  const { restart } = useLocalSearchParams<{ restart?: string }>();
  const { pet, refresh, markRemoteSyncPending, remoteSyncPending } = usePet();
  const { horizontalPadding } = useResponsive();
  const [form, setForm] = useState<SnapshotDraft>(emptyDraft);
  const [stepIndex, setStepIndex] = useState(0);
  const [phase, setPhase] = useState<'wizard' | 'results'>('wizard');
  const [result, setResult] = useState<FutureSnapshot | null>(null);
  const [loading, setLoading] = useState(false);
  const [textError, setTextError] = useState('');

  const currentStep = SNAPSHOT_STEPS[stepIndex];
  const isLastStep = stepIndex === SNAPSHOT_STEPS.length - 1;

  useEffect(() => {
    if (restart === '1') {
      setPhase('wizard');
      setStepIndex(0);
      setResult(null);
      setForm(emptyDraft);
      drafts.clearSnapshot();
      return;
    }

    drafts.getSnapshot().then((draft) => {
      if (draft) setForm(fromStoredSnapshotDraft(draft));
    });
  }, [restart]);

  useEffect(() => {
    drafts.saveSnapshot(toStoredSnapshotDraft(form));
  }, [form]);

  function updateChoice(key: keyof SnapshotDraft, value: string) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleShareSnapshot() {
    if (!result || !pet) return;

    const message = [
      `Your Future Snapshot for ${pet.name}`,
      '',
      'Today',
      result.today,
      '',
      '6 Months From Now',
      result.six_months,
      '',
      '2 Years From Now',
      result.two_years,
      '',
      '5 Years From Now',
      result.five_years,
    ].join('\n');

    await Share.share({ message, title: `Future Snapshot — ${pet.name}` });
  }

  function handleBack() {
    if (phase === 'results') {
      router.push('/(tabs)');
      return;
    }

    if (stepIndex > 0) {
      setStepIndex((current) => current - 1);
      return;
    }

    router.back();
  }

  function handleNext() {
    if (currentStep.type === 'text') {
      if (!form.favorite_activities.trim()) {
        setTextError('Tell us about a favorite activity');
        return;
      }
      setTextError('');
      handleSubmit();
      return;
    }

    if (stepIndex < SNAPSHOT_STEPS.length - 1) {
      setStepIndex((current) => current + 1);
    }
  }

  async function handleSubmit() {
    if (!pet) return;

    setLoading(true);
    try {
      const stored = toStoredSnapshotDraft(form);
      const { answers, remoteFailed: answersFailed } = await database.saveLifestyleAnswers(
        pet.id,
        {
          ...stored,
          favorite_activities: stored.favorite_activities,
        },
      );
      const content = await generateFutureSnapshot(pet, answers);
      const { snapshot, remoteFailed: snapshotFailed } = await database.saveFutureSnapshot(
        pet.id,
        answers.id,
        content,
      );

      markRemoteSyncPending(answersFailed || snapshotFailed);
      showRemoteFallbackNotice(answersFailed || snapshotFailed);
      setResult(snapshot);
      setPhase('results');
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
      <SafeScreen>
        <EmptyState
          title="Add a pet first"
          message="Create a pet profile before generating a future snapshot."
          actionLabel="Create Pet Profile"
          onAction={() => router.push('/pet-profile')}
        />
      </SafeScreen>
    );
  }

  if (phase === 'results' && result) {
    return (
      <SafeScreen edges={['top']}>
        <ScrollView
          contentContainerStyle={[styles.resultsContent, { paddingHorizontal: horizontalPadding }]}
          showsVerticalScrollIndicator={false}>
          <SnapshotResultsHeader onBack={handleBack} onShare={handleShareSnapshot} />
          <OfflineBanner visible={remoteSyncPending} />
          <SnapshotCard
            label="Today"
            content={result.today}
            timeframe="today"
            photoUri={pet.photo_uri}
          />
          <SnapshotCard
            label="6 Months From Now"
            content={result.six_months}
            timeframe="six_months"
            photoUri={pet.photo_uri}
          />
          <SnapshotCard
            label="2 Years From Now"
            content={result.two_years}
            timeframe="two_years"
            photoUri={pet.photo_uri}
          />
          <SnapshotCard
            label="5 Years From Now"
            content={result.five_years}
            timeframe="five_years"
            photoUri={pet.photo_uri}
          />
        </ScrollView>
      </SafeScreen>
    );
  }

  const choiceValue = form[currentStep.key as keyof SnapshotDraft] as string;

  return (
    <SafeScreen edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <View style={[styles.headerWrap, { paddingHorizontal: horizontalPadding }]}>
          <ProfileScreenHeader title="Future Snapshot" onBack={handleBack} />
        </View>

        <ScrollView
          contentContainerStyle={[styles.wizardContent, { paddingHorizontal: horizontalPadding }]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}>
          <OfflineBanner visible={remoteSyncPending} />

          <Text style={styles.illustration}>{currentStep.illustration}</Text>

          <Text style={styles.question}>{currentStep.question}</Text>
          <Text style={styles.subtitle}>{currentStep.subtitle}</Text>

          {currentStep.type === 'choice' ? (
            <View style={styles.options}>
              {SNAPSHOT_FREQUENCY_OPTIONS.map((option) => (
                <SnapshotOptionButton
                  key={option}
                  label={option}
                  selected={choiceValue === option}
                  onPress={() => updateChoice(currentStep.key, option)}
                />
              ))}
            </View>
          ) : (
            <View style={styles.textWrap}>
              <TextInput
                value={form.favorite_activities}
                onChangeText={(value) => {
                  setTextError('');
                  updateChoice('favorite_activities', value);
                }}
                placeholder="Fetch, park walks, snuggle time..."
                placeholderTextColor={Colors.textMuted}
                multiline
                style={[styles.textInput, textError ? styles.textInputError : null]}
              />
              {textError ? <Text style={styles.error}>{textError}</Text> : null}
            </View>
          )}
        </ScrollView>

        <View style={[styles.footer, { paddingHorizontal: horizontalPadding }]}>
          <PrimaryButton
            title={isLastStep ? 'Generate Snapshot' : 'Next'}
            loading={loading}
            onPress={handleNext}
            style={styles.nextButton}
          />
          <SnapshotProgressBar step={stepIndex + 1} total={SNAPSHOT_STEPS.length} />
        </View>
      </KeyboardAvoidingView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
  headerWrap: {
    paddingTop: Spacing.sm,
  },
  wizardContent: {
    flexGrow: 1,
    paddingBottom: Spacing.lg,
  },
  illustration: {
    fontSize: 72,
    textAlign: 'center',
    marginTop: Spacing.md,
    marginBottom: Spacing.lg,
  },
  question: {
    ...Typography.title,
    color: Colors.text,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  subtitle: {
    ...Typography.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.lg,
    paddingHorizontal: Spacing.sm,
  },
  options: {
    marginTop: Spacing.sm,
  },
  textWrap: {
    marginTop: Spacing.sm,
  },
  textInput: {
    minHeight: 120,
    borderWidth: 1.5,
    borderColor: '#E8DDD3',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 14,
    backgroundColor: Colors.card,
    ...Typography.body,
    color: Colors.text,
    textAlignVertical: 'top',
  },
  textInputError: {
    borderColor: Colors.error,
  },
  error: {
    ...Typography.caption,
    color: Colors.error,
    marginTop: 8,
  },
  footer: {
    paddingTop: Spacing.sm,
    paddingBottom: Spacing.md,
    gap: Spacing.sm,
    backgroundColor: Colors.background,
  },
  nextButton: {
    borderRadius: Radius.full,
    backgroundColor: Colors.primaryDark,
  },
  resultsContent: {
    paddingTop: Spacing.sm,
    paddingBottom: Spacing.xxl,
  },
});
