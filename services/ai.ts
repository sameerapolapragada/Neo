import { WEEKLY_SUGGESTIONS } from '@/constants/theme';
import type {
  FutureSnapshotContent,
  LifestyleAnswersInput,
  MissingMomentsContent,
  Pet,
} from '@/types';

export interface AIService {
  generateFutureSnapshot(
    pet: Pet,
    answers: LifestyleAnswersInput,
  ): Promise<FutureSnapshotContent>;
  generateMissingMoments(pet: Pet): Promise<MissingMomentsContent>;
}

type FrequencyTier = 'high' | 'mid' | 'low';

function frequencyTier(frequency: string): FrequencyTier {
  const normalized = frequency.toLowerCase();
  if (
    normalized === 'daily' ||
    normalized === 'every day' ||
    normalized === 'several times a week'
  ) {
    return 'high';
  }
  if (normalized === 'weekly' || normalized === 'once a week') {
    return 'mid';
  }
  return 'low';
}

function activityPhrase(activities: string): string | null {
  const trimmed = activities.trim();
  if (!trimmed) return null;
  const lower = trimmed.toLowerCase();
  if (lower.startsWith('fetch') || lower.startsWith('walk') || lower.startsWith('park')) {
    return trimmed;
  }
  return trimmed.charAt(0).toLowerCase() + trimmed.slice(1);
}

function buildTodayLine(pet: Pet, answers: LifestyleAnswersInput): string {
  const play = frequencyTier(answers.play_frequency);
  const activity = activityPhrase(answers.favorite_activities);

  if (play === 'high') {
    return activity
      ? `${pet.name} enjoys your company—especially during ${activity}—and feels safe, loved, and happy in their daily routine.`
      : `${pet.name} enjoys your company and feels safe, loved, and happy in their daily routine.`;
  }

  if (play === 'mid') {
    return `${pet.name} looks forward to time with you and finds comfort in the routines you share.`;
  }

  if (answers.play_frequency.toLowerCase() === 'not yet') {
    return `${pet.name} is just getting to know you, and the gentle moments you share already matter.`;
  }

  return `${pet.name} cherishes quiet time with you and feels secure in the bond you're building.`;
}

function buildSixMonthsLine(pet: Pet, answers: LifestyleAnswersInput): string {
  const environments = frequencyTier(answers.new_environments);
  const enrichment = frequencyTier(answers.enrichment);

  if (environments === 'high' || enrichment === 'high') {
    return `${pet.name} may continue to grow in confidence and enjoy new experiences with you.`;
  }

  if (environments === 'mid' || enrichment === 'mid') {
    return `${pet.name} may start exploring more of the world at their own pace, with you by their side.`;
  }

  return `${pet.name} may feel more at ease as familiar places and gentle routines become part of their story.`;
}

function buildTwoYearsLine(pet: Pet, answers: LifestyleAnswersInput): string {
  const play = frequencyTier(answers.play_frequency);
  const social = frequencyTier(answers.socialization);
  const activity = activityPhrase(answers.favorite_activities);

  if (play === 'high' || social === 'high') {
    return activity
      ? `Your bond may become even deeper as you explore more adventures together—especially around ${activity}.`
      : 'Your bond may become even deeper as you explore more adventures together.';
  }

  if (play === 'mid' || social === 'mid') {
    return `The trust you share with ${pet.name} may grow into a steady rhythm of meaningful moments.`;
  }

  return `The quiet care you give ${pet.name} today may blossom into a deeply rooted companionship.`;
}

function buildFiveYearsLine(answers: LifestyleAnswersInput): string {
  const activity = activityPhrase(answers.favorite_activities);

  if (activity) {
    return `These moments you're building today—including ${activity}—may become some of your most cherished memories.`;
  }

  return "These moments you're building today may become some of your most cherished memories.";
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class MockAIService implements AIService {
  async generateFutureSnapshot(
    pet: Pet,
    answers: LifestyleAnswersInput,
  ): Promise<FutureSnapshotContent> {
    await delay(800);

    return {
      today: buildTodayLine(pet, answers),
      six_months: buildSixMonthsLine(pet, answers),
      two_years: buildTwoYearsLine(pet, answers),
      five_years: buildFiveYearsLine(answers),
    };
  }

  async generateMissingMoments(pet: Pet): Promise<MissingMomentsContent> {
    await delay(600);

    return {
      moments_being_created: [
        `Daily companionship with ${pet.name}`,
        'Familiar routines',
        'Play time at home',
      ],
      moments_potentially_missing: [
        'New environments',
        'Puzzle enrichment',
        'Social experiences',
        'Training games',
        'Photo memories',
      ],
      suggestions: [...WEEKLY_SUGGESTIONS],
    };
  }
}

const mockService = new MockAIService();

export async function generateFutureSnapshot(
  pet: Pet,
  answers: LifestyleAnswersInput,
): Promise<FutureSnapshotContent> {
  return mockService.generateFutureSnapshot(pet, answers);
}

export async function generateMissingMoments(pet: Pet): Promise<MissingMomentsContent> {
  return mockService.generateMissingMoments(pet);
}

export function createAIService(provider: 'mock' | 'openai' | 'claude' = 'mock'): AIService {
  if (provider === 'mock') return mockService;
  throw new Error(`${provider} provider not configured yet. Use mock for MVP.`);
}
