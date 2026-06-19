import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddScreenHeaderProps {
  title: string;
  onBack: () => void;
}

export function QuickAddScreenHeader({ title, onBack }: QuickAddScreenHeaderProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Go back"
        onPress={onBack}
        style={({ pressed }) => [styles.side, pressed && styles.pressed]}>
        <Ionicons name="arrow-back" size={22} color={AuthColors.text} />
      </Pressable>

      <Text style={styles.title}>{title}</Text>

      <View style={styles.side} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  side: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    ...AuthTypography.heading4,
    color: AuthColors.text,
    textAlign: 'center',
  },
  pressed: {
    opacity: 0.7,
  },
});
