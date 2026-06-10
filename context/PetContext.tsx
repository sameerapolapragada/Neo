import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';

import { database } from '@/lib/database';
import { isSupabaseConfigured } from '@/lib/supabase';
import type { FutureSnapshot, Memory, MissingMoments, Pet } from '@/types';

interface PetContextValue {
  pet: Pet | null;
  latestSnapshot: FutureSnapshot | null;
  latestMoments: MissingMoments | null;
  memories: Memory[];
  loading: boolean;
  remoteSyncPending: boolean;
  refresh: () => Promise<void>;
  setPet: (pet: Pet | null) => void;
  markRemoteSyncPending: (pending: boolean) => void;
}

const PetContext = createContext<PetContextValue | null>(null);

export function PetProvider({ children }: { children: React.ReactNode }) {
  const [pet, setPet] = useState<Pet | null>(null);
  const [latestSnapshot, setLatestSnapshot] = useState<FutureSnapshot | null>(null);
  const [latestMoments, setLatestMoments] = useState<MissingMoments | null>(null);
  const [memories, setMemories] = useState<Memory[]>([]);
  const [loading, setLoading] = useState(true);
  const [remoteSyncPending, setRemoteSyncPending] = useState(!isSupabaseConfigured);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const activePet = await database.getActivePet();
      setPet(activePet);

      if (activePet) {
        const [snapshot, moments, petMemories] = await Promise.all([
          database.getLatestFutureSnapshot(activePet.id),
          database.getLatestMissingMoments(activePet.id),
          database.getMemories(activePet.id),
        ]);
        setLatestSnapshot(snapshot);
        setLatestMoments(moments);
        setMemories(petMemories);
      } else {
        setLatestSnapshot(null);
        setLatestMoments(null);
        setMemories([]);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const markRemoteSyncPending = useCallback((pending: boolean) => {
    setRemoteSyncPending(pending);
  }, []);

  return (
    <PetContext.Provider
      value={{
        pet,
        latestSnapshot,
        latestMoments,
        memories,
        loading,
        remoteSyncPending,
        refresh,
        setPet,
        markRemoteSyncPending,
      }}>
      {children}
    </PetContext.Provider>
  );
}

export function usePet() {
  const context = useContext(PetContext);
  if (!context) {
    throw new Error('usePet must be used within PetProvider');
  }
  return context;
}
