import type { WeightUnit } from '@/types';

export type AgeUnit = 'years' | 'months';

export function parseAge(age: string): { value: string; unit: AgeUnit } {
  const trimmed = age.trim();
  const match = trimmed.match(/^(\d+(?:\.\d+)?)\s*(years?|months?)?/i);

  if (!match) {
    return { value: trimmed.replace(/[^\d.]/g, ''), unit: 'years' };
  }

  const unit: AgeUnit = match[2]?.toLowerCase().startsWith('month') ? 'months' : 'years';
  return { value: match[1], unit };
}

export function computeAgeFromBirthday(birthdayIso: string): string {
  const birthday = new Date(birthdayIso);
  if (Number.isNaN(birthday.getTime())) return '';

  const now = new Date();
  let months =
    (now.getFullYear() - birthday.getFullYear()) * 12 + (now.getMonth() - birthday.getMonth());

  if (now.getDate() < birthday.getDate()) {
    months -= 1;
  }

  if (months < 0) {
    months = 0;
  }

  if (months < 24) {
    return `${months} months`;
  }

  const years = Math.floor(months / 12);
  return `${years} years`;
}

export function parseWeight(weight: string): string {
  return weight.replace(/[^\d.]/g, '');
}

export function parseWeightUnit(weight?: string): WeightUnit {
  return weight?.toLowerCase().includes('lbs') ? 'lbs' : 'kg';
}

export function formatWeight(value: string, unit: WeightUnit = 'kg'): string | undefined {
  const trimmed = value.trim();
  if (!trimmed) return undefined;
  return `${trimmed} ${unit}`;
}

export function formatDetailedAge(pet: { age: string; birthday?: string }): string {
  if (pet.birthday) {
    const birthday = new Date(pet.birthday);
    if (!Number.isNaN(birthday.getTime())) {
      const now = new Date();
      let totalMonths =
        (now.getFullYear() - birthday.getFullYear()) * 12 + (now.getMonth() - birthday.getMonth());

      if (now.getDate() < birthday.getDate()) {
        totalMonths -= 1;
      }

      if (totalMonths < 0) {
        totalMonths = 0;
      }

      const years = Math.floor(totalMonths / 12);
      const months = totalMonths % 12;
      const yearLabel = years > 0 ? `${years} Year${years === 1 ? '' : 's'}` : '';
      const monthLabel = months > 0 ? `${months} Month${months === 1 ? '' : 's'}` : '';

      if (yearLabel && monthLabel) {
        return `${yearLabel}, ${monthLabel}`;
      }

      if (yearLabel) {
        return yearLabel;
      }

      if (monthLabel) {
        return monthLabel;
      }

      return '0 Months';
    }
  }

  return pet.age
    .replace(/\s*old\s*$/i, '')
    .trim()
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

export function formatHomePetMeta(pet: { age: string; birthday?: string; breed: string }): string {
  let ageLabel = pet.age.replace(/\s*old\s*$/i, '').trim().toLowerCase();

  if (pet.birthday) {
    const computed = computeAgeFromBirthday(pet.birthday);
    if (computed) {
      ageLabel = computed;
    }
  }

  return `${ageLabel} · ${pet.breed}`;
}

export function formatProfileDate(iso: string): string {
  if (!iso) return 'Select date';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return 'Select date';

  return date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

export function formatProfileDateShort(iso: string): string {
  if (!iso) return '—';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '—';

  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export function formatMicrochipNumber(value?: string): string {
  if (!value?.trim()) return '—';

  const digits = value.replace(/\D/g, '');
  if (digits.length === 15) {
    return `${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6, 9)} ${digits.slice(9, 12)} ${digits.slice(12)}`;
  }

  return value.trim();
}

export function toProfileDateIso(date: Date): string {
  const normalized = new Date(date);
  normalized.setHours(12, 0, 0, 0);
  return normalized.toISOString();
}
