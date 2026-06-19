import { Pressable, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import type { WellnessMetricConfig } from '@/constants/wellnessForm';
import { AuthColors } from '@/constants/authTheme';

interface WellnessMetricCardProps {
  metric: WellnessMetricConfig;
  value?: number;
  onChange: (value: number) => void;
}

export function WellnessMetricCard({ metric, value, onChange }: WellnessMetricCardProps) {
  const lowLabel = metric.scale[0]?.label;
  const highLabel = metric.scale[metric.scale.length - 1]?.label;

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.emoji}>{metric.emoji}</Text>
        <Text style={styles.title}>{metric.title}</Text>
      </View>

      <View style={styles.scaleRow}>
        {metric.scale.map((step) => {
          const selected = value === step.value;

          return (
            <Pressable
              key={step.value}
              accessibilityRole="button"
              accessibilityState={{ selected }}
              onPress={() => onChange(step.value)}
              style={({ pressed }) => [styles.stepCol, pressed && styles.pressed]}>
              <Text style={styles.stepEmoji}>{step.emoji}</Text>
              <View style={[styles.stepBadge, selected && styles.stepBadgeSelected]}>
                <Text style={[styles.stepNumber, selected && styles.stepNumberSelected]}>
                  {step.value}
                </Text>
              </View>
            </Pressable>
          );
        })}
      </View>

      {lowLabel || highLabel ? (
        <View style={styles.labelRow}>
          <Text style={styles.edgeLabel}>{lowLabel ?? ''}</Text>
          <Text style={styles.edgeLabel}>{highLabel ?? ''}</Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: AuthColors.background,
    borderRadius: 18,
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 14,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: AuthColors.profileFieldBorder,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 14,
  },
  emoji: {
    fontSize: 18,
  },
  title: {
    fontSize: 17,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  scaleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 4,
  },
  stepCol: {
    flex: 1,
    alignItems: 'center',
    gap: 6,
  },
  stepEmoji: {
    fontSize: 16,
    height: 20,
  },
  stepBadge: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: AuthColors.quickAddField,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepBadgeSelected: {
    backgroundColor: AuthColors.onboardingPrimary,
  },
  stepNumber: {
    fontSize: 13,
    fontWeight: '700',
    color: AuthColors.quickAddLabel,
  },
  stepNumberSelected: {
    color: AuthColors.background,
  },
  labelRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 10,
    paddingHorizontal: 2,
  },
  edgeLabel: {
    fontSize: 11,
    color: AuthColors.quickAddLabel,
    maxWidth: '42%',
  },
  pressed: {
    opacity: 0.88,
  },
});
