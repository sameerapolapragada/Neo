import type { WellnessMetricId } from '@/types';

import { AuthChartColors, AuthColors } from '@/constants/authTheme';
import type { ComponentProps } from 'react';
import type { Ionicons } from '@expo/vector-icons';

export const WELLNESS_METRIC_COUNT = 5;

export interface WellnessScaleStep {
  value: number;
  emoji: string;
  label?: string;
}

export interface WellnessMetricConfig {
  id: WellnessMetricId;
  title: string;
  emoji: string;
  scale: WellnessScaleStep[];
}

export interface WellnessMetricTheme {
  icon: ComponentProps<typeof Ionicons>['name'];
  iconBackground: string;
  iconColor: string;
  selected: string;
}

export const WELLNESS_METRIC_THEMES: Record<WellnessMetricId, WellnessMetricTheme> = {
  appetite: {
    icon: 'restaurant-outline',
    iconBackground: '#E8F5E9',
    iconColor: '#4CAF50',
    selected: AuthColors.primary,
  },
  energy: {
    icon: 'flash-outline',
    iconBackground: AuthColors.surfaceWarm,
    iconColor: AuthColors.accentWarm,
    selected: AuthColors.accentWarm,
  },
  mood: {
    icon: 'happy-outline',
    iconBackground: '#E8F0FE',
    iconColor: '#5B8DEF',
    selected: '#5B8DEF',
  },
  exercise: {
    icon: 'walk-outline',
    iconBackground: '#E8F0FE',
    iconColor: '#5B8DEF',
    selected: '#5B8DEF',
  },
  sleep: {
    icon: 'moon-outline',
    iconBackground: AuthColors.primarySoft,
    iconColor: AuthColors.primary,
    selected: AuthColors.primaryDark,
  },
};

export const WELLNESS_METRICS: WellnessMetricConfig[] = [
  {
    id: 'appetite',
    title: 'Appetite',
    emoji: '🦴',
    scale: [
      { value: 1, emoji: '😟', label: 'Not eating' },
      { value: 2, emoji: '😐' },
      { value: 3, emoji: '🙂' },
      { value: 4, emoji: '😊' },
      { value: 5, emoji: '🤩', label: 'Eating great' },
    ],
  },
  {
    id: 'energy',
    title: 'Energy',
    emoji: '⚡',
    scale: [
      { value: 1, emoji: '😴', label: 'Very tired' },
      { value: 2, emoji: '😢' },
      { value: 3, emoji: '🙂' },
      { value: 4, emoji: '😄' },
      { value: 5, emoji: '🚀', label: 'Full of life' },
    ],
  },
  {
    id: 'mood',
    title: 'Mood',
    emoji: '🐾',
    scale: [
      { value: 1, emoji: '😟', label: 'Not himself' },
      { value: 2, emoji: '😐' },
      { value: 3, emoji: '🙂' },
      { value: 4, emoji: '😊' },
      { value: 5, emoji: '🥰', label: 'Happy & playful' },
    ],
  },
  {
    id: 'exercise',
    title: 'Exercise',
    emoji: '🏃',
    scale: [
      { value: 1, emoji: '🛋️', label: 'Very little' },
      { value: 2, emoji: '🚶' },
      { value: 3, emoji: '🙂' },
      { value: 4, emoji: '🏃' },
      { value: 5, emoji: '🏅', label: 'Very active' },
    ],
  },
  {
    id: 'sleep',
    title: 'Sleep',
    emoji: '🌙',
    scale: [
      { value: 1, emoji: '😵‍💫', label: 'Restless' },
      { value: 2, emoji: '😬' },
      { value: 3, emoji: '😐' },
      { value: 4, emoji: '😌' },
      { value: 5, emoji: '😴', label: 'Sleeping well' },
    ],
  },
];

export const WELLNESS_CHART_COLORS: Record<WellnessMetricId, string> = {
  appetite: '#4CAF50',
  energy: AuthChartColors.energy,
  mood: AuthChartColors.mood,
  exercise: '#5B8DEF',
  sleep: AuthColors.primary,
};

export const WELLNESS_BAR_COLORS: Record<WellnessMetricId, string> = {
  appetite: WELLNESS_CHART_COLORS.appetite,
  energy: WELLNESS_CHART_COLORS.energy,
  mood: WELLNESS_CHART_COLORS.mood,
  exercise: WELLNESS_CHART_COLORS.exercise,
  sleep: WELLNESS_CHART_COLORS.sleep,
};

export const WELLNESS_INSIGHT_TINTS: Record<WellnessMetricId, string> = {
  appetite: '#E8F5E9',
  energy: '#FFF8E1',
  mood: '#F0EDF5',
  exercise: '#DDF7F3',
  sleep: '#F0EDF5',
};
