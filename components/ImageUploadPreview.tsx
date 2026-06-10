import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { PrimaryButton } from '@/components/PrimaryButton';
import { Card } from '@/components/SafeScreen';
import { Colors, Radius, Typography } from '@/constants/theme';
import { useResponsive } from '@/hooks/useResponsive';

interface ImageUploadPreviewProps {
  uri?: string;
  onPick: () => void;
  onRemove?: () => void;
  pickLabel?: string;
  changeLabel?: string;
  hint?: string;
  size?: number;
  aspect?: 'square' | 'wide';
}

export function ImageUploadPreview({
  uri,
  onPick,
  onRemove,
  pickLabel = 'Upload Photo',
  changeLabel = 'Change Photo',
  hint = 'Add a photo',
  size,
  aspect = 'square',
}: ImageUploadPreviewProps) {
  const { photoSize, width: screenWidth, horizontalPadding } = useResponsive();
  const previewSize = size ?? photoSize;
  const wideWidth = Math.min(screenWidth - horizontalPadding * 2 - 32, 360);
  const wideHeight = Math.round(wideWidth * 0.75);

  return (
    <Card style={styles.card}>
      {uri ? (
        <View style={styles.previewWrap}>
          <Image
            source={{ uri }}
            style={[
              styles.preview,
              aspect === 'square'
                ? { width: previewSize, height: previewSize, borderRadius: Radius.xl }
                : { width: wideWidth, height: wideHeight, borderRadius: Radius.lg },
            ]}
            contentFit="cover"
            accessibilityLabel="Selected photo preview"
          />
          <View style={styles.actions}>
            <PrimaryButton title={changeLabel} variant="outline" onPress={onPick} />
            {onRemove ? (
              <Pressable
                accessibilityRole="button"
                onPress={onRemove}
                style={({ pressed }) => [styles.removeButton, pressed && styles.pressed]}>
                <Text style={styles.removeText}>Remove Photo</Text>
              </Pressable>
            ) : null}
          </View>
        </View>
      ) : (
        <Pressable
          accessibilityRole="button"
          onPress={onPick}
          style={({ pressed }) => [
            styles.placeholder,
            aspect === 'square'
              ? { width: previewSize, height: previewSize, borderRadius: Radius.xl }
              : { width: wideWidth, height: wideHeight, borderRadius: Radius.lg },
            pressed && styles.pressed,
          ]}>
          <Text style={styles.emoji}>📷</Text>
          <Text style={styles.hint}>{hint}</Text>
        </Pressable>
      )}

      {!uri ? <PrimaryButton title={pickLabel} variant="outline" onPress={onPick} /> : null}
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  previewWrap: {
    alignItems: 'center',
    gap: 12,
    width: '100%',
  },
  preview: {
    backgroundColor: Colors.disclaimerBg,
  },
  placeholder: {
    backgroundColor: Colors.disclaimerBg,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.border,
    borderStyle: 'dashed',
  },
  emoji: {
    fontSize: 32,
  },
  hint: {
    ...Typography.caption,
    color: Colors.textSecondary,
    marginTop: 6,
  },
  actions: {
    width: '100%',
    gap: 8,
  },
  removeButton: {
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  removeText: {
    ...Typography.label,
    color: Colors.error,
  },
  pressed: {
    opacity: 0.85,
  },
});
