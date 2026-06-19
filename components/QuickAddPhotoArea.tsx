import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

const DEFAULT_PHOTO = require('@/assets/images/add-memory-default.jpg');

interface QuickAddPhotoAreaProps {
  photoUri?: string;
  onPick: () => void;
}

export function QuickAddPhotoArea({ photoUri, onPick }: QuickAddPhotoAreaProps) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={photoUri ? 'Change photo' : 'Add photo'}
      onPress={onPick}
      style={({ pressed }) => [styles.wrap, pressed && styles.pressed]}>
      <Image
        source={photoUri ? { uri: photoUri } : DEFAULT_PHOTO}
        style={styles.photo}
        contentFit="cover"
      />

      <View style={styles.overlay}>
        <View style={styles.cameraCircle}>
          <Ionicons name="camera" size={15} color={AuthColors.background} />
        </View>
        <Text style={styles.overlayText}>Tap to change photo</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrap: {
    height: 220,
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 20,
    position: 'relative',
  },
  photo: {
    width: '100%',
    height: '100%',
  },
  overlay: {
    position: 'absolute',
    left: 12,
    bottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.55)',
    borderRadius: 999,
    paddingLeft: 6,
    paddingRight: 14,
    paddingVertical: 6,
  },
  cameraCircle: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: 'rgba(0, 0, 0, 0.35)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  overlayText: {
    ...AuthTypography.label,
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.94,
  },
});
