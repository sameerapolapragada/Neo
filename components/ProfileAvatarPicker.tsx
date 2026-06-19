import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Colors } from '@/constants/theme';

interface ProfileAvatarPickerProps {
  uri?: string;
  onPick: () => void;
  size?: number;
}

export function ProfileAvatarPicker({ uri, onPick, size = 148 }: ProfileAvatarPickerProps) {
  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Change pet photo"
        onPress={onPick}
        style={({ pressed }) => [styles.avatarPressable, pressed && styles.pressed]}>
        {uri ? (
          <Image source={{ uri }} style={[styles.avatar, { width: size, height: size }]} contentFit="cover" />
        ) : (
          <View style={[styles.avatar, styles.placeholder, { width: size, height: size }]}>
            <Text style={styles.placeholderEmoji}>🐶</Text>
          </View>
        )}
        <View style={styles.cameraButton}>
          <Ionicons name="camera" size={18} color={Colors.text} />
        </View>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    marginBottom: 28,
  },
  avatarPressable: {
    position: 'relative',
  },
  avatar: {
    borderRadius: 999,
    backgroundColor: '#ECE7E2',
  },
  placeholder: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderEmoji: {
    fontSize: 56,
  },
  cameraButton: {
    position: 'absolute',
    right: 6,
    bottom: 6,
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: Colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.border,
    shadowColor: '#3D2C2C',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  pressed: {
    opacity: 0.92,
  },
});
