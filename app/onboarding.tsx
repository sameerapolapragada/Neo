import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { AppHeader } from '@/components/AppHeader';
import { AppLogo } from '@/components/AppLogo';
import { PrimaryButton } from '@/components/PrimaryButton';
import { ScreenLayout } from '@/components/ScreenLayout';

export default function OnboardingScreen() {
  return (
    <ScreenLayout contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <AppLogo style={styles.logo} />
      </View>

      <AppHeader
        title="Welcome to Neo"
        subtitle="Create memory-based lifestyle snapshots for your pet. Not medical advice—just meaningful moments."
        showDisclaimer
      />

      <PrimaryButton title="Create Pet Profile" onPress={() => router.push('/pet-profile')} />
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  content: {
    justifyContent: 'center',
  },
  hero: {
    alignItems: 'center',
    marginBottom: 32,
  },
  logo: {
    marginBottom: 8,
  },
});
