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

function pickByFrequency(frequency: string, high: string, mid: string, low: string): string {
  if (frequency === 'Daily' || frequency === 'Several times a week') return high;
  if (frequency === 'Weekly' || frequency === 'A few times a month') return mid;
  return low;
}

function buildActivityLine(pet: Pet, answers: LifestyleAnswersInput): string {
  const play = pickByFrequency(
    answers.play_frequency,
    'playful routines',
    'cozy routines',
    'quiet bonding moments',
  );
  return `${pet.name} enjoys ${answers.favorite_activities.toLowerCase()} with ${play} woven into everyday life.`;
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

    const activityLine = buildActivityLine(pet, answers);
    const envLine = pickByFrequency(
      answers.new_environments,
      'new places and scents keep curiosity alive',
      'familiar spots with occasional new discoveries',
      'a calm home base with gentle novelty',
    );
    const enrichLine = pickByFrequency(
      answers.enrichment,
      'puzzles, training, and enrichment are part of the rhythm',
      'enrichment pops up in small, meaningful bursts',
      'simple enrichment moments create steady joy',
    );
    const socialLine = pickByFrequency(
      answers.socialization,
      'social time adds sparkle to the week',
      'select social moments feel special',
      'one-on-one time stays at the center',
    );

    return {
      today: `${pet.name}'s story today is full of warmth. ${activityLine} With ${envLine}, ${enrichLine}, and ${socialLine}, this season feels like a living scrapbook in motion.`,
      six_months: `Six months from now, ${pet.name} may have a richer collection of favorite spots, silly habits, and little rituals. New photos and notes could capture how ${answers.favorite_activities.toLowerCase()} evolved into signature moments.`,
      two_years: `In two years, ${pet.name}'s lifestyle snapshot might show deeper routines: trusted walking routes, go-to enrichment games, and memories tied to seasons. The story becomes less about perfect days and more about meaningful patterns.`,
      five_years: `Five years from now, ${pet.name}'s memory timeline could read like a love letter—milestones, everyday joys, and the small adventures that made this chapter unforgettable. Neo helps preserve that lifestyle story, not predict health outcomes.`,
    };
  }

  async generateMissingMoments(pet: Pet): Promise<MissingMomentsContent> {
    await delay(600);

    const favoriteLabel = pet.breed ? `${pet.breed} adventures` : 'everyday adventures';

    return {
      moments_being_created: [
        `Daily routines with ${pet.name}`,
        `Favorite activities: ${favoriteLabel}`,
        'Photos and notes you already capture',
        'Comfortable home rituals',
      ],
      moments_potentially_missing: [
        'A photo from a new angle or location',
        'A note about a small personality change',
        'A new enrichment activity to try together',
        'A memory from an ordinary Tuesday',
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
