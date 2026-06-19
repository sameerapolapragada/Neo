import { WELLNESS_METRICS } from '@/constants/wellnessForm';
import type { WellnessCheckIn, WellnessMetricId } from '@/types';

import { computeAverageScore, computeWellnessProgress, countCompletedRatings, formatCheckInDate } from './wellnessDate';

export type WellnessHistoryRange = 'weekly' | 'monthly' | 'yearly';

export interface WellnessMetricPoint {
  weekStart: string;
  value: number;
}

export interface WellnessMetricInsight {
  id: WellnessMetricId;
  title: string;
  emoji: string;
  status: string;
  delta: number;
  points: WellnessMetricPoint[];
}

const MONTHS_SHORT = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export function getCompleteCheckIns(checkIns: WellnessCheckIn[]): WellnessCheckIn[] {
  return checkIns
    .filter((checkIn) => computeWellnessProgress(checkIn.ratings).isComplete)
    .sort(
      (a, b) =>
        new Date(a.week_start).getTime() - new Date(b.week_start).getTime(),
    );
}

export function getRecentCompleteCheckIns(
  checkIns: WellnessCheckIn[],
  count = 8,
): WellnessCheckIn[] {
  return checkIns
    .filter((checkIn) => countCompletedRatings(checkIn.ratings) > 0)
    .sort(
      (a, b) =>
        new Date(a.week_start).getTime() - new Date(b.week_start).getTime(),
    )
    .slice(-count);
}

export function getMetricPoints(
  checkIns: WellnessCheckIn[],
  metricId: WellnessMetricId,
  count = 8,
): WellnessMetricPoint[] {
  return getRecentCompleteCheckIns(checkIns, count)
    .map((checkIn) => ({
      weekStart: checkIn.week_start,
      value: checkIn.ratings[metricId] ?? 0,
    }))
    .filter((point) => point.value > 0);
}

export function getMetricAverage(
  checkIns: WellnessCheckIn[],
  metricId: WellnessMetricId,
  count = 8,
): number {
  const points = getMetricPoints(checkIns, metricId, count);
  if (points.length === 0) return 0;
  return points.reduce((sum, point) => sum + point.value, 0) / points.length;
}

export function getOverallAverage(checkIns: WellnessCheckIn[], count = 8): number {
  const recent = getRecentCompleteCheckIns(checkIns, count);
  if (recent.length === 0) return 0;

  const total = recent.reduce((sum, checkIn) => sum + computeAverageScore(checkIn.ratings), 0);
  return total / recent.length;
}

export function getOverallDelta(checkIns: WellnessCheckIn[], count = 8): number {
  const recent = getRecentCompleteCheckIns(checkIns, count);
  if (recent.length < 2) return 0;

  const first = computeAverageScore(recent[0].ratings);
  const last = computeAverageScore(recent[recent.length - 1].ratings);
  return last - first;
}

export function getMetricDelta(checkIns: WellnessCheckIn[], metricId: WellnessMetricId): number {
  const points = getMetricPoints(checkIns, metricId);
  if (points.length < 2) return 0;
  return points[points.length - 1].value - points[points.length - 2].value;
}

export function getMetricLatestValue(
  checkIns: WellnessCheckIn[],
  metricId: WellnessMetricId,
): number | null {
  const points = getMetricPoints(checkIns, metricId);
  if (points.length === 0) return null;
  return points[points.length - 1].value;
}

export function getMetricTrendLabel(delta: number): string {
  if (delta > 0.4) return 'Improving';
  if (delta < -0.4) return 'Declining';
  if (Math.abs(delta) <= 0.1) return 'Stable';
  return 'Consistent';
}

export function formatTrendDelta(delta: number): string {
  const rounded = Math.abs(delta).toFixed(1);
  if (delta > 0) return `+${rounded}`;
  if (delta < 0) return `-${rounded}`;
  return '+0.0';
}

export function formatVsLast(delta: number): string {
  const arrow = delta > 0 ? '↑' : delta < 0 ? '↓' : '↑';
  return `${arrow} ${Math.abs(delta).toFixed(0)} vs last`;
}

export function formatChartDateLabel(weekStart: string): string {
  const date = new Date(`${weekStart.slice(0, 10)}T12:00:00`);
  return `${MONTHS_SHORT[date.getMonth()]} ${date.getDate()}`;
}

export function formatChartDateRange(checkIns: WellnessCheckIn[], count = 8): string {
  const recent = getRecentCompleteCheckIns(checkIns, count);
  if (recent.length === 0) return 'No data yet';

  const start = formatChartDateLabel(recent[0].week_start);
  const end = formatChartDateLabel(recent[recent.length - 1].week_start);
  return `${start} – ${end}`;
}

export function buildMetricInsights(checkIns: WellnessCheckIn[]): WellnessMetricInsight[] {
  return WELLNESS_METRICS.map((metric) => {
    const points = getMetricPoints(checkIns, metric.id);
    const delta =
      points.length >= 2
        ? points[points.length - 1].value - points[0].value
        : getMetricDelta(checkIns, metric.id);

    return {
      id: metric.id,
      title: metric.title,
      emoji: metric.emoji,
      status: getMetricTrendLabel(delta),
      delta,
      points,
    };
  });
}

export function getChartTickLabels(checkIns: WellnessCheckIn[], count = 4): string[] {
  const recent = getRecentCompleteCheckIns(checkIns, 8);
  if (recent.length === 0) return [];

  if (recent.length <= count) {
    return recent.map((checkIn) => formatChartDateLabel(checkIn.week_start));
  }

  const step = (recent.length - 1) / (count - 1);
  return Array.from({ length: count }, (_, index) => {
    const checkIn = recent[Math.round(index * step)];
    return formatChartDateLabel(checkIn.week_start);
  });
}

export function getWeekCountLabel(checkIns: WellnessCheckIn[]): string {
  const count = getRecentCompleteCheckIns(checkIns, 8).length;
  if (count === 0) return '0 weeks';
  if (count === 1) return '1 week';
  return `${count} weeks`;
}

export function hasWellnessHistory(checkIns: WellnessCheckIn[]): boolean {
  return checkIns.some((checkIn) => countCompletedRatings(checkIn.ratings) > 0);
}

function startOfDay(date: Date): Date {
  const normalized = new Date(date);
  normalized.setHours(0, 0, 0, 0);
  return normalized;
}

function endOfDay(date: Date): Date {
  const normalized = new Date(date);
  normalized.setHours(23, 59, 59, 999);
  return normalized;
}

export function getPeriodStart(range: WellnessHistoryRange, offset = 0): Date {
  const now = new Date();

  if (range === 'weekly') {
    const start = startOfDay(now);
    const day = start.getDay();
    start.setDate(start.getDate() - day + offset * 7);
    return start;
  }

  if (range === 'monthly') {
    return new Date(now.getFullYear(), now.getMonth() + offset, 1);
  }

  return new Date(now.getFullYear() + offset, 0, 1);
}

export function getPeriodEnd(range: WellnessHistoryRange, offset = 0): Date {
  const start = getPeriodStart(range, offset);

  if (range === 'weekly') {
    const end = new Date(start);
    end.setDate(end.getDate() + 6);
    return endOfDay(end);
  }

  if (range === 'monthly') {
    return endOfDay(new Date(start.getFullYear(), start.getMonth() + 1, 0));
  }

  return endOfDay(new Date(start.getFullYear(), 11, 31));
}

export function filterCheckInsForPeriod(
  checkIns: WellnessCheckIn[],
  range: WellnessHistoryRange,
  offset = 0,
): WellnessCheckIn[] {
  const start = getPeriodStart(range, offset);
  const end = getPeriodEnd(range, offset);

  return checkIns
    .filter((checkIn) => {
      const date = new Date(`${checkIn.week_start.slice(0, 10)}T12:00:00`);
      return date >= start && date <= end && countCompletedRatings(checkIn.ratings) > 0;
    })
    .sort(
      (a, b) =>
        new Date(a.week_start).getTime() - new Date(b.week_start).getTime(),
    );
}

export function formatPeriodLabel(range: WellnessHistoryRange, offset = 0): string {
  const start = getPeriodStart(range, offset);

  if (range === 'monthly') {
    return start.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  }

  if (range === 'yearly') {
    return String(start.getFullYear());
  }

  const end = getPeriodEnd(range, offset);
  const startLabel = start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  const endLabel = end.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  return `${startLabel} – ${endLabel}`;
}

export function getPeriodChartTickLabels(
  range: WellnessHistoryRange,
  offset = 0,
): string[] {
  if (range === 'monthly') {
    const start = getPeriodStart('monthly', offset);
    const month = MONTHS_SHORT[start.getMonth()];
    const daysInMonth = new Date(start.getFullYear(), start.getMonth() + 1, 0).getDate();
    return [1, 8, 15, 22, 29]
      .filter((day) => day <= daysInMonth)
      .map((day) => `${month} ${day}`);
  }

  if (range === 'yearly') {
    return ['Jan', 'Apr', 'Jul', 'Oct', 'Dec'];
  }

  const start = getPeriodStart('weekly', offset);
  return Array.from({ length: 5 }, (_, index) => {
    const date = new Date(start);
    date.setDate(start.getDate() + index);
    return formatChartDateLabel(date.toISOString());
  });
}

export function formatInsightDate(checkIns: WellnessCheckIn[]): string {
  const recent = getRecentCompleteCheckIns(checkIns, 1);
  if (recent.length === 0) return '';
  return formatCheckInDate(recent[recent.length - 1].week_start);
}
