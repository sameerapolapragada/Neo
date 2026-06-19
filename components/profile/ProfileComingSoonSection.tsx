import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { COMING_SOON_FEATURES } from '@/constants/moreFeatures';
import { AuthColors } from '@/constants/authTheme';

interface ProfileComingSoonSectionProps {
  petName: string;
}

export function ProfileComingSoonSection({ petName }: ProfileComingSoonSectionProps) {
  return (
    <View style={styles.section}>
      <View style={styles.headerRow}>
        <Text style={styles.sectionLabel}>COMING SOON</Text>
        <View style={styles.headerLine} />
        <View style={styles.lockedBadge}>
          <Text style={styles.lockedText}>Locked</Text>
        </View>
      </View>

      <View style={styles.card}>
        {COMING_SOON_FEATURES.map((feature, index) => {
          const subtitle =
            feature.id === 'pet-biography'
              ? `${petName}'s life story`
              : feature.description;

          return (
            <View key={feature.id}>
              <View style={styles.row}>
                <View style={styles.left}>
                  {feature.icon === 'emoji' ? (
                    <Text style={styles.emoji}>{feature.emoji}</Text>
                  ) : (
                    <Ionicons name={feature.icon} size={20} color={feature.accentColor} />
                  )}
                  <View style={styles.copy}>
                    <Text style={styles.title}>{feature.title}</Text>
                    <Text style={styles.subtitle}>{subtitle}</Text>
                  </View>
                </View>
                <Ionicons name="lock-closed-outline" size={16} color={AuthColors.textMuted} />
              </View>
              {index < COMING_SOON_FEATURES.length - 1 ? <View style={styles.divider} /> : null}
            </View>
          );
        })}
      </View>

      <Text style={styles.footerNote}>More features on the way — stay tuned.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: 18,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 10,
  },
  sectionLabel: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
  },
  headerLine: {
    flex: 1,
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.profileFieldBorder,
  },
  lockedBadge: {
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
    backgroundColor: AuthColors.quickAddField,
  },
  lockedText: {
    fontSize: 11,
    fontWeight: '700',
    color: AuthColors.textMuted,
  },
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
    opacity: 0.92,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    minHeight: 58,
    paddingVertical: 10,
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
    paddingRight: 12,
  },
  emoji: {
    fontSize: 20,
    width: 24,
    textAlign: 'center',
  },
  copy: {
    flex: 1,
    gap: 2,
  },
  title: {
    fontSize: 15,
    ...withAppFont('700'),
    color: AuthColors.textMuted,
  },
  subtitle: {
    fontSize: 13,
    color: AuthColors.textMuted,
    opacity: 0.85,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.profileFieldBorder,
  },
  footerNote: {
    marginTop: 12,
    textAlign: 'center',
    fontSize: 13,
    color: AuthColors.quickAddLabel,
  },
});
