import { Picker } from '@react-native-picker/picker';
import { Platform, StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';

interface ProfileFormFieldProps extends TextInputProps {
  label: string;
  error?: string;
  required?: boolean;
}

export function ProfileFormField({
  label,
  error,
  required,
  style,
  ...props
}: ProfileFormFieldProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>
        {label}
        {required ? <Text style={styles.required}> *</Text> : null}
      </Text>
      <TextInput
        placeholderTextColor={Colors.textMuted}
        style={[styles.input, error ? styles.inputError : null, style]}
        {...props}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

interface ProfileFormPickerProps<T extends string> {
  label: string;
  value: T;
  options: readonly T[];
  onValueChange: (value: T) => void;
  error?: string;
  compact?: boolean;
}

export function ProfileFormPicker<T extends string>({
  label,
  value,
  options,
  onValueChange,
  error,
  compact = false,
}: ProfileFormPickerProps<T>) {
  return (
    <View style={[styles.container, compact && styles.compactContainer]}>
      {!compact ? <Text style={styles.label}>{label}</Text> : null}
      <View style={[styles.pickerWrap, compact && styles.compactPickerWrap, error ? styles.inputError : null]}>
        <Picker
          selectedValue={value}
          onValueChange={onValueChange}
          style={[styles.picker, compact && styles.compactPicker]}
          itemStyle={Platform.OS === 'ios' && !compact ? styles.pickerItem : undefined}>
          {options.map((option) => (
            <Picker.Item key={option} label={option} value={option} />
          ))}
        </Picker>
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

interface ProfileWeightFieldProps {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  unit?: string;
  error?: string;
}

export function ProfileWeightField({
  label,
  value,
  onChangeText,
  unit = 'kg',
  error,
}: ProfileWeightFieldProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>{label}</Text>
      <View style={[styles.weightWrap, error ? styles.inputError : null]}>
        <TextInput
          value={value}
          onChangeText={onChangeText}
          keyboardType="decimal-pad"
          placeholder="12"
          placeholderTextColor={Colors.textMuted}
          style={styles.weightInput}
        />
        <Text style={styles.unit}>{unit}</Text>
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 18,
  },
  compactContainer: {
    marginBottom: 0,
    flex: 1,
  },
  label: {
    ...Typography.label,
    color: Colors.text,
    marginBottom: 8,
  },
  required: {
    color: Colors.error,
  },
  input: {
    minHeight: 50,
    borderWidth: 1,
    borderColor: '#E8DDD3',
    borderRadius: 18,
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.card,
    ...Typography.body,
    color: Colors.text,
  },
  pickerWrap: {
    borderWidth: 1,
    borderColor: '#E8DDD3',
    borderRadius: 18,
    backgroundColor: Colors.card,
    overflow: 'hidden',
    minHeight: 50,
    justifyContent: 'center',
  },
  compactPickerWrap: {
    minHeight: 50,
  },
  picker: {
    height: Platform.OS === 'ios' ? 132 : 50,
  },
  compactPicker: {
    height: 50,
    marginTop: Platform.OS === 'ios' ? -8 : 0,
  },
  pickerItem: {
    ...Typography.body,
  },
  weightWrap: {
    minHeight: 50,
    borderWidth: 1,
    borderColor: '#E8DDD3',
    borderRadius: 18,
    paddingHorizontal: 16,
    backgroundColor: Colors.card,
    flexDirection: 'row',
    alignItems: 'center',
  },
  weightInput: {
    flex: 1,
    ...Typography.body,
    color: Colors.text,
    paddingVertical: 12,
  },
  unit: {
    ...Typography.body,
    color: Colors.textSecondary,
    marginLeft: 8,
  },
  inputError: {
    borderColor: Colors.error,
  },
  error: {
    ...Typography.caption,
    color: Colors.error,
    marginTop: 6,
  },
});
