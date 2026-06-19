import { Image } from 'expo-image';
import { Ionicons } from '@expo/vector-icons';
import { Alert, Pressable, Platform, StyleSheet, Text, View } from 'react-native';
import { router } from 'expo-router';

import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';
import { formatHomePetMeta } from '@/utils/petProfile';
import type { Pet } from '@/types';

const DEFAULT_PHOTO = require('@/assets/images/pet-profile-default.jpg');

interface HomeEmptyHeaderProps {
  pet: Pet;
}

export function HomeEmptyHeader({ pet }: HomeEmptyHeaderProps) {
  function openQuickAdd() {
    Alert.alert('Quick Add', 'What would you like to add?', [
      { text: 'Photo Memory', onPress: () => router.push('/add-memory') },
      { text: 'Milestone', onPress: () => router.push('/add-memory?type=milestone') },
      { text: 'Cancel', style: 'cancel' },
    ]);
  }

  return (
    <View style={styles.wrap}>
      <View style={styles.identity}>
        <View style={styles.avatarWrap}>
          {pet.photo_uri ? (
            <Image source={{ uri: pet.photo_uri }} style={styles.avatar} contentFit="cover" />
          ) : (
            <Image source={DEFAULT_PHOTO} style={styles.avatar} contentFit="cover" />
          )}
          <View style={styles.statusDot} />
        </View>

        <View style={styles.copy}>
          <Text style={styles.name}>{pet.name}</Text>
          <Text style={styles.meta}>{formatHomePetMeta(pet)}</Text>
        </View>
      </View>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Quick add"
        onPress={openQuickAdd}
        style={({ pressed }) => [styles.quickAdd, pressed && styles.pressed]}>
        <Ionicons name="add" size={16} color={AuthColors.background} />
        <Text style={styles.quickAddLabel}>Quick Add</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
    marginBottom: 28,
  },
  identity: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 12,
    minWidth: 0,
  },
  avatarWrap: {
    position: 'relative',
  },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: AuthColors.surface,
  },
  statusDot: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: AuthColors.success,
    borderWidth: 2,
    borderColor: AuthColors.screenBackground,
  },
  copy: {
    flex: 1,
    minWidth: 0,
    gap: 2,
  },
  name: {
    fontSize: 22,
    lineHeight: 28,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  meta: {
    ...AuthTypography.body,
    fontSize: 14,
    lineHeight: 20,
    color: AuthColors.textMuted,
  },
  quickAdd: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: AuthColors.accent,
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
    ...Platform.select({
      ios: {
        shadowColor: AuthColors.accent,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
      },
      android: { elevation: 3 },
      default: {},
    }),
  },
  quickAddLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.9,
  },
});
