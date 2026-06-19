import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { Colors, Typography } from '@/constants/theme';

interface TimelineScreenHeaderProps {
  onFilter?: () => void;
}

export function TimelineScreenHeader({ onFilter }: TimelineScreenHeaderProps) {
  return (
    <View style={styles.header}>
      <View style={styles.spacer} />
      <Text style={styles.title}>Timeline</Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Filter timeline"
        onPress={onFilter}
        style={({ pressed }) => [styles.filterButton, pressed && styles.pressed]}>
        <Ionicons name="funnel-outline" size={22} color={Colors.text} />
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
  spacer: {
    width: 44,
  },
  title: {
    ...Typography.subtitle,
    color: Colors.text,
    ...withAppFont('700'),
  },
  filterButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: {
    opacity: 0.7,
  },
});
