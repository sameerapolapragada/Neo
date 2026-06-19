import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { Colors, Typography } from '@/constants/theme';

interface MemoryFormHeaderProps {
  onBack: () => void;
  onSave: () => void;
  saving?: boolean;
}

export function MemoryFormHeader({ onBack, onSave, saving }: MemoryFormHeaderProps) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Go back"
        onPress={onBack}
        style={({ pressed }) => [styles.iconButton, pressed && styles.pressed]}>
        <Ionicons name="chevron-back" size={24} color={Colors.text} />
      </Pressable>

      <Text style={styles.title}>Add Memory</Text>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Save memory"
        onPress={onSave}
        disabled={saving}
        style={({ pressed }) => [styles.saveButton, pressed && !saving && styles.pressed]}>
        <Text style={[styles.saveText, saving && styles.saveTextDisabled]}>
          {saving ? 'Saving...' : 'Save'}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 12,
  },
  iconButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    ...Typography.subtitle,
    color: Colors.text,
    ...withAppFont('700'),
  },
  saveButton: {
    minWidth: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 4,
  },
  saveText: {
    ...Typography.label,
    fontSize: 16,
    color: Colors.primary,
  },
  saveTextDisabled: {
    opacity: 0.5,
  },
  pressed: {
    opacity: 0.7,
  },
});
