import { WELLNESS_METRIC_COUNT, WELLNESS_METRICS } from '@/constants/wellnessForm';
import type { WellnessCheckIn, WellnessRatings } from '@/types';

const MONTHS_SHORT = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const MONTHS_LONG = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

export function getWeekStart(date = new Date()): Date {
  const start = new Date(date);
  const day = start.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() + diff);
  return start;
}

export function toWeekStartIso(date = new Date()): string {
  return getWeekStart(date).toISOString().slice(0, 10);
}

export function formatWeekRange(weekStartIso: string): string {
  const start = new Date(`${weekStartIso}T12:00:00`);
  const end = new Date(start);
  end.setDate(end.getDate() + 6);

  const startLabel = `${MONTHS_LONG[start.getMonth()]} ${start.getDate()}`;
  const endLabel = `${MONTHS_LONG[end.getMonth()]} ${end.getDate()}`;

  return `Week of ${startLabel} – ${endLabel}`;
}

export function formatCheckInDate(isoDate: string): string {
  const date = new Date(`${isoDate.slice(0, 10)}T12:00:00`);
  return `${MONTHS_SHORT[date.getMonth()]} ${date.getDate()}`;
}

export function countCompletedRatings(ratings: WellnessRatings): number {
  return WELLNESS_METRICS.filter((metric) => ratings[metric.id] != null).length;
}

export function computeAverageScore(ratings: WellnessRatings): number {
  const values = WELLNESS_METRICS.map((metric) => ratings[metric.id]).filter(
    (value): value is number => value != null,
  );

  if (values.length === 0) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

export function computeWellnessProgress(ratings: WellnessRatings) {
  const completed = countCompletedRatings(ratings);
  const average = computeAverageScore(ratings);

  return {
    completed,
    total: WELLNESS_METRIC_COUNT,
    average,
    isComplete: completed === WELLNESS_METRIC_COUNT,
  };
}

export function summarizeCheckIn(ratings: WellnessRatings): string {
  const progress = computeWellnessProgress(ratings);

  if (progress.completed === 0) return 'Not started';
  if (!progress.isComplete) return 'In progress';

  if (progress.average >= 4.2) return 'All good';
  if (ratings.energy != null && ratings.energy <= 2) return 'Slight lethargy';
  if (ratings.appetite != null && ratings.appetite <= 2) return 'Low appetite';
  if (progress.average >= 3) return 'Doing okay';
  return 'Needs attention';
}

export function computeWellnessStreak(checkIns: WellnessCheckIn[], weekStartIso: string): number {
  const byWeek = new Map(
    checkIns.map((checkIn) => [checkIn.week_start.slice(0, 10), checkIn]),
  );

  let streak = 0;
  let cursor = new Date(`${weekStartIso}T12:00:00`);
  const currentKey = cursor.toISOString().slice(0, 10);
  const current = byWeek.get(currentKey);

  if (!current || countCompletedRatings(current.ratings) < WELLNESS_METRIC_COUNT) {
    cursor.setDate(cursor.getDate() - 7);
  }

  while (true) {
    const key = cursor.toISOString().slice(0, 10);
    const checkIn = byWeek.get(key);
    if (!checkIn || countCompletedRatings(checkIn.ratings) < WELLNESS_METRIC_COUNT) {
      break;
    }

    streak += 1;
    cursor.setDate(cursor.getDate() - 7);
  }

  return streak;
}

export function getPreviousWeekStarts(weekStartIso: string, count: number): string[] {
  const weeks: string[] = [];
  const cursor = new Date(`${weekStartIso}T12:00:00`);
  cursor.setDate(cursor.getDate() - 7);

  for (let index = 0; index < count; index += 1) {
    weeks.push(cursor.toISOString().slice(0, 10));
    cursor.setDate(cursor.getDate() - 7);
  }

  return weeks;
}
