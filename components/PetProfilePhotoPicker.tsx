import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

const DEFAULT_AVATAR = require('@/assets/images/pet-profile-default.jpg');

interface PetProfilePhotoPickerProps {
  uri?: string;
  onPick: () => void;
}

export function PetProfilePhotoPicker({ uri, onPick }: PetProfilePhotoPickerProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Change pet photo"
        onPress={onPick}
        style={({ pressed }) => [styles.photoButton, pressed && styles.pressed]}>
        <Image
          source={uri ? { uri } : DEFAULT_AVATAR}
          style={styles.photo}
          contentFit="cover"
        />

        <View style={styles.cameraBadge}>
          <Ionicons name="camera-outline" size={16} color={AuthColors.onboardingTextMuted} />
        </View>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    marginBottom: 24,
  },
  photoButton: {
    width: 112,
    height: 112,
    borderRadius: 56,
    position: 'relative',
    overflow: 'visible',
  },
  photo: {
    width: '100%',
    height: '100%',
    borderRadius: 56,
  },
  cameraBadge: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: AuthColors.background,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 3,
    elevation: 2,
  },
  pressed: {
    opacity: 0.88,
  },
});
