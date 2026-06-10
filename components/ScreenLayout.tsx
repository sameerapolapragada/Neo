import { ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ScrollViewProps,
  StyleSheet,
  View,
  ViewStyle,
} from 'react-native';

import { LoadingState } from '@/components/LoadingState';
import { SafeScreen } from '@/components/SafeScreen';
import { Spacing } from '@/constants/theme';
import { useResponsive } from '@/hooks/useResponsive';

interface ScreenLayoutProps {
  children: ReactNode;
  scrollable?: boolean;
  keyboardAvoiding?: boolean;
  loading?: boolean;
  loadingMessage?: string;
  contentContainerStyle?: ViewStyle;
  scrollViewProps?: Omit<ScrollViewProps, 'contentContainerStyle' | 'children'>;
  footer?: ReactNode;
}

export function ScreenLayout({
  children,
  scrollable = true,
  keyboardAvoiding = false,
  loading = false,
  loadingMessage,
  contentContainerStyle,
  scrollViewProps,
  footer,
}: ScreenLayoutProps) {
  const { horizontalPadding, verticalPadding } = useResponsive();

  if (loading) {
    return (
      <SafeScreen>
        <LoadingState message={loadingMessage} />
      </SafeScreen>
    );
  }

  const contentStyle = [
    styles.content,
    {
      paddingHorizontal: horizontalPadding,
      paddingTop: verticalPadding,
      paddingBottom: Spacing.xxl,
    },
    contentContainerStyle,
  ];

  const body = scrollable ? (
    <ScrollView
      contentContainerStyle={contentStyle}
      keyboardShouldPersistTaps="handled"
      showsVerticalScrollIndicator={false}
      {...scrollViewProps}>
      {children}
    </ScrollView>
  ) : (
    <View style={[styles.flex, contentStyle]}>{children}</View>
  );

  return (
    <SafeScreen style={styles.flex}>
      {keyboardAvoiding ? (
        <KeyboardAvoidingView
          style={styles.flex}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          keyboardVerticalOffset={Platform.OS === 'ios' ? 4 : 0}>
          {body}
        </KeyboardAvoidingView>
      ) : (
        body
      )}
      {footer}
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
  content: {
    flexGrow: 1,
  },
});
