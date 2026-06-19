import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import { Typography } from '@/constants/theme';

export type MomentCardVariant = 'created' | 'missing' | 'suggestions';

const VARIANT_CONFIG = {
  created: {
    backgroundColor: AuthColors.accentSoft,
    titleColor: AuthColors.accent,
    markerColor: AuthColors.success,
    illustration: '🐕',
    marker: 'check' as const,
  },
  missing: {
    backgroundColor: AuthColors.primarySoft,
    titleColor: AuthColors.primaryDark,
    markerColor: AuthColors.primary,
    illustration: '💭',
    marker: 'dot' as const,
  },
  suggestions: {
    backgroundColor: AuthColors.accentSoft,
    titleColor: AuthColors.accentDark,
    markerColor: AuthColors.accent,
    illustration: '📋',
    marker: 'dot' as const,
  },
};

interface MomentCardProps {
  title: string;
  items: string[];
  variant: MomentCardVariant;
}

export function MomentCard({ title, items, variant }: MomentCardProps) {
  const config = VARIANT_CONFIG[variant];

  return (
    <View style={[styles.card, { backgroundColor: config.backgroundColor }]}>
      <View style={styles.content}>
        <Text style={[styles.title, { color: config.titleColor }]}>{title}</Text>

        {items.map((item) => (
          <View key={item} style={styles.row}>
            {config.marker === 'check' ? (
              <Ionicons name="checkmark-circle" size={18} color={config.markerColor} />
            ) : (
              <View style={[styles.dot, { backgroundColor: config.markerColor }]} />
            )}
            <Text style={styles.item}>{item}</Text>
          </View>
        ))}
      </View>

      <View style={styles.artWrap}>
        <Text style={styles.artEmoji}>{config.illustration}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 22,
    padding: 18,
    marginBottom: 16,
    flexDirection: 'row',
    overflow: 'hidden',
    minHeight: 148,
  },
  content: {
    flex: 1,
    paddingRight: 72,
  },
  title: {
    ...Typography.subtitle,
    marginBottom: 12,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 8,
    gap: 10,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginTop: 7,
  },
  item: {
    ...Typography.body,
    color: AuthColors.text,
    flex: 1,
    lineHeight: 22,
  },
  artWrap: {
    position: 'absolute',
    right: 10,
    bottom: 8,
    width: 72,
    height: 72,
    alignItems: 'center',
    justifyContent: 'center',
  },
  artEmoji: {
    fontSize: 44,
  },
});
