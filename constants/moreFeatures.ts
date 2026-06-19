import type { ComponentProps } from 'react';
import type { Ionicons } from '@expo/vector-icons';

type IconName = ComponentProps<typeof Ionicons>['name'];

export interface MoreFeatureItem {
  id: string;
  title: string;
  subtitle: string;
  description: string;
  backgroundColor: string;
  accentColor: string;
  icon: IconName | 'emoji';
  emoji?: string;
}

export const MORE_FEATURES: MoreFeatureItem[] = [
  {
    id: 'health-records',
    title: 'Health Records',
    subtitle: 'Coming Soon',
    description: 'Full medical history',
    backgroundColor: '#FFF0F2',
    accentColor: '#F06B7A',
    icon: 'heart',
  },
  {
    id: 'vaccinations',
    title: 'Vaccinations',
    subtitle: 'Coming Soon',
    description: 'Track and schedule shots',
    backgroundColor: '#EEF5FF',
    accentColor: '#4A8FE7',
    icon: 'emoji',
    emoji: '💉',
  },
  {
    id: 'medications',
    title: 'Medications',
    subtitle: 'Coming Soon',
    description: 'Dosage reminders',
    backgroundColor: '#F0EDF5',
    accentColor: '#7A6E99',
    icon: 'emoji',
    emoji: '💊',
  },
  {
    id: 'vet-visits',
    title: 'Vet Visits',
    subtitle: 'Coming Soon',
    description: 'Appointment log',
    backgroundColor: '#F0EDF5',
    accentColor: '#7A6E99',
    icon: 'medkit',
  },
  {
    id: 'pet-biography',
    title: 'Pet Biography',
    subtitle: 'Coming Soon',
    description: 'Life story',
    backgroundColor: '#FFF4DA',
    accentColor: '#E18E09',
    icon: 'document-text',
  },
];

export const COMING_SOON_FEATURES = MORE_FEATURES;
