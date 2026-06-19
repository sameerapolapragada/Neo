import AsyncStorage from '@react-native-async-storage/async-storage';

import { generateId } from '@/lib/id';

import type {
  FutureSnapshot,
  LifestyleAnswers,
  LifestyleAnswersInput,
  Memory,
  MissingMoments,
  Pet,
  WellnessCheckIn,
  WellnessRatings,
  WeightEntry,
} from '@/types';

const KEYS = {
  pets: '@neo/pets',
  lifestyleAnswers: '@neo/lifestyle_answers',
  futureSnapshots: '@neo/future_snapshots',
  missingMoments: '@neo/missing_moments',
  memories: '@neo/memories',
  wellnessCheckIns: '@neo/wellness_check_ins',
  weightEntries: '@neo/weight_entries',
  activePetId: '@neo/active_pet_id',
  onboardingComplete: '@neo/onboarding_complete',
} as const;

async function readJson<T>(key: string, fallback: T): Promise<T> {
  const raw = await AsyncStorage.getItem(key);
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

async function writeJson<T>(key: string, value: T): Promise<void> {
  await AsyncStorage.setItem(key, JSON.stringify(value));
}

export const localStorage = {
  async isOnboardingComplete(): Promise<boolean> {
    const value = await AsyncStorage.getItem(KEYS.onboardingComplete);
    return value === 'true';
  },

  async setOnboardingComplete(): Promise<void> {
    await AsyncStorage.setItem(KEYS.onboardingComplete, 'true');
  },

  async getActivePetId(): Promise<string | null> {
    return AsyncStorage.getItem(KEYS.activePetId);
  },

  async setActivePetId(petId: string): Promise<void> {
    await AsyncStorage.setItem(KEYS.activePetId, petId);
  },

  async getPet(petId: string): Promise<Pet | null> {
    const pets = await readJson<Pet[]>(KEYS.pets, []);
    return pets.find((pet) => pet.id === petId) ?? null;
  },

  async getActivePet(): Promise<Pet | null> {
    const petId = await this.getActivePetId();
    if (!petId) return null;
    return this.getPet(petId);
  },

  async savePet(
    pet: Omit<Pet, 'id' | 'created_at'> & { id?: string },
  ): Promise<Pet> {
    const pets = await readJson<Pet[]>(KEYS.pets, []);
    const now = new Date().toISOString();
    const saved: Pet = {
      id: pet.id ?? generateId(),
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      age: pet.age,
      weight: pet.weight,
      photo_uri: pet.photo_uri,
      birthday: pet.birthday,
      gender: pet.gender,
      adoption_date: pet.adoption_date,
      microchip_id: pet.microchip_id,
      created_at: pet.id
        ? (pets.find((p) => p.id === pet.id)?.created_at ?? now)
        : now,
    };

    const index = pets.findIndex((p) => p.id === saved.id);
    if (index >= 0) {
      pets[index] = saved;
    } else {
      pets.push(saved);
    }

    await writeJson(KEYS.pets, pets);
    await this.setActivePetId(saved.id);
    return saved;
  },

  async saveLifestyleAnswers(
    petId: string,
    answers: LifestyleAnswersInput,
  ): Promise<LifestyleAnswers> {
    const all = await readJson<LifestyleAnswers[]>(KEYS.lifestyleAnswers, []);
    const saved: LifestyleAnswers = {
      id: generateId(),
      pet_id: petId,
      ...answers,
      created_at: new Date().toISOString(),
    };
    all.push(saved);
    await writeJson(KEYS.lifestyleAnswers, all);
    return saved;
  },

  async cacheLifestyleAnswers(entry: LifestyleAnswers): Promise<void> {
    const all = await readJson<LifestyleAnswers[]>(KEYS.lifestyleAnswers, []);
    const index = all.findIndex((item) => item.id === entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.push(entry);
    }
    await writeJson(KEYS.lifestyleAnswers, all);
  },

  async saveFutureSnapshot(
    petId: string,
    lifestyleAnswersId: string,
    content: Omit<FutureSnapshot, 'id' | 'pet_id' | 'lifestyle_answers_id' | 'created_at'>,
  ): Promise<FutureSnapshot> {
    const all = await readJson<FutureSnapshot[]>(KEYS.futureSnapshots, []);
    const saved: FutureSnapshot = {
      id: generateId(),
      pet_id: petId,
      lifestyle_answers_id: lifestyleAnswersId,
      ...content,
      created_at: new Date().toISOString(),
    };
    all.unshift(saved);
    await writeJson(KEYS.futureSnapshots, all);
    return saved;
  },

  async cacheFutureSnapshot(entry: FutureSnapshot): Promise<void> {
    const all = await readJson<FutureSnapshot[]>(KEYS.futureSnapshots, []);
    const index = all.findIndex((item) => item.id === entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.unshift(entry);
    }
    await writeJson(KEYS.futureSnapshots, all);
  },

  async getLatestFutureSnapshot(petId: string): Promise<FutureSnapshot | null> {
    const all = await readJson<FutureSnapshot[]>(KEYS.futureSnapshots, []);
    return all.find((snapshot) => snapshot.pet_id === petId) ?? null;
  },

  async getFutureSnapshots(petId: string): Promise<FutureSnapshot[]> {
    const all = await readJson<FutureSnapshot[]>(KEYS.futureSnapshots, []);
    return all.filter((snapshot) => snapshot.pet_id === petId);
  },

  async saveMissingMoments(
    petId: string,
    content: Omit<MissingMoments, 'id' | 'pet_id' | 'created_at'>,
  ): Promise<MissingMoments> {
    const all = await readJson<MissingMoments[]>(KEYS.missingMoments, []);
    const saved: MissingMoments = {
      id: generateId(),
      pet_id: petId,
      ...content,
      created_at: new Date().toISOString(),
    };
    all.unshift(saved);
    await writeJson(KEYS.missingMoments, all);
    return saved;
  },

  async cacheMissingMoments(entry: MissingMoments): Promise<void> {
    const all = await readJson<MissingMoments[]>(KEYS.missingMoments, []);
    const index = all.findIndex((item) => item.id === entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.unshift(entry);
    }
    await writeJson(KEYS.missingMoments, all);
  },

  async getLatestMissingMoments(petId: string): Promise<MissingMoments | null> {
    const all = await readJson<MissingMoments[]>(KEYS.missingMoments, []);
    return all.find((entry) => entry.pet_id === petId) ?? null;
  },

  async saveMemory(
    petId: string,
    memory: Omit<Memory, 'id' | 'pet_id' | 'created_at'> & { created_at?: string },
  ): Promise<Memory> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    const { created_at, ...fields } = memory;
    const saved: Memory = {
      id: generateId(),
      pet_id: petId,
      ...fields,
      created_at: created_at ?? new Date().toISOString(),
    };
    all.unshift(saved);
    await writeJson(KEYS.memories, all);
    return saved;
  },

  async cacheMemory(entry: Memory): Promise<void> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    const index = all.findIndex((item) => item.id === entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.unshift(entry);
    }
    await writeJson(KEYS.memories, all);
  },

  async getMemories(petId: string): Promise<Memory[]> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    return all.filter((memory) => memory.pet_id === petId);
  },

  async getMemory(petId: string, memoryId: string): Promise<Memory | null> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    return all.find((memory) => memory.pet_id === petId && memory.id === memoryId) ?? null;
  },

  async updateMemory(
    petId: string,
    memoryId: string,
    updates: Partial<Omit<Memory, 'id' | 'pet_id'>>,
  ): Promise<Memory> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    const index = all.findIndex(
      (memory) => memory.pet_id === petId && memory.id === memoryId,
    );

    if (index < 0) {
      throw new Error('Memory not found');
    }

    const updated: Memory = {
      ...all[index],
      ...updates,
    };
    all[index] = updated;
    await writeJson(KEYS.memories, all);
    return updated;
  },

  async deleteMemory(petId: string, memoryId: string): Promise<void> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    const filtered = all.filter(
      (memory) => !(memory.pet_id === petId && memory.id === memoryId),
    );
    await writeJson(KEYS.memories, filtered);
  },

  async getWellnessCheckIns(petId: string): Promise<WellnessCheckIn[]> {
    const all = await readJson<WellnessCheckIn[]>(KEYS.wellnessCheckIns, []);
    return all
      .filter((checkIn) => checkIn.pet_id === petId)
      .sort(
        (a, b) =>
          new Date(b.week_start).getTime() - new Date(a.week_start).getTime(),
      );
  },

  async getWellnessCheckInForWeek(
    petId: string,
    weekStart: string,
  ): Promise<WellnessCheckIn | null> {
    const all = await readJson<WellnessCheckIn[]>(KEYS.wellnessCheckIns, []);
    return (
      all.find(
        (checkIn) =>
          checkIn.pet_id === petId && checkIn.week_start.slice(0, 10) === weekStart.slice(0, 10),
      ) ?? null
    );
  },

  async saveWellnessCheckIn(
    petId: string,
    weekStart: string,
    ratings: WellnessRatings,
  ): Promise<WellnessCheckIn> {
    const all = await readJson<WellnessCheckIn[]>(KEYS.wellnessCheckIns, []);
    const normalizedWeek = weekStart.slice(0, 10);
    const now = new Date().toISOString();
    const existingIndex = all.findIndex(
      (checkIn) =>
        checkIn.pet_id === petId && checkIn.week_start.slice(0, 10) === normalizedWeek,
    );

    if (existingIndex >= 0) {
      const updated: WellnessCheckIn = {
        ...all[existingIndex],
        ratings,
        updated_at: now,
      };
      all[existingIndex] = updated;
      await writeJson(KEYS.wellnessCheckIns, all);
      return updated;
    }

    const saved: WellnessCheckIn = {
      id: generateId(),
      pet_id: petId,
      week_start: normalizedWeek,
      ratings,
      created_at: now,
      updated_at: now,
    };
    all.unshift(saved);
    await writeJson(KEYS.wellnessCheckIns, all);
    return saved;
  },

  async getWeightEntries(petId: string): Promise<WeightEntry[]> {
    const all = await readJson<WeightEntry[]>(KEYS.weightEntries, []);
    return all
      .filter((entry) => entry.pet_id === petId)
      .sort(
        (a, b) =>
          new Date(b.recorded_at).getTime() - new Date(a.recorded_at).getTime(),
      );
  },

  async saveWeightEntry(
    petId: string,
    entry: Omit<WeightEntry, 'id' | 'pet_id' | 'created_at'>,
  ): Promise<WeightEntry> {
    const all = await readJson<WeightEntry[]>(KEYS.weightEntries, []);
    const saved: WeightEntry = {
      id: generateId(),
      pet_id: petId,
      weight: entry.weight,
      recorded_at: entry.recorded_at,
      created_at: new Date().toISOString(),
    };
    all.unshift(saved);
    await writeJson(KEYS.weightEntries, all);
    return saved;
  },

  async deleteWeightEntry(petId: string, entryId: string): Promise<void> {
    const all = await readJson<WeightEntry[]>(KEYS.weightEntries, []);
    const filtered = all.filter(
      (entry) => !(entry.pet_id === petId && entry.id === entryId),
    );
    await writeJson(KEYS.weightEntries, filtered);
  },
};
