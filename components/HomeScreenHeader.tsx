import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';

import { NeoWordmark } from '@/components/NeoWordmark';
import { AuthColors } from '@/constants/authTheme';

interface HomeScreenHeaderProps {
  onMenuPress?: () => void;
  onNotificationsPress?: () => void;
}

export function HomeScreenHeader({
  onMenuPress,
  onNotificationsPress,
}: HomeScreenHeaderProps) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Open menu"
        onPress={onMenuPress}
        style={({ pressed }) => [styles.side, pressed && styles.pressed]}>
        <Ionicons name="menu-outline" size={24} color={AuthColors.text} />
      </Pressable>

      <NeoWordmark size="small" variant="onboarding" />

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Notifications"
        onPress={onNotificationsPress}
        style={({ pressed }) => [styles.side, styles.bellButton, pressed && styles.pressed]}>
        <Ionicons name="notifications-outline" size={22} color={AuthColors.text} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  side: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bellButton: {
    alignItems: 'flex-end',
  },
  pressed: {
    opacity: 0.7,
  },
});
