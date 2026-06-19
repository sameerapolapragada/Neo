import { Ionicons } from '@expo/vector-icons';
import { withAppFont } from '@/constants/fonts';
import { useMemo, useState } from 'react';
import {
  Alert,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { WeightLineChart } from '@/components/WeightLineChart';
import { AuthColors, AuthShadow, AuthTypography } from '@/constants/authTheme';
import { formatWeight, toProfileDateIso } from '@/utils/petProfile';
import {
  buildWeightChartData,
  formatWeightEntryDate,
  getLatestWeightEntry,
  getWeightUnitFromEntries,
  sortWeightEntriesDesc,
} from '@/utils/weightTracker';
import type { Pet, WeightEntry, WeightUnit } from '@/types';

interface WeightTrackerViewProps {
  pet: Pet;
  entries: WeightEntry[];
  onBack: () => void;
  onAddWeight: (value: string, unit: WeightUnit, recordedAt: string) => Promise<void>;
  onDeleteEntry?: (entryId: string) => Promise<void>;
}

interface AddWeightModalProps {
  visible: boolean;
  unit: WeightUnit;
  saving: boolean;
  onClose: () => void;
  onSave: (value: string, recordedAt: string) => void;
}

function AddWeightModal({ visible, unit, saving, onClose, onSave }: AddWeightModalProps) {
  const [value, setValue] = useState('');
  const [recordedAt, setRecordedAt] = useState(toProfileDateIso(new Date()));

  function handleClose() {
    setValue('');
    setRecordedAt(toProfileDateIso(new Date()));
    onClose();
  }

  function handleSave() {
    const trimmed = value.trim();
    if (!/^\d+(\.\d+)?$/.test(trimmed)) {
      Alert.alert('Invalid weight', 'Enter a valid number for weight.');
      return;
    }

    onSave(trimmed, recordedAt);
    setValue('');
    setRecordedAt(toProfileDateIso(new Date()));
  }

  return (
    <Modal transparent visible={visible} animationType="fade">
      <Pressable style={styles.modalBackdrop} onPress={handleClose} />
      <View style={styles.modalCard}>
        <Text style={styles.modalTitle}>Add Weight</Text>

        <View style={styles.inputRow}>
          <TextInput
            value={value}
            onChangeText={setValue}
            keyboardType="decimal-pad"
            placeholder="0.0"
            placeholderTextColor={AuthColors.textMuted}
            style={styles.input}
          />
          <Text style={styles.unitLabel}>{unit}</Text>
        </View>

        <Text style={styles.fieldLabel}>Date</Text>
        <Text style={styles.dateValue}>{formatWeightEntryDate(recordedAt)}</Text>

        <View style={styles.modalActions}>
          <Pressable
            accessibilityRole="button"
            onPress={handleClose}
            style={({ pressed }) => [styles.modalButton, pressed && styles.pressed]}>
            <Text style={styles.cancelLabel}>Cancel</Text>
          </Pressable>

          <Pressable
            accessibilityRole="button"
            disabled={saving}
            onPress={handleSave}
            style={({ pressed }) => [
              styles.modalButton,
              styles.saveButton,
              saving && styles.disabled,
              pressed && !saving && styles.pressed,
            ]}>
            <Text style={styles.saveLabel}>{saving ? 'Saving...' : 'Save'}</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

export function WeightTrackerView({
  pet,
  entries,
  onBack,
  onAddWeight,
  onDeleteEntry,
}: WeightTrackerViewProps) {
  const [showAddModal, setShowAddModal] = useState(false);
  const [saving, setSaving] = useState(false);

  const sortedEntries = useMemo(() => sortWeightEntriesDesc(entries), [entries]);
  const latestEntry = useMemo(() => getLatestWeightEntry(entries), [entries]);
  const unit = useMemo(() => getWeightUnitFromEntries(entries, pet), [entries, pet]);
  const chartData = useMemo(() => buildWeightChartData(entries), [entries]);

  const currentWeight = latestEntry?.weight ?? pet.weight ?? '—';
  const currentDate = latestEntry
    ? formatWeightEntryDate(latestEntry.recorded_at)
    : pet.created_at
      ? formatWeightEntryDate(pet.created_at)
      : '—';

  function openMenu() {
    if (!latestEntry || !onDeleteEntry) {
      Alert.alert('Weight Tracker', 'Track weight over time to spot trends.');
      return;
    }

    Alert.alert('Weight Tracker', 'Manage your latest weight entry.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete Latest Entry',
        style: 'destructive',
        onPress: () => {
          Alert.alert('Delete entry?', 'This removes the latest weight reading.', [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Delete',
              style: 'destructive',
              onPress: () => onDeleteEntry(latestEntry.id),
            },
          ]);
        },
      },
    ]);
  }

  async function handleAddWeight(value: string, recordedAt: string) {
    setSaving(true);
    try {
      await onAddWeight(value, unit, recordedAt);
      setShowAddModal(false);
    } finally {
      setSaving(false);
    }
  }

  return (
    <View style={styles.wrap}>
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Go back"
          onPress={onBack}
          style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
          <Ionicons name="arrow-back" size={22} color={AuthColors.text} />
        </Pressable>

        <Text style={styles.headerTitle}>Weight Tracker</Text>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Weight tracker options"
          onPress={openMenu}
          style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
          <Ionicons name="ellipsis-vertical" size={20} color={AuthColors.text} />
        </Pressable>
      </View>

      <View style={styles.currentCard}>
        <View style={styles.currentCopy}>
          <Text style={styles.currentLabel}>Current Weight</Text>
          <Text style={styles.currentValue}>{currentWeight}</Text>
          <Text style={styles.currentDate}>{currentDate}</Text>
        </View>
      </View>

      <Pressable
        accessibilityRole="button"
        onPress={() => setShowAddModal(true)}
        style={({ pressed }) => [styles.addButton, pressed && styles.pressed]}>
        <View style={styles.addIconWrap}>
          <Ionicons name="add" size={16} color={AuthColors.background} />
        </View>
        <Text style={styles.addLabel}>Add Weight</Text>
      </Pressable>

      <Text style={styles.sectionTitle}>Weight History</Text>

      {entries.length > 0 ? (
        <>
          <WeightLineChart
            points={chartData.points}
            tickLabels={chartData.tickLabels}
            yMin={chartData.yMin}
            yMax={chartData.yMax}
            yStep={chartData.yStep}
          />

          <View style={styles.historyList}>
            {sortedEntries.map((entry, index) => (
              <View
                key={entry.id}
                style={[styles.historyRow, index < sortedEntries.length - 1 && styles.historyDivider]}>
                <Text style={styles.historyDate}>{formatWeightEntryDate(entry.recorded_at)}</Text>
                <Text style={styles.historyWeight}>{entry.weight}</Text>
              </View>
            ))}
          </View>
        </>
      ) : (
        <Text style={styles.emptyHistory}>No weight history yet. Add your first reading above.</Text>
      )}

      <AddWeightModal
        visible={showAddModal}
        unit={unit}
        saving={saving}
        onClose={() => setShowAddModal(false)}
        onSave={handleAddWeight}
      />
    </View>
  );
}

export const DEMO_WEIGHT_ENTRIES: Omit<WeightEntry, 'id' | 'pet_id' | 'created_at'>[] = [
  { weight: '40.5 lbs', recorded_at: '2024-03-01T12:00:00.000Z' },
  { weight: '41 lbs', recorded_at: '2024-04-01T12:00:00.000Z' },
  { weight: '41.5 lbs', recorded_at: '2024-05-01T12:00:00.000Z' },
  { weight: '42 lbs', recorded_at: '2024-05-28T12:00:00.000Z' },
];

const styles = StyleSheet.create({
  wrap: {
    paddingBottom: 8,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  sideButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
  },
  pressed: {
    opacity: 0.72,
  },
  currentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: AuthColors.border,
    borderRadius: 18,
    paddingHorizontal: 16,
    paddingVertical: 14,
    backgroundColor: AuthColors.card,
    marginBottom: 16,
  },
  currentCopy: {
    flex: 1,
    gap: 2,
  },
  currentLabel: {
    fontSize: 13,
    lineHeight: 18,
    color: AuthColors.textMuted,
  },
  currentValue: {
    fontSize: 28,
    lineHeight: 34,
    ...withAppFont('700'),
    color: AuthColors.text,
    marginTop: 2,
  },
  currentDate: {
    fontSize: 13,
    lineHeight: 18,
    color: AuthColors.textMuted,
    marginTop: 2,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    backgroundColor: AuthColors.primary,
    borderRadius: 999,
    minHeight: 52,
    marginBottom: 24,
  },
  addIconWrap: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: AuthColors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addLabel: {
    ...AuthTypography.button,
    color: AuthColors.background,
  },
  sectionTitle: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
    marginBottom: 4,
  },
  historyList: {
    marginTop: 18,
  },
  historyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
  },
  historyDivider: {
    borderBottomWidth: 1,
    borderBottomColor: AuthColors.border,
  },
  historyDate: {
    ...AuthTypography.body,
    color: AuthColors.text,
  },
  historyWeight: {
    ...AuthTypography.label,
    color: AuthColors.text,
  },
  emptyHistory: {
    ...AuthTypography.body,
    color: AuthColors.textMuted,
    marginTop: 8,
  },
  modalBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(45, 38, 64, 0.35)',
  },
  modalCard: {
    position: 'absolute',
    left: 24,
    right: 24,
    top: '34%',
    backgroundColor: AuthColors.card,
    borderRadius: 20,
    padding: 20,
    ...AuthShadow.card,
  },
  modalTitle: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
    marginBottom: 16,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: AuthColors.border,
    borderRadius: 14,
    paddingHorizontal: 14,
    marginBottom: 16,
  },
  input: {
    flex: 1,
    minHeight: 48,
    fontSize: 18,
    color: AuthColors.text,
  },
  unitLabel: {
    ...AuthTypography.label,
    color: AuthColors.textMuted,
  },
  fieldLabel: {
    fontSize: 13,
    color: AuthColors.textMuted,
    marginBottom: 4,
  },
  dateValue: {
    ...AuthTypography.body,
    color: AuthColors.text,
    marginBottom: 18,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
  },
  modalButton: {
    minHeight: 40,
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
  saveButton: {
    paddingHorizontal: 12,
  },
  cancelLabel: {
    ...AuthTypography.label,
    color: AuthColors.textMuted,
  },
  saveLabel: {
    ...AuthTypography.label,
    color: AuthColors.primary,
  },
  disabled: {
    opacity: 0.5,
  },
});
