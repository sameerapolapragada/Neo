import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';

import { NeoWordmark } from '@/components/NeoWordmark';
import { AuthColors } from '@/constants/authTheme';

interface EmptyTimelineHeaderProps {
  onCalendarPress?: () => void;
  onNotificationsPress?: () => void;
  showCalendarCheck?: boolean;
}

export function EmptyTimelineHeader({
  onCalendarPress,
  onNotificationsPress,
  showCalendarCheck = true,
}: EmptyTimelineHeaderProps) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Open calendar"
        onPress={onCalendarPress}
        style={({ pressed }) => [styles.side, pressed && styles.pressed]}>
        {showCalendarCheck ? (
          <View style={styles.calendarWrap}>
            <Ionicons name="calendar-outline" size={22} color={AuthColors.text} />
            <View style={styles.calendarCheck}>
              <Ionicons name="checkmark" size={8} color={AuthColors.background} />
            </View>
          </View>
        ) : (
          <Ionicons name="calendar-outline" size={22} color={AuthColors.text} />
        )}
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
    marginBottom: 16,
  },
  side: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  calendarWrap: {
    width: 28,
    height: 28,
    alignItems: 'center',
    justifyContent: 'center',
  },
  calendarCheck: {
    position: 'absolute',
    right: -1,
    bottom: -1,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: AuthColors.onboardingPrimary,
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
