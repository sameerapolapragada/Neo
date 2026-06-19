import { ReactNode } from 'react';
import { StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddLabeledBoxProps {
  label: string;
  error?: string;
  children?: ReactNode;
  footer?: ReactNode;
}

export function QuickAddLabeledBox({ label, error, children, footer }: QuickAddLabeledBoxProps) {
  return (
    <View style={styles.wrap}>
      <View style={[styles.box, error ? styles.boxError : null]}>
        <Text style={styles.label}>{label}</Text>
        {children}
        {footer}
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

export function QuickAddBoxInput({ style, ...props }: TextInputProps) {
  return (
    <TextInput
      placeholderTextColor="#B8AEA0"
      style={[styles.input, style]}
      {...props}
    />
  );
}

interface QuickAddBoxCaptionProps extends TextInputProps {
  value: string;
  maxLength: number;
}

export function QuickAddBoxCaption({ value, maxLength, style, ...props }: QuickAddBoxCaptionProps) {
  return (
    <>
      <TextInput
        placeholderTextColor="#B8AEA0"
        style={[styles.caption, style]}
        multiline
        maxLength={maxLength}
        value={value}
        {...props}
      />
      <Text style={styles.counter}>
        {value.length} / {maxLength}
      </Text>
    </>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 14,
  },
  box: {
    backgroundColor: AuthColors.quickAddField,
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 14,
  },
  boxError: {
    borderWidth: 1,
    borderColor: AuthColors.error,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    marginBottom: 8,
  },
  input: {
    ...AuthTypography.body,
    fontSize: 16,
    color: AuthColors.text,
    paddingVertical: 0,
  },
  caption: {
    ...AuthTypography.body,
    fontSize: 16,
    color: AuthColors.text,
    minHeight: 96,
    textAlignVertical: 'top',
    lineHeight: 22,
    paddingVertical: 0,
  },
  counter: {
    fontSize: 12,
    color: AuthColors.quickAddLabel,
    textAlign: 'right',
    marginTop: 8,
  },
  error: {
    ...AuthTypography.body,
    fontSize: 13,
    color: AuthColors.error,
    marginTop: 6,
    marginLeft: 4,
  },
});
