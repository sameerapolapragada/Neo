import { Image } from 'expo-image';
import { StyleSheet, Text, useWindowDimensions, View } from 'react-native';

const ILLUSTRATION = require('@/assets/images/empty-timeline-sleeping-puppy.png');

const DECORATIONS = [
  { glyph: '🐾', top: '8%', left: '12%', size: 18, rotate: '-12deg' },
  { glyph: '🐾', top: '18%', right: '10%', size: 16, rotate: '10deg' },
  { glyph: '🐾', top: '42%', left: '8%', size: 14, rotate: '8deg' },
  { glyph: '🐾', top: '50%', right: '14%', size: 15, rotate: '-8deg' },
  { glyph: '♡', top: '14%', left: '28%', size: 14 },
  { glyph: '♡', top: '28%', right: '24%', size: 12 },
  { glyph: '♡', top: '46%', left: '22%', size: 13 },
] as const;

export function EmptyTimelineIllustration() {
  const { width } = useWindowDimensions();
  const imageWidth = width;
  const imageHeight = imageWidth * (682 / 340);
  const cropTop = imageHeight * 0.13;
  const frameHeight = imageHeight * 0.36;

  return (
    <View style={[styles.wrap, { height: frameHeight }]}>
      {DECORATIONS.map((item, index) => (
        <Text
          key={index}
          style={[
            styles.decor,
            {
              fontSize: item.size,
              top: item.top,
              left: 'left' in item ? item.left : undefined,
              right: 'right' in item ? item.right : undefined,
              transform: 'rotate' in item ? [{ rotate: item.rotate }] : undefined,
            },
          ]}>
          {item.glyph}
        </Text>
      ))}

      <View style={[styles.imageClip, { height: frameHeight }]}>
        <Image
          source={ILLUSTRATION}
          style={{
            width: imageWidth,
            height: imageHeight,
            marginTop: -cropTop,
          }}
          contentFit="cover"
          accessibilityLabel="Sleeping golden retriever puppy"
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    width: '100%',
    position: 'relative',
    alignItems: 'center',
    marginBottom: 8,
  },
  decor: {
    position: 'absolute',
    color: '#D8CFC0',
    zIndex: 1,
  },
  imageClip: {
    width: '100%',
    overflow: 'hidden',
    alignItems: 'center',
  },
});
