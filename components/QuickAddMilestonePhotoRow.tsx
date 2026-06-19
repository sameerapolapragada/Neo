import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

const DEFAULT_PHOTO = require('@/assets/images/pet-profile-default.jpg');

interface QuickAddMilestonePhotoRowProps {
  photoUri?: string;
  onPress: () => void;
}

export function QuickAddMilestonePhotoRow({ photoUri, onPress }: QuickAddMilestonePhotoRowProps) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>Photo (Optional)</Text>

      <View style={styles.row}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={photoUri ? 'Change photo' : 'View photo'}
          onPress={onPress}
          style={({ pressed }) => [styles.photoSlot, pressed && styles.pressed]}>
          <Image
            source={photoUri ? { uri: photoUri } : DEFAULT_PHOTO}
            style={styles.photo}
            contentFit="cover"
          />
        </Pressable>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Add photo"
          onPress={onPress}
          style={({ pressed }) => [styles.addSlot, pressed && styles.pressed]}>
          <Ionicons name="camera-outline" size={24} color={AuthColors.onboardingTextMuted} />
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 16,
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: AuthColors.text,
    marginBottom: 10,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  photoSlot: {
    width: 92,
    height: 92,
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: AuthColors.surface,
  },
  photo: {
    width: '100%',
    height: '100%',
  },
  addSlot: {
    width: 92,
    height: 92,
    borderRadius: 14,
    borderWidth: 1.5,
    borderStyle: 'dashed',
    borderColor: AuthColors.profileFieldBorder,
    backgroundColor: AuthColors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: {
    opacity: 0.92,
  },
});
