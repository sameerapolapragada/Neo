import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors } from '@/constants/authTheme';

export interface ProfileRecordRow {
  label: string;
  detail: string;
  onPress?: () => void;
}

interface ProfileRecordsSectionProps {
  rows: ProfileRecordRow[];
}

export function ProfileRecordsSection({ rows }: ProfileRecordsSectionProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>RECORDS</Text>
      <View style={styles.card}>
        {rows.map((row, index) => (
          <View key={row.label}>
            <Pressable
              accessibilityRole={row.onPress ? 'button' : undefined}
              disabled={!row.onPress}
              onPress={row.onPress}
              style={({ pressed }) => [styles.row, row.onPress && pressed && styles.pressed]}>
              <Text style={styles.rowLabel}>{row.label}</Text>
              <View style={styles.rowRight}>
                <Text style={styles.rowDetail}>{row.detail}</Text>
                {row.onPress ? (
                  <Ionicons name="chevron-forward" size={16} color={AuthColors.textMuted} />
                ) : null}
              </View>
            </Pressable>
            {index < rows.length - 1 ? <View style={styles.divider} /> : null}
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: 18,
  },
  sectionLabel: {
    fontSize: 11,
    ...withAppFont('700'),
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    minHeight: 54,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  rowLabel: {
    fontSize: 16,
    fontWeight: '700',
    color: AuthColors.text,
  },
  rowRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  rowDetail: {
    fontSize: 14,
    color: AuthColors.textMuted,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.profileFieldBorder,
    marginHorizontal: 16,
  },
  pressed: {
    opacity: 0.88,
  },
});
