import { AuthColors, AuthChartColors } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

export const Colors = {
  background: AuthColors.background,
  card: AuthColors.card,
  primary: AuthColors.primary,
  primaryDark: AuthColors.primaryDark,
  accent: AuthColors.accent,
  text: AuthColors.text,
  textSecondary: AuthColors.textSecondary,
  textMuted: AuthColors.textMuted,
  border: AuthColors.border,
  error: AuthColors.error,
  tabInactive: AuthColors.textMuted,
  disclaimerBg: AuthColors.surfaceWarm,
  snapshotBlue: AuthColors.accentViolet,
};

export { AuthChartColors as ChartColors };

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
  hero: { fontSize: 28, lineHeight: 34, ...withAppFont('700') },
  title: { fontSize: 22, lineHeight: 28, ...withAppFont('700') },
  subtitle: { fontSize: 18, lineHeight: 24, ...withAppFont('600') },
  heading1: { fontSize: 34, lineHeight: 38, ...withAppFont('700') },
  heading2: { fontSize: 28, lineHeight: 32, ...withAppFont('700') },
  heading3: { fontSize: 24, lineHeight: 30, ...withAppFont('700') },
  heading4: { fontSize: 20, lineHeight: 26, ...withAppFont('700') },
  heading5: { fontSize: 18, lineHeight: 24, ...withAppFont('700') },
  subheading: { fontSize: 16, lineHeight: 22, ...withAppFont('600') },
  subheadingSm: { fontSize: 14, lineHeight: 20, ...withAppFont('600') },
  body: { fontSize: 16, lineHeight: 22, ...withAppFont('400') },
  caption: { fontSize: 14, lineHeight: 20, ...withAppFont('400') },
  label: { fontSize: 14, lineHeight: 18, ...withAppFont('600') },
  button: { fontSize: 17, ...withAppFont('700') },
};

export const DISCLAIMER =
  'Neo creates lifestyle and memory suggestions only. It does not provide veterinary or medical advice.';

export const AGE_UNIT_OPTIONS = ['years', 'months'] as const;

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
  'Create a mini memory note',
  'Add a 5-minute enrichment game',
] as const;
