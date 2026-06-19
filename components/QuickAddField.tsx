import { ReactNode } from 'react';
import { StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddFieldProps {
  label: string;
  error?: string;
  children?: ReactNode;
  multiline?: boolean;
}

export function QuickAddField({ label, error, children, multiline }: QuickAddFieldProps) {
  return (
    <View style={styles.wrap}>
      <View style={[styles.field, multiline && styles.fieldMultiline, error ? styles.fieldError : null]}>
        <Text style={styles.floatingLabel}>{label}</Text>
        {children}
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

export function QuickAddInput({ style, ...props }: TextInputProps) {
  return (
    <TextInput
      placeholderTextColor={AuthColors.textMuted}
      style={[styles.input, style]}
      {...props}
    />
  );
}

interface QuickAddCaptionProps extends TextInputProps {
  value: string;
  maxLength: number;
}

export function QuickAddCaption({ value, maxLength, style, ...props }: QuickAddCaptionProps) {
  return (
    <TextInput
      placeholderTextColor={AuthColors.textMuted}
      style={[styles.caption, style]}
      multiline
      maxLength={maxLength}
      value={value}
      {...props}
    />
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 16,
  },
  field: {
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    borderRadius: 12,
    backgroundColor: AuthColors.background,
    paddingHorizontal: 14,
    paddingTop: 16,
    paddingBottom: 12,
    minHeight: 56,
  },
  fieldMultiline: {
    minHeight: 120,
    paddingBottom: 14,
  },
  fieldError: {
    borderColor: AuthColors.error,
  },
  floatingLabel: {
    position: 'absolute',
    top: -9,
    left: 10,
    paddingHorizontal: 4,
    backgroundColor: AuthColors.background,
    fontSize: 12,
    fontWeight: '500',
    color: AuthColors.onboardingTextMuted,
  },
  input: {
    ...AuthTypography.body,
    fontWeight: '600',
    color: AuthColors.text,
    paddingVertical: 0,
  },
  caption: {
    ...AuthTypography.body,
    fontWeight: '400',
    color: AuthColors.text,
    minHeight: 88,
    textAlignVertical: 'top',
    lineHeight: 22,
    paddingVertical: 0,
  },
  error: {
    ...AuthTypography.body,
    fontSize: 13,
    color: AuthColors.error,
    marginTop: 6,
    marginLeft: 4,
  },
});
