import { formatProfileDate, parseWeight, parseWeightUnit } from '@/utils/petProfile';
import type { Pet, WeightEntry, WeightUnit } from '@/types';

export function getWeightNumericValue(weight: string): number {
  const parsed = parseFloat(parseWeight(weight));
  return Number.isFinite(parsed) ? parsed : 0;
}

export function formatWeightEntryDate(iso: string): string {
  return formatProfileDate(iso);
}

export function formatWeightChartMonth(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString('en-US', { month: 'short' });
}

export function sortWeightEntriesDesc(entries: WeightEntry[]): WeightEntry[] {
  return [...entries].sort(
    (a, b) => new Date(b.recorded_at).getTime() - new Date(a.recorded_at).getTime(),
  );
}

export function sortWeightEntriesAsc(entries: WeightEntry[]): WeightEntry[] {
  return [...entries].sort(
    (a, b) => new Date(a.recorded_at).getTime() - new Date(b.recorded_at).getTime(),
  );
}

export function getLatestWeightEntry(entries: WeightEntry[]): WeightEntry | null {
  const sorted = sortWeightEntriesDesc(entries);
  return sorted[0] ?? null;
}

export function getWeightUnitFromEntries(entries: WeightEntry[], pet?: Pet | null): WeightUnit {
  const latest = getLatestWeightEntry(entries);
  if (latest) return parseWeightUnit(latest.weight);
  return parseWeightUnit(pet?.weight);
}

export function buildWeightChartData(entries: WeightEntry[]): {
  points: number[];
  tickLabels: string[];
  yMin: number;
  yMax: number;
  yStep: number;
} {
  const sorted = sortWeightEntriesAsc(entries);
  const values = sorted.map((entry) => getWeightNumericValue(entry.weight));

  if (values.length === 0) {
    return { points: [], tickLabels: [], yMin: 30, yMax: 45, yStep: 5 };
  }

  const minValue = Math.min(...values);
  const maxValue = Math.max(...values);
  const padding = 2;
  const rawMin = Math.floor((minValue - padding) / 5) * 5;
  const rawMax = Math.ceil((maxValue + padding) / 5) * 5;
  const yMin = Math.max(0, rawMin);
  const yMax = Math.max(yMin + 5, rawMax);
  const yStep = 5;

  const tickLabels = sorted.map((entry) => formatWeightChartMonth(entry.recorded_at));

  return { points: values, tickLabels, yMin, yMax, yStep };
}

export function createInitialWeightEntry(pet: Pet): Omit<WeightEntry, 'id' | 'created_at'> {
  return {
    pet_id: pet.id,
    weight: pet.weight ?? '0 lbs',
    recorded_at: pet.created_at,
  };
}
