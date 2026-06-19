import { StyleSheet, Text, View } from 'react-native';
import { AuthColors, AuthTypography } from '@/constants/authTheme';

export interface ProfileSectionRow {
  emoji?: string;
  label: string;
  value: string;
}

interface ProfileSectionCardProps {
  title: string;
  rows: ProfileSectionRow[];
  bodyText?: string;
}

export function ProfileSectionCard({ title, rows, bodyText }: ProfileSectionCardProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionLabel}>{title}</Text>
      <View style={styles.card}>
        {bodyText ? (
          <Text style={styles.bodyText}>{bodyText}</Text>
        ) : (
          rows.map((row, index) => (
            <View key={row.label}>
              <View style={styles.row}>
                {row.emoji ? <Text style={styles.emoji}>{row.emoji}</Text> : null}
                <Text style={styles.rowLabel}>{row.label}</Text>
                <Text style={styles.rowValue} numberOfLines={2}>
                  {row.value}
                </Text>
              </View>
              {index < rows.length - 1 ? <View style={styles.divider} /> : null}
            </View>
          ))
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: 18,
  },
  sectionLabel: {
    ...AuthTypography.eyebrow,
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    paddingVertical: 10,
    gap: 10,
  },
  emoji: {
    width: 24,
    fontSize: 16,
    textAlign: 'center',
  },
  rowLabel: {
    flex: 1,
    ...AuthTypography.body,
    fontSize: 15,
    color: AuthColors.textMuted,
  },
  rowValue: {
    maxWidth: '52%',
    ...AuthTypography.label,
    fontSize: 15,
    color: AuthColors.text,
    textAlign: 'right',
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.profileFieldBorder,
  },
  bodyText: {
    ...AuthTypography.body,
    fontSize: 15,
    color: AuthColors.text,
    paddingVertical: 14,
  },
});
