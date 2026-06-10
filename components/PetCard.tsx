import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { Card } from '@/components/SafeScreen';
import { Colors, Typography } from '@/constants/theme';
import { useResponsive } from '@/hooks/useResponsive';
import type { Pet } from '@/types';

interface PetCardProps {
  pet: Pet;
  compact?: boolean;
}

export function PetCard({ pet, compact = false }: PetCardProps) {
  const { photoSize, isSmall } = useResponsive();
  const size = compact ? photoSize - 16 : photoSize;

  return (
    <Card style={compact ? styles.compact : undefined}>
      <View style={styles.row}>
        {pet.photo_uri ? (
          <Image source={{ uri: pet.photo_uri }} style={[styles.photo, { width: size, height: size }]} contentFit="cover" />
        ) : (
          <View style={[styles.photo, styles.photoPlaceholder, { width: size, height: size }]}>
            <Text style={styles.placeholderEmoji}>🐾</Text>
          </View>
        )}
        <View style={styles.info}>
          <Text style={[styles.name, isSmall && styles.nameSmall]}>{pet.name}</Text>
          <Text style={styles.meta}>
            {pet.species} · {pet.breed}
          </Text>
          {!compact ? (
            <Text style={styles.meta}>
              Age {pet.age}
              {pet.weight ? ` · ${pet.weight}` : ''}
            </Text>
          ) : null}
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  compact: {
    padding: 12,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  photo: {
    borderRadius: 16,
  },
  photoPlaceholder: {
    backgroundColor: Colors.disclaimerBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderEmoji: {
    fontSize: 28,
  },
  info: {
    flex: 1,
    gap: 4,
  },
  name: {
    ...Typography.subtitle,
    color: Colors.text,
  },
  nameSmall: {
    fontSize: 16,
    lineHeight: 22,
  },
  meta: {
    ...Typography.caption,
    color: Colors.textSecondary,
  },
});
