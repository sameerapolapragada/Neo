import AsyncStorage from '@react-native-async-storage/async-storage';
import { v4 as uuidv4 } from 'uuid';

import type {
  FutureSnapshot,
  LifestyleAnswers,
  LifestyleAnswersInput,
  Memory,
  MissingMoments,
  Pet,
} from '@/types';

const KEYS = {
  pets: '@neo/pets',
  lifestyleAnswers: '@neo/lifestyle_answers',
  futureSnapshots: '@neo/future_snapshots',
  missingMoments: '@neo/missing_moments',
  memories: '@neo/memories',
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
      id: pet.id ?? uuidv4(),
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      age: pet.age,
      weight: pet.weight,
      photo_uri: pet.photo_uri,
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
      id: uuidv4(),
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
      id: uuidv4(),
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
      id: uuidv4(),
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
    memory: Omit<Memory, 'id' | 'pet_id' | 'created_at'>,
  ): Promise<Memory> {
    const all = await readJson<Memory[]>(KEYS.memories, []);
    const saved: Memory = {
      id: uuidv4(),
      pet_id: petId,
      ...memory,
      created_at: new Date().toISOString(),
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
};
