import AsyncStorage from '@react-native-async-storage/async-storage';

import type { MemoryDraft, PetProfileDraft, SnapshotDraft } from '@/types';

const KEYS = {
  petProfile: '@neo/draft/pet_profile',
  snapshot: '@neo/draft/snapshot',
  memory: '@neo/draft/memory',
} as const;

export const drafts = {
  async getPetProfile(): Promise<PetProfileDraft | null> {
    const raw = await AsyncStorage.getItem(KEYS.petProfile);
    return raw ? (JSON.parse(raw) as PetProfileDraft) : null;
  },

  async savePetProfile(draft: PetProfileDraft): Promise<void> {
    await AsyncStorage.setItem(KEYS.petProfile, JSON.stringify(draft));
  },

  async clearPetProfile(): Promise<void> {
    await AsyncStorage.removeItem(KEYS.petProfile);
  },

  async getSnapshot(): Promise<SnapshotDraft | null> {
    const raw = await AsyncStorage.getItem(KEYS.snapshot);
    return raw ? (JSON.parse(raw) as SnapshotDraft) : null;
  },

  async saveSnapshot(draft: SnapshotDraft): Promise<void> {
    await AsyncStorage.setItem(KEYS.snapshot, JSON.stringify(draft));
  },

  async clearSnapshot(): Promise<void> {
    await AsyncStorage.removeItem(KEYS.snapshot);
  },

  async getMemory(): Promise<MemoryDraft | null> {
    const raw = await AsyncStorage.getItem(KEYS.memory);
    return raw ? (JSON.parse(raw) as MemoryDraft) : null;
  },

  async saveMemory(draft: MemoryDraft): Promise<void> {
    await AsyncStorage.setItem(KEYS.memory, JSON.stringify(draft));
  },

  async clearMemory(): Promise<void> {
    await AsyncStorage.removeItem(KEYS.memory);
  },
};
