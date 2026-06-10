export type Species = 'Dog' | 'Cat' | 'Rabbit' | 'Bird' | 'Guinea Pig' | 'Other';

export interface Pet {
  id: string;
  name: string;
  species: Species;
  breed: string;
  age: string;
  weight?: string;
  photo_uri?: string;
  created_at: string;
}

export interface LifestyleAnswersInput {
  play_frequency: string;
  new_environments: string;
  enrichment: string;
  socialization: string;
  favorite_activities: string;
}

export interface LifestyleAnswers extends LifestyleAnswersInput {
  id: string;
  pet_id: string;
  created_at: string;
}

export interface FutureSnapshotContent {
  today: string;
  six_months: string;
  two_years: string;
  five_years: string;
}

export interface FutureSnapshot extends FutureSnapshotContent {
  id: string;
  pet_id: string;
  lifestyle_answers_id: string;
  created_at: string;
}

export interface MissingMomentsContent {
  moments_being_created: string[];
  moments_potentially_missing: string[];
  suggestions: string[];
}

export interface MissingMoments extends MissingMomentsContent {
  id: string;
  pet_id: string;
  created_at: string;
}

export interface Memory {
  id: string;
  pet_id: string;
  title: string;
  description: string;
  photo_uri?: string;
  created_at: string;
}

export type TimelineEntry =
  | { type: 'memory'; data: Memory }
  | { type: 'snapshot'; data: FutureSnapshot };

export interface PetProfileDraft {
  name: string;
  species: Species;
  breed: string;
  age: string;
  weight: string;
  photo_uri?: string;
}

export interface MemoryDraft {
  title: string;
  description: string;
  photo_uri?: string;
}

export interface SnapshotDraft {
  play_frequency: string;
  new_environments: string;
  enrichment: string;
  socialization: string;
  favorite_activities: string;
}
