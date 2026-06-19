import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { Colors, Typography } from '@/constants/theme';

interface ProfileScreenHeaderProps {
  title: string;
  onBack: () => void;
}

export function ProfileScreenHeader({ title, onBack }: ProfileScreenHeaderProps) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Go back"
        onPress={onBack}
        style={({ pressed }) => [styles.backButton, pressed && styles.pressed]}>
        <Ionicons name="chevron-back" size={24} color={Colors.text} />
      </Pressable>
      <Text style={styles.title}>{title}</Text>
      <View style={styles.spacer} />
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 8,
  },
  backButton: {
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
  spacer: {
    width: 44,
  },
  pressed: {
    opacity: 0.7,
  },
});
