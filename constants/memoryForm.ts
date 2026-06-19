export const MEMORY_CATEGORIES = [
  { value: 'Memory' as const, icon: 'camera-outline' as const, emoji: '📷' },
  { value: 'Adventure' as const, icon: 'leaf-outline' as const, emoji: '🌿' },
  { value: 'Funny Moment' as const, icon: 'happy-outline' as const, emoji: '😄' },
  { value: 'Birthday' as const, icon: 'gift-outline' as const, emoji: '🎂' },
  { value: 'Favorite Thing' as const, icon: 'star-outline' as const, emoji: '⭐' },
];

export const SUGGESTED_MILESTONES = [
  { emoji: '🏠', label: 'First Day Home' },
  { emoji: '🎂', label: 'Birthday' },
  { emoji: '🎓', label: 'Training Achievement' },
  { emoji: '🐾', label: 'New Friend' },
  { emoji: '⭐', label: 'Special Moment' },
] as const;

export const MILESTONE_SENTIMENTS = [
  { emoji: '🥺', label: 'Emotional' as const },
  { emoji: '😊', label: 'Joyful' as const },
  { emoji: '😂', label: 'Hilarious' as const },
  { emoji: '🥰', label: 'Loving' as const },
  { emoji: '🤩', label: 'Proud' as const },
  { emoji: '😢', label: 'Bittersweet' as const },
] as const;

export const CAPTION_MAX_LENGTH = 280;
export const NOTES_MAX_LENGTH = 500;
