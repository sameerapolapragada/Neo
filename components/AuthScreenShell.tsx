import { ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthLandingHero } from '@/components/AuthLandingHero';
import { AuthPrimaryButton } from '@/components/AuthPrimaryButton';
import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { useResponsive } from '@/hooks/useResponsive';

interface AuthScreenShellProps {
  title: string;
  subtitle: string;
  children: ReactNode;
  actionLabel: string;
  onAction: () => void;
  actionLoading?: boolean;
  footerText: string;
  footerLinkLabel: string;
  onFooterLink: () => void;
  onBack?: () => void;
}

export function AuthScreenShell({
  title,
  subtitle,
  children,
  actionLabel,
  onAction,
  actionLoading,
  footerText,
  footerLinkLabel,
  onFooterLink,
  onBack,
}: AuthScreenShellProps) {
  const { horizontalPadding } = useResponsive();
  const insets = useSafeAreaInsets();
  const contentPadding = Math.max(horizontalPadding, 24);

  return (
    <SafeScreen style={styles.screen} edges={[]}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}>
          <View style={styles.heroSection}>
            <AuthLandingHero />

            {onBack ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Go back"
                onPress={onBack}
                style={({ pressed }) => [
                  styles.backButton,
                  { top: insets.top + 4 },
                  pressed && styles.pressed,
                ]}>
                <Ionicons name="chevron-back" size={24} color={AuthColors.background} />
              </Pressable>
            ) : null}
          </View>

          <View style={[styles.body, { paddingHorizontal: contentPadding }]}>
            <Text style={styles.description}>{subtitle}</Text>

            <Text style={styles.title}>{title}</Text>

            <View style={styles.form}>{children}</View>

            <AuthPrimaryButton
              title={actionLoading ? 'Please wait...' : actionLabel}
              onPress={onAction}
              disabled={actionLoading}
              variant="onboarding"
              style={styles.actionButton}
            />

            <Text style={styles.footer}>
              {footerText}{' '}
              <Text style={styles.footerLink} onPress={onFooterLink}>
                {footerLinkLabel}
              </Text>
            </Text>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.background,
  },
  flex: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingBottom: Spacing.xxl,
  },
  heroSection: {
    position: 'relative',
  },
  backButton: {
    position: 'absolute',
    left: 8,
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 22,
    backgroundColor: 'rgba(0,0,0,0.22)',
  },
  pressed: {
    opacity: 0.7,
  },
  body: {
    alignItems: 'center',
    marginTop: 4,
    gap: 0,
  },
  description: {
    ...AuthTypography.body,
    fontSize: 14,
    lineHeight: 20,
    color: AuthColors.onboardingTextMuted,
    textAlign: 'center',
    marginTop: 4,
    maxWidth: 280,
  },
  title: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
    marginTop: 24,
    marginBottom: 4,
    alignSelf: 'stretch',
    textAlign: 'left',
  },
  form: {
    alignSelf: 'stretch',
    marginTop: 8,
  },
  actionButton: {
    alignSelf: 'stretch',
    marginTop: 8,
  },
  footer: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.text,
    textAlign: 'center',
    marginTop: 20,
  },
  footerLink: {
    ...AuthTypography.label,
    color: AuthColors.onboardingPrimary,
  },
});
