import { Redirect } from 'expo-router';
import { useEffect, useState } from 'react';

import { LoadingState } from '@/components/LoadingState';
import { SafeScreen } from '@/components/SafeScreen';
import { usePet } from '@/context/PetContext';
import { database } from '@/lib/database';

export default function IndexScreen() {
  const { pet, loading, refresh } = usePet();
  const [onboardingComplete, setOnboardingComplete] = useState<boolean | null>(null);

  useEffect(() => {
    database.isOnboardingComplete().then(setOnboardingComplete);
    refresh();
  }, [refresh]);

  if (loading || onboardingComplete === null) {
    return (
      <SafeScreen>
        <LoadingState message="Getting Neo ready..." />
      </SafeScreen>
    );
  }

  if (!onboardingComplete || !pet) {
    return <Redirect href="/onboarding" />;
  }

  return <Redirect href="/(tabs)" />;
}
