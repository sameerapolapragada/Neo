import { Picker } from '@react-native-picker/picker';
import { Platform, StyleSheet, Text, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';

interface FormPickerProps<T extends string> {
  label: string;
  value: T;
  options: readonly T[];
  onValueChange: (value: T) => void;
  error?: string;
}

export function FormPicker<T extends string>({
  label,
  value,
  options,
  onValueChange,
  error,
}: FormPickerProps<T>) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>{label}</Text>
      <View style={[styles.pickerWrap, error ? styles.inputError : null]}>
        <Picker
          selectedValue={value}
          onValueChange={onValueChange}
          style={styles.picker}
          itemStyle={Platform.OS === 'ios' ? styles.pickerItem : undefined}>
          {options.map((option) => (
            <Picker.Item key={option} label={option} value={option} />
          ))}
        </Picker>
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  label: {
    ...Typography.label,
    color: Colors.text,
    marginBottom: 8,
  },
  pickerWrap: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 12,
    backgroundColor: Colors.card,
    overflow: 'hidden',
  },
  picker: {
    height: Platform.OS === 'ios' ? 132 : 52,
  },
  pickerItem: {
    ...Typography.body,
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
