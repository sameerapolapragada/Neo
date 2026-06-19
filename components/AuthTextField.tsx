import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface AuthTextFieldProps extends TextInputProps {
  label: string;
  error?: string;
  secureToggle?: boolean;
  secureVisible?: boolean;
  onToggleSecure?: () => void;
}

export function AuthTextField({
  label,
  error,
  secureToggle,
  secureVisible,
  onToggleSecure,
  style,
  ...props
}: AuthTextFieldProps) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>{label}</Text>
      <View style={[styles.inputWrap, error ? styles.inputError : null]}>
        <TextInput
          placeholderTextColor={AuthColors.textMuted}
          style={[styles.input, style]}
          {...props}
        />
        {secureToggle ? (
          <Pressable
            accessibilityRole="button"
            onPress={onToggleSecure}
            style={styles.secureButton}>
            <Ionicons
              name={secureVisible ? 'eye-off-outline' : 'eye-outline'}
              size={20}
              color={AuthColors.textMuted}
            />
          </Pressable>
        ) : null}
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 16,
  },
  label: {
    ...AuthTypography.label,
    color: AuthColors.text,
    marginBottom: 8,
  },
  inputWrap: {
    minHeight: 52,
    borderWidth: 1,
    borderColor: AuthColors.border,
    borderRadius: 14,
    backgroundColor: AuthColors.card,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
  },
  inputError: {
    borderColor: AuthColors.error,
  },
  input: {
    flex: 1,
    ...AuthTypography.body,
    color: AuthColors.text,
    paddingVertical: 12,
  },
  secureButton: {
    padding: 4,
    marginLeft: 8,
  },
  error: {
    ...AuthTypography.body,
    fontSize: 13,
    color: AuthColors.error,
    marginTop: 6,
  },
});
