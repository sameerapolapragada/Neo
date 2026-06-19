import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { formatPetHeroMeta } from '@/utils/profileStats';
import type { Pet } from '@/types';

const DEFAULT_PHOTO = require('@/assets/images/pet-profile-default.jpg');

interface ProfileHeroSectionProps {
  pet: Pet;
  onEdit: () => void;
}

export function ProfileHeroSection({ pet, onEdit }: ProfileHeroSectionProps) {
  return (
    <View style={styles.wrap}>
      <Image
        source={pet.photo_uri ? { uri: pet.photo_uri } : DEFAULT_PHOTO}
        style={styles.photo}
        contentFit="cover"
      />

      <View style={styles.overlay} />
      <View style={styles.bottomFade} />

      <View style={styles.topBar}>
        <View style={styles.brandRow}>
          <View style={styles.brandIcon}>
            <Ionicons name="heart" size={14} color={AuthColors.background} />
          </View>
          <Text style={styles.brandText}>Neo</Text>
        </View>
      </View>

      <View style={styles.heroCopy}>
        <View style={styles.titleBlock}>
          <Text style={styles.name}>{pet.name}</Text>
          <Text style={styles.meta}>{formatPetHeroMeta(pet)}</Text>
        </View>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Edit profile"
          onPress={onEdit}
          style={({ pressed }) => [styles.editButton, pressed && styles.pressed]}>
          <Ionicons name="pencil-outline" size={14} color={AuthColors.background} />
          <Text style={styles.editLabel}>Edit</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    minHeight: 300,
    position: 'relative',
    overflow: 'hidden',
  },
  photo: {
    ...StyleSheet.absoluteFillObject,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(45, 38, 64, 0.18)',
  },
  bottomFade: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '55%',
    backgroundColor: 'rgba(45, 38, 64, 0.42)',
  },
  topBar: {
    position: 'absolute',
    top: 8,
    left: 16,
    right: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  brandIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(45, 38, 64, 0.55)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  brandText: {
    ...AuthTypography.label,
    fontSize: 16,
    color: AuthColors.background,
  },
  heroCopy: {
    position: 'absolute',
    left: 20,
    right: 20,
    bottom: 28,
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    gap: 12,
  },
  titleBlock: {
    flex: 1,
  },
  name: {
    ...AuthTypography.heading2,
    color: AuthColors.background,
    marginBottom: 4,
  },
  meta: {
    ...AuthTypography.subheadingSm,
    color: 'rgba(255,255,255,0.92)',
  },
  editButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    minHeight: 34,
    paddingHorizontal: 14,
    borderRadius: 999,
    backgroundColor: 'rgba(45, 38, 64, 0.55)',
  },
  editLabel: {
    ...AuthTypography.label,
    fontSize: 14,
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.85,
  },
});
