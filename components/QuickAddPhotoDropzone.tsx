import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddPhotoDropzoneProps {
  photoUri?: string;
  onPick: () => void;
}

export function QuickAddPhotoDropzone({ photoUri, onPick }: QuickAddPhotoDropzoneProps) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={photoUri ? 'Change photo' : 'Add photo'}
      onPress={onPick}
      style={({ pressed }) => [styles.wrap, pressed && styles.pressed]}>
      {photoUri ? (
        <>
          <Image source={{ uri: photoUri }} style={styles.photo} contentFit="cover" />
          <View style={styles.changeBadge}>
            <Text style={styles.changeText}>Tap to change photo</Text>
          </View>
        </>
      ) : (
        <View style={styles.empty}>
          <View style={styles.iconCircle}>
            <Ionicons name="camera-outline" size={22} color={AuthColors.quickAddAccent} />
          </View>
          <Text style={styles.title}>Add a Photo</Text>
          <Text style={styles.subtitle}>Tap to choose from library or camera</Text>
          <Text style={styles.emojis}>📷 🖼 🐾</Text>
        </View>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrap: {
    minHeight: 196,
    borderRadius: 18,
    borderWidth: 1.5,
    borderStyle: 'dashed',
    borderColor: AuthColors.profileFieldBorder,
    backgroundColor: AuthColors.quickAddField,
    overflow: 'hidden',
    marginBottom: 16,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingVertical: 28,
    gap: 8,
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: AuthColors.quickAddAccentSoft,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  title: {
    ...AuthTypography.subheading,
    color: AuthColors.text,
  },
  subtitle: {
    ...AuthTypography.subheadingSm,
    color: AuthColors.quickAddLabel,
    textAlign: 'center',
  },
  emojis: {
    fontSize: 18,
    marginTop: 4,
    letterSpacing: 6,
  },
  photo: {
    width: '100%',
    height: 196,
  },
  changeBadge: {
    position: 'absolute',
    left: 12,
    bottom: 12,
    backgroundColor: 'rgba(0,0,0,0.55)',
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  changeText: {
    ...AuthTypography.label,
    fontSize: 12,
    color: AuthColors.background,
  },
  pressed: {
    opacity: 0.94,
  },
});
