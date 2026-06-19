import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { Colors, Typography } from '@/constants/theme';

interface MemoryPhotoPickerProps {
  photoUris: string[];
  onPick: () => void;
  onRemove: (uri: string) => void;
}

export function MemoryPhotoPicker({ photoUris, onPick, onRemove }: MemoryPhotoPickerProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Add photos"
        onPress={onPick}
        style={({ pressed }) => [styles.uploadArea, pressed && styles.pressed]}>
        <Ionicons name="camera-outline" size={28} color={Colors.textMuted} />
        <Text style={styles.uploadLabel}>Add Photos (optional)</Text>
      </Pressable>

      {photoUris.length > 0 ? (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.thumbnailRow}>
          {photoUris.map((uri) => (
            <View key={uri} style={styles.thumbnailWrap}>
              <Image source={{ uri }} style={styles.thumbnail} contentFit="cover" />
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Remove photo"
                onPress={() => onRemove(uri)}
                style={({ pressed }) => [styles.removeButton, pressed && styles.pressed]}>
                <Ionicons name="close" size={12} color={Colors.text} />
              </Pressable>
            </View>
          ))}

          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Add more photos"
            onPress={onPick}
            style={({ pressed }) => [styles.addButton, pressed && styles.pressed]}>
            <Ionicons name="add" size={24} color={Colors.textSecondary} />
          </Pressable>
        </ScrollView>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 24,
  },
  uploadArea: {
    minHeight: 120,
    borderWidth: 1.5,
    borderColor: '#DDD5CC',
    borderStyle: 'dashed',
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.card,
    gap: 8,
  },
  uploadLabel: {
    ...Typography.body,
    color: Colors.textSecondary,
  },
  thumbnailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginTop: 12,
    paddingRight: 4,
  },
  thumbnailWrap: {
    position: 'relative',
  },
  thumbnail: {
    width: 72,
    height: 72,
    borderRadius: 14,
    backgroundColor: Colors.disclaimerBg,
  },
  removeButton: {
    position: 'absolute',
    top: -6,
    right: -6,
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addButton: {
    width: 72,
    height: 72,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#DDD5CC',
    backgroundColor: Colors.card,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: {
    opacity: 0.85,
  },
});
