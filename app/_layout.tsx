import {
  ComicNeue_400Regular,
  ComicNeue_700Bold,
} from '@expo-google-fonts/comic-neue';
import { useFonts } from 'expo-font';
import * as Notifications from 'expo-notifications';
import { Stack, router } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import 'react-native-reanimated';

import { PetProvider } from '@/context/PetContext';
import { configureWellnessNotifications } from '@/lib/wellnessReminders';
import { setupDefaultFonts } from '@/lib/setupDefaultFonts';

export { ErrorBoundary } from 'expo-router';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    ComicNeue_400Regular,
    ComicNeue_700Bold,
    SpaceMono: require('../assets/fonts/SpaceMono-Regular.ttf'),
  });

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      setupDefaultFonts();
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  useEffect(() => {
    configureWellnessNotifications();

    const subscription = Notifications.addNotificationResponseReceivedListener((response) => {
      const url = response.notification.request.content.data?.url;
      if (typeof url === 'string') {
        router.push(url as '/(tabs)/moments');
      }
    });

    return () => subscription.remove();
  }, []);

  if (!loaded) {
    return null;
  }

  return (
    <PetProvider>
      <Stack screenOptions={{ headerShown: false, animation: 'fade' }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="onboarding" />
        <Stack.Screen name="login" />
        <Stack.Screen name="signup" />
        <Stack.Screen name="pet-profile" />
        <Stack.Screen name="add-memory" />
        <Stack.Screen name="memory/[id]" />
        <Stack.Screen name="weight-tracker" />
        <Stack.Screen name="more-features" />
        <Stack.Screen name="(tabs)" />
      </Stack>
    </PetProvider>
  );
}
