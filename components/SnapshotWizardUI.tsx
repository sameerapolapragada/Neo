import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors, Radius, Typography } from '@/constants/theme';

interface SnapshotOptionButtonProps {
  label: string;
  selected: boolean;
  onPress: () => void;
}

export function SnapshotOptionButton({ label, selected, onPress }: SnapshotOptionButtonProps) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        selected && styles.buttonSelected,
        pressed && styles.pressed,
      ]}>
      <Text style={[styles.label, selected && styles.labelSelected]}>{label}</Text>
      {selected ? (
        <View style={styles.checkWrap}>
          <Ionicons name="checkmark" size={16} color={Colors.primaryDark} />
        </View>
      ) : null}
    </Pressable>
  );
}

interface SnapshotProgressBarProps {
  step: number;
  total: number;
}

export function SnapshotProgressBar({ step, total }: SnapshotProgressBarProps) {
  const progress = step / total;

  return (
    <View style={styles.progressWrap}>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${progress * 100}%` }]} />
      </View>
      <Text style={styles.counter}>
        {step} / {total}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 54,
    borderRadius: Radius.full,
    borderWidth: 1.5,
    borderColor: '#E8DDD3',
    backgroundColor: Colors.card,
    paddingHorizontal: 18,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  buttonSelected: {
    borderColor: Colors.primaryDark,
    backgroundColor: '#FFF9F7',
  },
  label: {
    ...Typography.body,
    color: Colors.text,
    flex: 1,
  },
  labelSelected: {
    color: Colors.primaryDark,
    fontWeight: '600',
  },
  checkWrap: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: Colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: 12,
  },
  pressed: {
    opacity: 0.9,
  },
  progressWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginTop: 8,
  },
  track: {
    flex: 1,
    height: 4,
    borderRadius: 999,
    backgroundColor: '#E8DDD3',
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    backgroundColor: Colors.primaryDark,
    borderRadius: 999,
  },
  counter: {
    ...Typography.caption,
    color: Colors.textSecondary,
    minWidth: 32,
    textAlign: 'right',
  },
});
