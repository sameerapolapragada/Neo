import { router } from 'expo-router';
import { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text } from 'react-native';

import { AuthScreenShell } from '@/components/AuthScreenShell';
import { AuthTextField } from '@/components/AuthTextField';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { usePet } from '@/context/PetContext';
import { auth } from '@/lib/auth';
import { database } from '@/lib/database';
import { hasAuthErrors, validateLoginForm } from '@/utils/authValidation';

export default function LoginScreen() {
  const { refresh } = usePet();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [secureVisible, setSecureVisible] = useState(false);
  const [errors, setErrors] = useState<ReturnType<typeof validateLoginForm>>({});
  const [loading, setLoading] = useState(false);

  async function routeAfterAuth() {
    await refresh();
    const [activePet, complete] = await Promise.all([
      database.getActivePet(),
      database.isOnboardingComplete(),
    ]);
    router.replace(activePet && complete ? '/(tabs)' : '/pet-profile');
  }

  async function handleLogin() {
    const nextErrors = validateLoginForm(email, password);
    setErrors(nextErrors);
    if (hasAuthErrors(nextErrors)) return;

    setLoading(true);
    try {
      await auth.signIn(email, password);
      await routeAfterAuth();
    } catch {
      Alert.alert('Sign in failed', 'Invalid email or password. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function handleContinueWithDevice() {
    const [pet, complete] = await Promise.all([
      database.getActivePet(),
      database.isOnboardingComplete(),
    ]);

    if (pet && complete) {
      await refresh();
      router.replace('/(tabs)');
      return;
    }

    Alert.alert(
      'No saved profile',
      'Create an account and pet profile to get started on this device.',
    );
  }

  return (
    <AuthScreenShell
      title="Welcome back"
      subtitle="Capture memories, milestones, and moments that matter."
      actionLabel="Log In"
      actionLoading={loading}
      onAction={handleLogin}
      footerText="Don't have an account?"
      footerLinkLabel="Sign up"
      onFooterLink={() => router.push('/signup')}
      onBack={() => router.back()}>
      <AuthTextField
        label="Email"
        value={email}
        onChangeText={(value) => {
          setEmail(value);
          if (errors.email) setErrors((current) => ({ ...current, email: undefined }));
        }}
        placeholder="you@example.com"
        keyboardType="email-address"
        autoCapitalize="none"
        autoCorrect={false}
        error={errors.email}
      />
      <AuthTextField
        label="Password"
        value={password}
        onChangeText={(value) => {
          setPassword(value);
          if (errors.password) setErrors((current) => ({ ...current, password: undefined }));
        }}
        placeholder="Enter your password"
        secureTextEntry={!secureVisible}
        secureToggle
        secureVisible={secureVisible}
        onToggleSecure={() => setSecureVisible((current) => !current)}
        error={errors.password}
      />

      <Pressable
        accessibilityRole="button"
        onPress={handleContinueWithDevice}
        style={({ pressed }) => [styles.deviceLink, pressed && styles.pressed]}>
        <Text style={styles.deviceLinkText}>Continue with saved profile on this device</Text>
      </Pressable>
    </AuthScreenShell>
  );
}

const styles = StyleSheet.create({
  deviceLink: {
    alignItems: 'center',
    paddingVertical: 8,
    marginBottom: 4,
  },
  deviceLinkText: {
    ...AuthTypography.body,
    color: AuthColors.onboardingPrimary,
    ...AuthTypography.label,
  },
  pressed: {
    opacity: 0.7,
  },
});
