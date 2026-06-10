import { getSupabaseClient, isSupabaseConfigured } from '@/lib/supabase';
import { localStorage } from '@/lib/localStorage';
import { readWithFallback, writeWithFallback } from '@/lib/databaseHelpers';
import type {
  FutureSnapshot,
  FutureSnapshotContent,
  LifestyleAnswers,
  LifestyleAnswersInput,
  Memory,
  MissingMoments,
  MissingMomentsContent,
  Pet,
} from '@/types';

export type { DataSource } from '@/lib/databaseHelpers';

async function cachePet(pet: Pet): Promise<void> {
  await localStorage.setActivePetId(pet.id);
  await localStorage.savePet(pet);
}

export const database = {
  isRemote: isSupabaseConfigured,

  async isOnboardingComplete(): Promise<boolean> {
    return localStorage.isOnboardingComplete();
  },

  async setOnboardingComplete(): Promise<void> {
    await localStorage.setOnboardingComplete();
  },

  async getActivePet(): Promise<Pet | null> {
    const petId = await localStorage.getActivePetId();
    if (!petId) return null;

    const supabase = getSupabaseClient();
    const result = await readWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('pets')
              .select('*')
              .eq('id', petId)
              .single();
            if (error) throw error;
            return data as Pet;
          }
        : null,
      () => localStorage.getPet(petId),
      'Fetch pet',
    );

    if (result.data && result.source === 'remote') {
      await cachePet(result.data);
    }

    return result.data;
  },

  async savePet(
    pet: Omit<Pet, 'id' | 'created_at'> & { id?: string },
  ): Promise<{ pet: Pet; remoteFailed: boolean }> {
    const payload = {
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      age: pet.age,
      weight: pet.weight ?? null,
      photo_uri: pet.photo_uri ?? null,
    };

    const supabase = getSupabaseClient();
    const result = await writeWithFallback(
      supabase
        ? async () => {
            if (pet.id) {
              const { data, error } = await supabase
                .from('pets')
                .update(payload)
                .eq('id', pet.id)
                .select()
                .single();
              if (error) throw error;
              return data as Pet;
            }

            const { data, error } = await supabase
              .from('pets')
              .insert(payload)
              .select()
              .single();
            if (error) throw error;
            return data as Pet;
          }
        : null,
      () =>
        localStorage.savePet({
          id: pet.id,
          name: pet.name,
          species: pet.species,
          breed: pet.breed,
          age: pet.age,
          weight: pet.weight,
          photo_uri: pet.photo_uri,
        }),
      'Save pet',
    );

    await cachePet(result.data);
    await localStorage.setOnboardingComplete();

    return { pet: result.data, remoteFailed: result.remoteFailed };
  },

  async saveLifestyleAnswers(
    petId: string,
    answers: LifestyleAnswersInput,
  ): Promise<{ answers: LifestyleAnswers; remoteFailed: boolean }> {
    const supabase = getSupabaseClient();
    const result = await writeWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('lifestyle_answers')
              .insert({ pet_id: petId, ...answers })
              .select()
              .single();
            if (error) throw error;
            return data as LifestyleAnswers;
          }
        : null,
      () => localStorage.saveLifestyleAnswers(petId, answers),
      'Save lifestyle answers',
    );

    await localStorage.cacheLifestyleAnswers(result.data);
    return { answers: result.data, remoteFailed: result.remoteFailed };
  },

  async saveFutureSnapshot(
    petId: string,
    lifestyleAnswersId: string,
    content: FutureSnapshotContent,
  ): Promise<{ snapshot: FutureSnapshot; remoteFailed: boolean }> {
    const supabase = getSupabaseClient();
    const result = await writeWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('future_snapshots')
              .insert({
                pet_id: petId,
                lifestyle_answers_id: lifestyleAnswersId,
                ...content,
              })
              .select()
              .single();
            if (error) throw error;
            return data as FutureSnapshot;
          }
        : null,
      () => localStorage.saveFutureSnapshot(petId, lifestyleAnswersId, content),
      'Save future snapshot',
    );

    await localStorage.cacheFutureSnapshot(result.data);
    return { snapshot: result.data, remoteFailed: result.remoteFailed };
  },

  async getLatestFutureSnapshot(petId: string): Promise<FutureSnapshot | null> {
    const supabase = getSupabaseClient();
    const result = await readWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('future_snapshots')
              .select('*')
              .eq('pet_id', petId)
              .order('created_at', { ascending: false })
              .limit(1)
              .maybeSingle();
            if (error) throw error;
            return (data as FutureSnapshot) ?? null;
          }
        : null,
      () => localStorage.getLatestFutureSnapshot(petId),
      'Fetch latest snapshot',
    );

    return result.data;
  },

  async getFutureSnapshots(petId: string): Promise<FutureSnapshot[]> {
    const supabase = getSupabaseClient();
    const result = await readWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('future_snapshots')
              .select('*')
              .eq('pet_id', petId)
              .order('created_at', { ascending: false });
            if (error) throw error;
            return (data as FutureSnapshot[]) ?? [];
          }
        : null,
      () => localStorage.getFutureSnapshots(petId),
      'Fetch snapshots',
    );

    return result.data ?? [];
  },

  async saveMissingMoments(
    petId: string,
    content: MissingMomentsContent,
  ): Promise<{ moments: MissingMoments; remoteFailed: boolean }> {
    const supabase = getSupabaseClient();
    const result = await writeWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('missing_moments')
              .insert({
                pet_id: petId,
                moments_being_created: content.moments_being_created,
                moments_potentially_missing: content.moments_potentially_missing,
                suggestions: content.suggestions,
              })
              .select()
              .single();
            if (error) throw error;
            return data as MissingMoments;
          }
        : null,
      () => localStorage.saveMissingMoments(petId, content),
      'Save missing moments',
    );

    await localStorage.cacheMissingMoments(result.data);
    return { moments: result.data, remoteFailed: result.remoteFailed };
  },

  async getLatestMissingMoments(petId: string): Promise<MissingMoments | null> {
    const supabase = getSupabaseClient();
    const result = await readWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('missing_moments')
              .select('*')
              .eq('pet_id', petId)
              .order('created_at', { ascending: false })
              .limit(1)
              .maybeSingle();
            if (error) throw error;
            return (data as MissingMoments) ?? null;
          }
        : null,
      () => localStorage.getLatestMissingMoments(petId),
      'Fetch missing moments',
    );

    return result.data;
  },

  async saveMemory(
    petId: string,
    memory: Omit<Memory, 'id' | 'pet_id' | 'created_at'>,
  ): Promise<{ memory: Memory; remoteFailed: boolean }> {
    const supabase = getSupabaseClient();
    const result = await writeWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('memories')
              .insert({
                pet_id: petId,
                title: memory.title,
                description: memory.description,
                photo_uri: memory.photo_uri ?? null,
              })
              .select()
              .single();
            if (error) throw error;
            return data as Memory;
          }
        : null,
      () => localStorage.saveMemory(petId, memory),
      'Save memory',
    );

    await localStorage.cacheMemory(result.data);
    return { memory: result.data, remoteFailed: result.remoteFailed };
  },

  async getMemories(petId: string): Promise<Memory[]> {
    const supabase = getSupabaseClient();
    const result = await readWithFallback(
      supabase
        ? async () => {
            const { data, error } = await supabase
              .from('memories')
              .select('*')
              .eq('pet_id', petId)
              .order('created_at', { ascending: false });
            if (error) throw error;
            return (data as Memory[]) ?? [];
          }
        : null,
      () => localStorage.getMemories(petId),
      'Fetch memories',
    );

    return result.data ?? [];
  },
};
