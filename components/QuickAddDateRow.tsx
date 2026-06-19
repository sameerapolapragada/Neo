import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors, AuthTypography } from '@/constants/authTheme';

interface QuickAddDateRowProps {
  value: string;
  onPress: () => void;
}

export function QuickAddDateRow({ value, onPress }: QuickAddDateRowProps) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.wrap, pressed && styles.pressed]}>
      <View style={styles.iconCircle}>
        <Ionicons name="calendar-outline" size={20} color={AuthColors.quickAddAccent} />
      </View>

      <View style={styles.copy}>
        <Text style={styles.label}>DATE</Text>
        <Text style={styles.value}>{value}</Text>
      </View>

      <Ionicons name="chevron-forward" size={18} color={AuthColors.quickAddLabel} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: AuthColors.quickAddField,
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 14,
    marginBottom: 20,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: AuthColors.quickAddAccentSoft,
    alignItems: 'center',
    justifyContent: 'center',
  },
  copy: {
    flex: 1,
    gap: 2,
  },
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.1,
    color: AuthColors.quickAddLabel,
  },
  value: {
    ...AuthTypography.body,
    fontSize: 15,
    ...withAppFont('600'),
    color: AuthColors.text,
  },
  pressed: {
    opacity: 0.92,
  },
});
