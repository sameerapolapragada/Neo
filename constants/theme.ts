export const Colors = {
  background: '#FFF8F3',
  card: '#FFFFFF',
  primary: '#E8876A',
  primaryDark: '#D06B4F',
  accent: '#7BAE7F',
  text: '#3D2C2C',
  textSecondary: '#8B7355',
  textMuted: '#B5A090',
  border: '#F0E4DA',
  error: '#D64545',
  tabInactive: '#C4B5A5',
  disclaimerBg: '#FFF3E8',
};

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const Radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 999,
};

export const Typography = {
  hero: { fontSize: 28, fontWeight: '700' as const, lineHeight: 34 },
  title: { fontSize: 22, fontWeight: '700' as const, lineHeight: 28 },
  subtitle: { fontSize: 18, fontWeight: '600' as const, lineHeight: 24 },
  body: { fontSize: 16, fontWeight: '400' as const, lineHeight: 22 },
  caption: { fontSize: 14, fontWeight: '400' as const, lineHeight: 20 },
  label: { fontSize: 14, fontWeight: '600' as const, lineHeight: 18 },
};

export const DISCLAIMER =
  'Neo creates lifestyle and memory suggestions only. It does not provide veterinary or medical advice.';

export const SPECIES_OPTIONS = [
  'Dog',
  'Cat',
  'Rabbit',
  'Bird',
  'Guinea Pig',
  'Other',
] as const;

export const FREQUENCY_OPTIONS = [
  'Daily',
  'Several times a week',
  'Weekly',
  'A few times a month',
  'Rarely',
] as const;

export const WEEKLY_SUGGESTIONS = [
  'Take one new photo',
  'Try one new walking route',
  'Add one memory note',
  'Try a 5-minute enrichment game',
] as const;
