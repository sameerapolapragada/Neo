import { Redirect } from 'expo-router';
import { useEffect, useState } from 'react';

import { LoadingState } from '@/components/LoadingState';
import { SafeScreen } from '@/components/SafeScreen';
import { usePet } from '@/context/PetContext';
import { auth } from '@/lib/auth';
import { database } from '@/lib/database';

export default function IndexScreen() {
  const { pet, loading, refresh } = usePet();
  const [sessionReady, setSessionReady] = useState(false);
  const [hasSession, setHasSession] = useState(false);
  const [onboardingComplete, setOnboardingComplete] = useState<boolean | null>(null);

  useEffect(() => {
    Promise.all([auth.getSession(), database.isOnboardingComplete(), refresh()]).then(
      ([session, complete]) => {
        setHasSession(Boolean(session));
        setOnboardingComplete(complete);
        setSessionReady(true);
      },
    );
  }, [refresh]);

  if (loading || !sessionReady || onboardingComplete === null) {
    return (
      <SafeScreen>
        <LoadingState message="Getting Neo ready..." />
      </SafeScreen>
    );
  }

  if (!hasSession) {
    if (pet && onboardingComplete) {
      return <Redirect href="/(tabs)" />;
    }

    return <Redirect href="/onboarding" />;
  }

  if (!onboardingComplete || !pet) {
    return <Redirect href="/pet-profile" />;
  }

  return <Redirect href="/(tabs)" />;
}
