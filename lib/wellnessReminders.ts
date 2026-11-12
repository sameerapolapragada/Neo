import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

import { WELLNESS_METRIC_COUNT } from '@/constants/wellnessForm';
import { countCompletedRatings, toWeekStartIso } from '@/utils/wellnessDate';
import type { Pet, WellnessCheckIn } from '@/types';

export const WELLNESS_REMINDER_ID = 'wellness-daily-check-in';

const ANDROID_CHANNEL_ID = 'wellness-reminders';
const REMINDER_HOUR = 9;
const REMINDER_MINUTE = 0;

let handlerConfigured = false;

export function configureWellnessNotifications() {
  if (handlerConfigured || Platform.OS === 'web') {
    return;
  }

  handlerConfigured = true;

  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowAlert: true,
      shouldPlaySound: true,
      shouldSetBadge: false,
      shouldShowBanner: true,
      shouldShowList: true,
    }),
  });
}

async function ensureAndroidChannel() {
  if (Platform.OS !== 'android') {
    return;
  }

  await Notifications.setNotificationChannelAsync(ANDROID_CHANNEL_ID, {
    name: 'Wellness reminders',
    importance: Notifications.AndroidImportance.DEFAULT,
  });
}

async function ensurePermissions(): Promise<boolean> {
  configureWellnessNotifications();
  await ensureAndroidChannel();

  const { status: existing } = await Notifications.getPermissionsAsync();
  if (existing === 'granted') {
    return true;
  }

  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

function isCurrentWeekCheckInComplete(checkIns: WellnessCheckIn[]): boolean {
  const weekStart = toWeekStartIso();
  const current = checkIns.find((checkIn) => checkIn.week_start.slice(0, 10) === weekStart);

  if (!current) {
    return false;
  }

  return countCompletedRatings(current.ratings) >= WELLNESS_METRIC_COUNT;
}

export async function syncWellnessCheckInReminder(
  pet: Pet | null,
  checkIns: WellnessCheckIn[],
): Promise<void> {
  if (Platform.OS === 'web') {
    return;
  }

  configureWellnessNotifications();

  try {
    await Notifications.cancelScheduledNotificationAsync(WELLNESS_REMINDER_ID);
  } catch {
    // No existing reminder to cancel.
  }

  if (!pet || isCurrentWeekCheckInComplete(checkIns)) {
    return;
  }

  const granted = await ensurePermissions();
  if (!granted) {
    return;
  }

  await Notifications.scheduleNotificationAsync({
    identifier: WELLNESS_REMINDER_ID,
    content: {
      title: 'Wellness check-in',
      body: `Take a moment to log how ${pet.name} has been this week.`,
      data: { url: '/(tabs)/moments' },
      ...(Platform.OS === 'android' ? { channelId: ANDROID_CHANNEL_ID } : {}),
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.DAILY,
      hour: REMINDER_HOUR,
      minute: REMINDER_MINUTE,
      ...(Platform.OS === 'android' ? { channelId: ANDROID_CHANNEL_ID } : {}),
    },
  });
}
