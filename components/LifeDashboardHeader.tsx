import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';
import type { Pet } from '@/types';

interface LifeDashboardHeaderProps {
  pet: Pet;
  onQuickAdd: () => void;
}

export function LifeDashboardHeader({ pet, onQuickAdd }: LifeDashboardHeaderProps) {
  const weight = pet.weight ?? '—';

  return (
    <View style={styles.wrap}>
      <View style={styles.left}>
        <View style={styles.photoWrap}>
          {pet.photo_uri ? (
            <Image source={{ uri: pet.photo_uri }} style={styles.photo} contentFit="cover" />
          ) : (
            <View style={[styles.photo, styles.photoPlaceholder]}>
              <Text style={styles.photoEmoji}>🐾</Text>
            </View>
          )}
          <View style={styles.statusDot} />
        </View>

        <View style={styles.info}>
          <Text style={styles.name}>{pet.name}</Text>
          <Text style={styles.meta}>
            {pet.age} • {pet.breed}
          </Text>
          <View style={styles.weightRow}>
            <View style={styles.weightDot} />
            <Text style={styles.weight}>{weight}</Text>
          </View>
        </View>
      </View>

      <Pressable
        accessibilityRole="button"
        onPress={onQuickAdd}
        style={({ pressed }) => [styles.quickAdd, pressed && styles.pressed]}>
        <Ionicons name="add" size={16} color={AuthColors.background} />
        <Text style={styles.quickAddText}>Quick Add</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: 18,
    gap: 12,
  },
  left: {
    flexDirection: 'row',
    flex: 1,
    gap: 14,
  },
  photoWrap: {
    position: 'relative',
  },
  photo: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: AuthColors.surface,
  },
  photoPlaceholder: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoEmoji: {
    fontSize: 26,
  },
  statusDot: {
    position: 'absolute',
    right: 2,
    bottom: 2,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: AuthColors.primary,
    borderWidth: 2,
    borderColor: AuthColors.background,
  },
  info: {
    flex: 1,
    gap: 4,
  },
  name: {
    fontSize: 28,
    lineHeight: 32,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  meta: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.textMuted,
  },
  weightRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 2,
  },
  weightDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: AuthColors.primary,
  },
  weight: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.text,
    ...withAppFont('600'),
  },
  quickAdd: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: AuthColors.primary,
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
    marginTop: 4,
  },
  quickAddText: {
    ...AuthTypography.label,
    fontSize: 13,
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.88,
  },
});
