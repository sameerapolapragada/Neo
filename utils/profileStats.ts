import {
  computeAgeFromBirthday,
  formatMicrochipNumber,
  formatProfileDate,
  parseWeight,
  parseWeightUnit,
} from '@/utils/petProfile';
import {
  getLatestWeightEntry,
  getWeightNumericValue,
  sortWeightEntriesAsc,
  sortWeightEntriesDesc,
} from '@/utils/weightTracker';
import type { Memory, Pet, WellnessCheckIn, WeightEntry } from '@/types';

function kgToLbs(kg: number): number {
  return kg * 2.20462;
}

function lbsToKg(lbs: number): number {
  return lbs / 2.20462;
}

export function formatShortAge(pet: Pet): string {
  if (pet.birthday) {
    const computed = computeAgeFromBirthday(pet.birthday);
    const match = computed.match(/^(\d+)\s+(year|month)/i);
    if (match) {
      const unit = match[2].toLowerCase().startsWith('month') ? 'mo' : 'yr';
      const suffix = match[1] === '1' && unit === 'yr' ? '' : 's';
      return `${match[1]} ${unit}${suffix}`;
    }
  }

  const trimmed = pet.age.replace(/\s*old\s*$/i, '').trim();
  return trimmed.replace(/\byears?\b/i, 'yrs').replace(/\bmonths?\b/i, 'mos');
}

export function formatSinceLabel(adoptionDate?: string, createdAt?: string): string {
  const iso = adoptionDate || createdAt;
  if (!iso) return '—';

  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '—';

  const month = date.toLocaleDateString('en-US', { month: 'short' });
  const year = date.toLocaleDateString('en-US', { year: '2-digit' });
  return `${month} '${year}`;
}

export function formatDualWeight(weight?: string): string {
  if (!weight?.trim()) return '—';

  const value = parseFloat(parseWeight(weight));
  if (!Number.isFinite(value)) return weight;

  const unit = parseWeightUnit(weight);
  if (unit === 'lbs') {
    const kg = lbsToKg(value);
    return `${kg.toFixed(1)} kg / ${value.toFixed(1)} lbs`;
  }

  const lbs = kgToLbs(value);
  return `${value.toFixed(1)} kg / ${lbs.toFixed(1)} lbs`;
}

export function formatWeightTrend(entries: WeightEntry[]): string | null {
  const sorted = sortWeightEntriesAsc(entries);
  if (sorted.length < 2) return null;

  const now = new Date();
  const sixMonthsAgo = new Date(now);
  sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

  const recent = sorted.filter((entry) => new Date(entry.recorded_at) >= sixMonthsAgo);
  const data = recent.length >= 2 ? recent : sorted.slice(0, 2);

  const first = getWeightNumericValue(data[0].weight);
  const last = getWeightNumericValue(data[data.length - 1].weight);
  const delta = last - first;
  const unit = parseWeightUnit(data[data.length - 1].weight);
  const sign = delta >= 0 ? '+' : '';

  return `${sign}${delta.toFixed(1)} ${unit} over 6 months`;
}

export function getProfileWeightValue(entries: WeightEntry[], pet: Pet): string {
  const latest = getLatestWeightEntry(entries);
  if (latest) {
    const value = parseWeight(latest.weight);
    const unit = parseWeightUnit(latest.weight);
    return `${value} ${unit}`;
  }

  return pet.weight ?? '—';
}

export function getWeightSparklinePoints(entries: WeightEntry[]): number[] {
  return sortWeightEntriesAsc(entries).map((entry) => getWeightNumericValue(entry.weight));
}

export function countMemories(memories: Memory[]): number {
  return memories.filter((memory) => memory.entry_type !== 'milestone').length;
}

export function countMilestones(memories: Memory[]): number {
  return memories.filter((memory) => memory.entry_type === 'milestone').length;
}

export function countCheckIns(checkIns: WellnessCheckIn[]): number {
  return checkIns.length;
}

export function formatPetSubtitle(pet: Pet): string {
  const age = formatShortAge(pet);
  return `${pet.breed} · ${age.replace(/\s*yrs?\b/i, (match) => (match.includes('yr') ? ' years' : match))}`;
}

export function formatPetHeroMeta(pet: Pet): string {
  const ageLabel = pet.birthday ? computeAgeFromBirthday(pet.birthday) : pet.age;
  const normalizedAge = ageLabel.replace(/\byears?\b/i, 'years').replace(/\bmonths?\b/i, 'months');
  return `${pet.breed} · ${normalizedAge}`;
}

export function formatBioPlaceholder(pet: Pet): string {
  return `${pet.name} is a gentle soul with a big heart. Add a bio in Edit Profile to share their story.`;
}

export function formatVetField(value?: string | null): string {
  return value?.trim() ? value.trim() : 'Not set';
}

export { formatMicrochipNumber, formatProfileDate };
