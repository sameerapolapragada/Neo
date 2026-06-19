import { Ionicons } from '@expo/vector-icons';
import { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface PetProfileFieldCardProps {
  label: string;
  onPress?: () => void;
  children: ReactNode;
  trailing?: ReactNode;
  error?: string;
}

export function PetProfileFieldCard({
  label,
  onPress,
  children,
  trailing,
  error,
}: PetProfileFieldCardProps) {
  const field = (
    <View style={[styles.field, error ? styles.fieldError : null]}>
      <Text style={styles.label}>{label}</Text>

      <View style={styles.row}>
        <View style={styles.content}>{children}</View>
        {trailing ? <View style={styles.trailing}>{trailing}</View> : null}
      </View>
    </View>
  );

  return (
    <View style={styles.wrap}>
      {onPress ? (
        <Pressable
          accessibilityRole="button"
          onPress={onPress}
          style={({ pressed }) => pressed && styles.pressed}>
          {field}
        </Pressable>
      ) : (
        field
      )}
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

interface PetProfileTextInputProps extends TextInputProps {
  value: string;
}

export function PetProfileTextInput({ style, ...props }: PetProfileTextInputProps) {
  return (
    <TextInput
      placeholderTextColor={AuthColors.textMuted}
      style={[styles.input, style]}
      {...props}
    />
  );
}

interface PetProfileValueTextProps {
  value: string;
  muted?: boolean;
}

export function PetProfileValueText({ value, muted }: PetProfileValueTextProps) {
  return (
    <Text style={[styles.valueText, muted && styles.valueMuted]} numberOfLines={1}>
      {value}
    </Text>
  );
}

export function PetProfileChevron() {
  return <Ionicons name="chevron-down" size={18} color={AuthColors.onboardingTextMuted} />;
}

export function PetProfileCalendarTrailing() {
  return <Ionicons name="calendar-outline" size={20} color={AuthColors.onboardingTextMuted} />;
}

export function PetProfileWeightSuffix({ unit }: { unit: string }) {
  return <Text style={styles.weightSuffix}>{unit}</Text>;
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 16,
  },
  field: {
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    borderRadius: 10,
    backgroundColor: AuthColors.background,
    paddingHorizontal: 14,
    paddingTop: 16,
    paddingBottom: 12,
    minHeight: 56,
  },
  fieldError: {
    borderColor: AuthColors.error,
  },
  label: {
    position: 'absolute',
    top: -9,
    left: 10,
    paddingHorizontal: 4,
    backgroundColor: AuthColors.background,
    fontSize: 12,
    fontWeight: '500',
    color: AuthColors.onboardingTextMuted,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  trailing: {
    marginLeft: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  input: {
    ...AuthTypography.body,
    color: AuthColors.text,
    fontWeight: '600',
    paddingVertical: 0,
  },
  valueText: {
    ...AuthTypography.body,
    color: AuthColors.text,
    fontWeight: '600',
  },
  valueMuted: {
    color: AuthColors.textMuted,
    fontWeight: '400',
  },
  weightSuffix: {
    ...AuthTypography.body,
    fontSize: 15,
    color: AuthColors.onboardingTextMuted,
    fontWeight: '500',
  },
  error: {
    ...AuthTypography.body,
    fontSize: 13,
    color: AuthColors.error,
    marginTop: 6,
    marginLeft: 4,
  },
  pressed: {
    opacity: 0.92,
  },
});
