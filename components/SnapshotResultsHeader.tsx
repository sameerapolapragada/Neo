import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { Colors, Typography } from '@/constants/theme';

interface SnapshotResultsHeaderProps {
  onBack: () => void;
  onShare?: () => void;
}

export function SnapshotResultsHeader({ onBack, onShare }: SnapshotResultsHeaderProps) {
  return (
    <View style={styles.wrap}>
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Go back"
          onPress={onBack}
          style={({ pressed }) => [styles.iconButton, pressed && styles.pressed]}>
          <Ionicons name="chevron-back" size={24} color={Colors.text} />
        </Pressable>

        <Text style={styles.title}>Your Future Snapshot</Text>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Share snapshot"
          onPress={onShare}
          disabled={!onShare}
          style={({ pressed }) => [
            styles.iconButton,
            pressed && onShare ? styles.pressed : null,
            !onShare ? styles.iconDisabled : null,
          ]}>
          <Ionicons name="download-outline" size={22} color={Colors.text} />
        </Pressable>
      </View>

      <Text style={styles.subtitle}>These are moments you may create together.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 20,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 8,
  },
  iconButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconDisabled: {
    opacity: 0.35,
  },
  title: {
    ...Typography.subtitle,
    color: Colors.text,
    ...withAppFont('700'),
  },
  subtitle: {
    ...Typography.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    paddingHorizontal: 12,
  },
  pressed: {
    opacity: 0.7,
  },
});
