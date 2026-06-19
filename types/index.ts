export type Species = 'Dog' | 'Cat' | 'Rabbit' | 'Bird' | 'Guinea Pig' | 'Other';

export type PetGender = 'Male' | 'Female' | 'Neutered' | 'Spayed' | 'Unknown';

export type WeightUnit = 'kg' | 'lbs';

export interface Pet {
  id: string;
  name: string;
  species: Species;
  breed: string;
  age: string;
  weight?: string;
  photo_uri?: string;
  birthday?: string;
  gender?: PetGender;
  adoption_date?: string;
  microchip_id?: string;
  vet_name?: string;
  vet_clinic?: string;
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
  entry_type?: MemoryEntryType;
  category?: MemoryCategory;
  sentiment?: MilestoneSentiment;
  created_at: string;
}

export type MemoryEntryType = 'memory' | 'milestone';

export type MemoryCategory =
  | 'Memory'
  | 'Adventure'
  | 'Funny Moment'
  | 'Birthday'
  | 'Favorite Thing';

export type TimelineEntry =
  | { type: 'memory'; data: Memory }
  | { type: 'snapshot'; data: FutureSnapshot };

export type AgeUnit = 'years' | 'months';

export interface PetProfileDraft {
  name: string;
  species: Species;
  breed: string;
  birthday: string;
  gender: PetGender;
  adoption_date: string;
  weightValue: string;
  weightUnit: WeightUnit;
  microchip_id: string;
  photo_uri?: string;
}

export type MilestoneSentiment =
  | 'Emotional'
  | 'Joyful'
  | 'Hilarious'
  | 'Loving'
  | 'Proud'
  | 'Bittersweet';

export interface MemoryDraft {
  entry_type: MemoryEntryType;
  category: MemoryCategory;
  title: string;
  description: string;
  photo_uris: string[];
  memory_date: string;
  sentiment?: MilestoneSentiment;
}

export interface SnapshotDraft {
  play_frequency: string;
  new_environments: string;
  enrichment: string;
  socialization: string;
  favorite_activities: string;
}

export type WellnessMetricId = 'appetite' | 'energy' | 'mood' | 'exercise' | 'sleep';

export type WellnessRatings = Partial<Record<WellnessMetricId, number>>;

export interface WellnessCheckIn {
  id: string;
  pet_id: string;
  week_start: string;
  ratings: WellnessRatings;
  created_at: string;
  updated_at: string;
}

export interface WeightEntry {
  id: string;
  pet_id: string;
  weight: string;
  recorded_at: string;
  created_at: string;
}
