import { StyleSheet, Text, View } from 'react-native';

import { AuthColors } from '@/constants/authTheme';
import { withAppFont } from '@/constants/fonts';

export function QuickAddMilestoneHeader() {
  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>RECORD A MILESTONE</Text>
      <Text style={styles.title}>New Milestone</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginBottom: 20,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1,
    color: AuthColors.textMuted,
    marginBottom: 8,
  },
  title: {
    fontSize: 34,
    lineHeight: 38,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
});
