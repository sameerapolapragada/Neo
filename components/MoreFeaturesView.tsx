import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { MORE_FEATURES, type MoreFeatureItem } from '@/constants/moreFeatures';
import { AuthColors, AuthTypography } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

const PUPPY_IMAGE = require('@/assets/images/coming-soon-puppy.png');

interface MoreFeatureCardProps {
  feature: MoreFeatureItem;
}

function MoreFeatureCard({ feature }: MoreFeatureCardProps) {
  return (
    <View style={[styles.card, { backgroundColor: feature.backgroundColor }]}>
      <View style={styles.iconWrap}>
        {feature.icon === 'emoji' ? (
          <Text style={styles.emojiIcon}>{feature.emoji}</Text>
        ) : (
          <Ionicons name={feature.icon} size={26} color={feature.accentColor} />
        )}
      </View>

      <View style={styles.copy}>
        <Text style={styles.cardTitle}>{feature.title}</Text>
        <Text style={styles.cardSubtitle}>{feature.subtitle}</Text>
      </View>

      <View style={[styles.lockButton, { backgroundColor: feature.accentColor }]}>
        <Ionicons name="lock-closed" size={14} color={AuthColors.background} />
      </View>
    </View>
  );
}

interface MoreFeaturesViewProps {
  onBack: () => void;
}

export function MoreFeaturesView({ onBack }: MoreFeaturesViewProps) {
  return (
    <View style={styles.wrap}>
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Go back"
          onPress={onBack}
          style={({ pressed }) => [styles.sideButton, pressed && styles.pressed]}>
          <Ionicons name="arrow-back" size={22} color={AuthColors.text} />
        </Pressable>

        <Text style={styles.headerTitle}>More Features</Text>

        <View style={styles.sideButton} />
      </View>

      <View style={styles.list}>
        {MORE_FEATURES.map((feature) => (
          <MoreFeatureCard key={feature.id} feature={feature} />
        ))}
      </View>

      <View style={styles.footer}>
        <View style={styles.footerWave} />

        <View style={styles.footerDecor}>
          <Text style={[styles.footerAccent, styles.footerHeartOne]}>❤️</Text>
          <Text style={[styles.footerAccent, styles.footerFlower]}>🌼</Text>
          <Text style={[styles.footerDot, styles.footerDotOne]}>•</Text>
          <Text style={[styles.footerDot, styles.footerDotTwo]}>•</Text>
          <Text style={[styles.footerDot, styles.footerDotThree]}>•</Text>
        </View>

        <View style={styles.footerContent}>
          <Text style={styles.footerText}>
            We&apos;re building amazing features for you and your pet!
          </Text>

          <Image source={PUPPY_IMAGE} style={styles.puppy} contentFit="contain" />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    backgroundColor: AuthColors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  sideButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    ...AuthTypography.heading5,
    color: AuthColors.text,
  },
  pressed: {
    opacity: 0.72,
  },
  list: {
    gap: 12,
  },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 14,
    minHeight: 74,
  },
  iconWrap: {
    width: 42,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  emojiIcon: {
    fontSize: 28,
    lineHeight: 32,
  },
  copy: {
    flex: 1,
    gap: 2,
  },
  cardTitle: {
    ...AuthTypography.subheading,
    color: AuthColors.text,
  },
  cardSubtitle: {
    ...AuthTypography.subheadingSm,
    color: AuthColors.textMuted,
  },
  lockButton: {
    width: 34,
    height: 34,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: 8,
  },
  footer: {
    marginTop: 28,
    minHeight: 220,
    position: 'relative',
    overflow: 'hidden',
  },
  footerWave: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: AuthColors.surfaceWarm,
    borderTopLeftRadius: 120,
    borderTopRightRadius: 120,
    transform: [{ scaleX: 1.08 }],
  },
  footerDecor: {
    ...StyleSheet.absoluteFillObject,
  },
  footerAccent: {
    position: 'absolute',
    fontSize: 16,
  },
  footerHeartOne: {
    top: 28,
    left: 18,
  },
  footerFlower: {
    top: 72,
    left: 42,
    fontSize: 14,
  },
  footerDot: {
    position: 'absolute',
    fontSize: 16,
    color: AuthColors.primary,
    opacity: 0.45,
  },
  footerDotOne: {
    top: 18,
    left: 96,
    color: AuthColors.accentWarm,
  },
  footerDotTwo: {
    top: 54,
    right: 120,
    color: AuthColors.accent,
  },
  footerDotThree: {
    bottom: 72,
    left: 28,
    color: AuthColors.primary,
  },
  footerContent: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingTop: 34,
    paddingHorizontal: 18,
    paddingBottom: 8,
    gap: 8,
  },
  footerText: {
    flex: 1,
    fontSize: 18,
    lineHeight: 26,
    ...withAppFont('700'),
    color: AuthColors.text,
    paddingBottom: 18,
  },
  puppy: {
    width: 132,
    height: 156,
  },
});
