import { router } from 'expo-router';
import { useState } from 'react';
import { Alert } from 'react-native';

import { AuthScreenShell } from '@/components/AuthScreenShell';
import { AuthTextField } from '@/components/AuthTextField';
import { auth } from '@/lib/auth';
import { hasAuthErrors, validateSignUpForm } from '@/utils/authValidation';

export default function SignUpScreen() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [secureVisible, setSecureVisible] = useState(false);
  const [confirmVisible, setConfirmVisible] = useState(false);
  const [errors, setErrors] = useState<ReturnType<typeof validateSignUpForm>>({});
  const [loading, setLoading] = useState(false);

  function clearError(key: keyof typeof errors) {
    if (errors[key]) {
      setErrors((current) => ({ ...current, [key]: undefined }));
    }
  }

  async function handleSignUp() {
    const nextErrors = validateSignUpForm(name, email, password, confirmPassword);
    setErrors(nextErrors);
    if (hasAuthErrors(nextErrors)) return;

    setLoading(true);
    try {
      const hasAccount = await auth.hasAccount();
      if (hasAccount) {
        Alert.alert(
          'Account already exists',
          'An account is already saved on this device. Try logging in instead.',
        );
        return;
      }

      await auth.signUp(name, email, password);
      router.replace('/pet-profile');
    } catch {
      Alert.alert('Sign up failed', 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthScreenShell
      title="Create your account"
      subtitle="Start capturing memories, milestones, and moments that matter."
      actionLabel="Get Started"
      actionLoading={loading}
      onAction={handleSignUp}
      footerText="Already have an account?"
      footerLinkLabel="Log in"
      onFooterLink={() => router.push('/login')}
      onBack={() => router.back()}>
      <AuthTextField
        label="Full name"
        value={name}
        onChangeText={(value) => {
          setName(value);
          clearError('name');
        }}
        placeholder="Your name"
        autoCapitalize="words"
        error={errors.name}
      />
      <AuthTextField
        label="Email"
        value={email}
        onChangeText={(value) => {
          setEmail(value);
          clearError('email');
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
          clearError('password');
        }}
        placeholder="Create a password"
        secureTextEntry={!secureVisible}
        secureToggle
        secureVisible={secureVisible}
        onToggleSecure={() => setSecureVisible((current) => !current)}
        error={errors.password}
      />
      <AuthTextField
        label="Confirm password"
        value={confirmPassword}
        onChangeText={(value) => {
          setConfirmPassword(value);
          clearError('confirmPassword');
        }}
        placeholder="Confirm your password"
        secureTextEntry={!confirmVisible}
        secureToggle
        secureVisible={confirmVisible}
        onToggleSecure={() => setConfirmVisible((current) => !current)}
        error={errors.confirmPassword}
      />
    </AuthScreenShell>
  );
}
