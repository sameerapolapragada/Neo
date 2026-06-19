import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddMilestonePhotoFieldProps {
  photoUri?: string;
  onPress: () => void;
}

export function QuickAddMilestonePhotoField({ photoUri, onPress }: QuickAddMilestonePhotoFieldProps) {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>Photo (Optional)</Text>

      <Pressable
        accessibilityRole="button"
        accessibilityLabel={photoUri ? 'Change photo' : 'Add photo'}
        onPress={onPress}
        style={({ pressed }) => [styles.field, pressed && styles.pressed]}>
        {photoUri ? (
          <>
            <Image source={{ uri: photoUri }} style={styles.thumbnail} contentFit="cover" />
            <View style={styles.copy}>
              <Text style={styles.title}>Photo added</Text>
              <Text style={styles.subtitle}>Tap to change photo</Text>
            </View>
          </>
        ) : (
          <>
            <View style={styles.iconCircle}>
              <Ionicons name="camera-outline" size={20} color={AuthColors.quickAddAccent} />
            </View>
            <View style={styles.copy}>
              <Text style={styles.title}>Add a Photo</Text>
              <Text style={styles.subtitle}>Capture the moment visually</Text>
            </View>
          </>
        )}
        <Ionicons name="chevron-forward" size={18} color={AuthColors.quickAddLabel} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 16,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderWidth: 1.5,
    borderStyle: 'dashed',
    borderColor: AuthColors.profileFieldBorder,
    borderRadius: 16,
    backgroundColor: AuthColors.quickAddField,
    paddingHorizontal: 14,
    paddingVertical: 16,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: AuthColors.quickAddAccentSoft,
    alignItems: 'center',
    justifyContent: 'center',
  },
  thumbnail: {
    width: 40,
    height: 40,
    borderRadius: 10,
  },
  copy: {
    flex: 1,
    gap: 2,
  },
  title: {
    ...AuthTypography.subheading,
    color: AuthColors.text,
  },
  subtitle: {
    ...AuthTypography.subheadingSm,
    color: AuthColors.quickAddLabel,
  },
  pressed: {
    opacity: 0.94,
  },
});
