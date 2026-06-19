import type { SnapshotDraft } from '@/types';

export const SNAPSHOT_FREQUENCY_OPTIONS = [
  'Every day',
  'Several times a week',
  'Once a week',
  'Rarely',
  'Not yet',
] as const;

export type SnapshotFrequencyOption = (typeof SNAPSHOT_FREQUENCY_OPTIONS)[number];

export const SNAPSHOT_STEPS = [
  {
    key: 'play_frequency' as const,
    question: 'How often do you play together?',
    subtitle: 'This helps us imagine your future moments together.',
    illustration: '🔭',
    type: 'choice' as const,
  },
  {
    key: 'new_environments' as const,
    question: 'How often does your pet experience new environments?',
    subtitle: 'New places can shape confidence and curiosity over time.',
    illustration: '🌳',
    type: 'choice' as const,
  },
  {
    key: 'enrichment' as const,
    question: 'How often do you do enrichment, puzzles, or training?',
    subtitle: 'Little brain games become part of your shared rhythm.',
    illustration: '🧩',
    type: 'choice' as const,
  },
  {
    key: 'socialization' as const,
    question: 'How often does your pet socialize?',
    subtitle: 'Friends, family, and other pets all count here.',
    illustration: '🐾',
    type: 'choice' as const,
  },
  {
    key: 'favorite_activities' as const,
    question: "What are your pet's favorite activities?",
    subtitle: 'Think walks, games, snuggles, or anything they love.',
    illustration: '✨',
    type: 'text' as const,
  },
];

export function mapFrequencyToStored(value: SnapshotFrequencyOption): string {
  switch (value) {
    case 'Every day':
      return 'Daily';
    case 'Several times a week':
      return 'Several times a week';
    case 'Once a week':
      return 'Weekly';
    case 'Rarely':
      return 'Rarely';
    case 'Not yet':
      return 'Not yet';
    default:
      return value;
  }
}

export function mapStoredToFrequency(value: string): SnapshotFrequencyOption {
  switch (value) {
    case 'Daily':
    case 'Every day':
      return 'Every day';
    case 'Several times a week':
      return 'Several times a week';
    case 'Weekly':
    case 'Once a week':
      return 'Once a week';
    case 'Not yet':
      return 'Not yet';
    default:
      return 'Rarely';
  }
}

export function toStoredSnapshotDraft(form: SnapshotDraft): SnapshotDraft {
  return {
    play_frequency: mapFrequencyToStored(form.play_frequency as SnapshotFrequencyOption),
    new_environments: mapFrequencyToStored(form.new_environments as SnapshotFrequencyOption),
    enrichment: mapFrequencyToStored(form.enrichment as SnapshotFrequencyOption),
    socialization: mapFrequencyToStored(form.socialization as SnapshotFrequencyOption),
    favorite_activities: form.favorite_activities.trim(),
  };
}

export function fromStoredSnapshotDraft(stored: SnapshotDraft): SnapshotDraft {
  return {
    play_frequency: mapStoredToFrequency(stored.play_frequency),
    new_environments: mapStoredToFrequency(stored.new_environments),
    enrichment: mapStoredToFrequency(stored.enrichment),
    socialization: mapStoredToFrequency(stored.socialization),
    favorite_activities: stored.favorite_activities,
  };
}
