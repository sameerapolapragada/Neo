import { Image } from 'expo-image';
import { StyleSheet, Text, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';
import type { Pet } from '@/types';

interface HomePetHeaderProps {
  pet: Pet;
}

function formatAgeLabel(age: string): string {
  if (age.toLowerCase().includes('old')) return age;
  return `${age} old`;
}

export function HomePetHeader({ pet }: HomePetHeaderProps) {
  return (
    <View style={styles.row}>
      {pet.photo_uri ? (
        <Image source={{ uri: pet.photo_uri }} style={styles.photo} contentFit="cover" />
      ) : (
        <View style={[styles.photo, styles.photoPlaceholder]}>
          <Text style={styles.placeholderEmoji}>🐾</Text>
        </View>
      )}

      <View style={styles.info}>
        <View style={styles.nameRow}>
          <Text style={styles.name}>{pet.name}</Text>
          <Text style={styles.paw}>🐾</Text>
        </View>
        <Text style={styles.meta}>
          {pet.breed} • {formatAgeLabel(pet.age)}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    marginBottom: 22,
  },
  photo: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: '#ECE7E2',
  },
  photoPlaceholder: {
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
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  name: {
    ...Typography.title,
    color: Colors.text,
  },
  paw: {
    fontSize: 16,
    opacity: 0.7,
  },
  meta: {
    ...Typography.body,
    color: Colors.textSecondary,
  },
});
