import { useEffect, useState } from 'react';
import { StyleSheet, Text, TextInput, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors } from '@/constants/authTheme';

interface ProfileVeterinarySectionProps {
  vetName?: string;
  vetClinic?: string;
  onSave: (fields: { vet_name?: string; vet_clinic?: string }) => Promise<void>;
}

interface EditableVetRowProps {
  emoji: string;
  label: string;
  value: string;
  placeholder: string;
  onChangeText: (value: string) => void;
  onBlur: () => void;
}

function EditableVetRow({
  emoji,
  label,
  value,
  placeholder,
  onChangeText,
  onBlur,
}: EditableVetRowProps) {
  return (
    <View style={styles.row}>
      <Text style={styles.emoji}>{emoji}</Text>
      <Text style={styles.rowLabel}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        onBlur={onBlur}
        placeholder={placeholder}
        placeholderTextColor={AuthColors.textMuted}
        style={styles.input}
        returnKeyType="done"
        blurOnSubmit
      />
    </View>
  );
}

export function ProfileVeterinarySection({
  vetName,
  vetClinic,
  onSave,
}: ProfileVeterinarySectionProps) {
  const [name, setName] = useState(vetName ?? '');
  const [clinic, setClinic] = useState(vetClinic ?? '');

  useEffect(() => {
    setName(vetName ?? '');
    setClinic(vetClinic ?? '');
  }, [vetName, vetClinic]);

  async function saveName(nextValue = name) {
    const trimmed = nextValue.trim();
    if (trimmed === (vetName ?? '').trim()) return;
    await onSave({ vet_name: trimmed || undefined });
  }

  async function saveClinic(nextValue = clinic) {
    const trimmed = nextValue.trim();
    if (trimmed === (vetClinic ?? '').trim()) return;
    await onSave({ vet_clinic: trimmed || undefined });
  }

  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>VETERINARY</Text>
      <View style={styles.card}>
        <EditableVetRow
          emoji="🏥"
          label="Vet"
          value={name}
          placeholder="Add vet name"
          onChangeText={setName}
          onBlur={() => saveName()}
        />
        <View style={styles.divider} />
        <EditableVetRow
          emoji="📍"
          label="Clinic"
          value={clinic}
          placeholder="Add clinic name"
          onChangeText={setClinic}
          onBlur={() => saveClinic()}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: 18,
  },
  sectionLabel: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    paddingVertical: 10,
    gap: 10,
  },
  emoji: {
    width: 24,
    fontSize: 16,
    textAlign: 'center',
  },
  rowLabel: {
    width: 56,
    fontSize: 15,
    color: AuthColors.textMuted,
  },
  input: {
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
    color: AuthColors.text,
    textAlign: 'right',
    paddingVertical: 0,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.profileFieldBorder,
  },
});
