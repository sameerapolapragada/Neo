import { StyleSheet, Text, View, type ViewStyle } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

interface WellnessSparklineProps {
  points: number[];
  color?: string;
  height?: number;
  filled?: boolean;
}

export function WellnessSparkline({
  points,
  color = AuthColors.primary,
  height = 44,
  filled = true,
}: WellnessSparklineProps) {
  if (points.length === 0) {
    return <View style={[styles.empty, { height }]} />;
  }

  return (
    <View style={[styles.wrap, { height }]}>
      {filled ? <View style={[styles.fill, { backgroundColor: `${color}18` }]} /> : null}
      <View style={styles.row}>
        {points.map((value, index) => {
          const normalized = Math.max(1, Math.min(5, value));
          const barHeight = ((normalized - 1) / 4) * (height - 10) + 8;

          return (
            <View key={`${index}-${value}`} style={styles.cell}>
              <View style={[styles.dot, { backgroundColor: color }]} />
              <View style={[styles.bar, { height: barHeight, backgroundColor: color }]} />
            </View>
          );
        })}
      </View>
    </View>
  );
}

interface WellnessLineChartProps {
  series: { color: string; points: number[]; label: string }[];
  tickLabels: string[];
  height?: number;
}

function ChartLineSegments({ points, color }: { points: number[]; color: string }) {
  if (points.length < 2) return null;

  const denominator = Math.max(points.length - 1, 1);

  return (
    <>
      {points.slice(1).map((value, index) => {
        const previous = points[index];
        const x1 = index / denominator;
        const x2 = (index + 1) / denominator;
        const y1 = (5 - previous) / 4;
        const y2 = (5 - value) / 4;
        const dx = (x2 - x1) * 100;
        const dy = (y2 - y1) * 100;
        const length = Math.sqrt(dx * dx + dy * dy);
        const angle = (Math.atan2(dy, dx) * 180) / Math.PI;

        return (
          <View
            key={`${index}-${value}`}
            style={[
              styles.lineSegment,
              {
                left: `${x1 * 100}%`,
                top: `${y1 * 100}%`,
                width: `${length}%`,
                backgroundColor: color,
                transform: [{ rotate: `${angle}deg` }],
              },
            ]}
          />
        );
      })}
    </>
  );
}

export function WellnessLineChart({
  series,
  tickLabels,
  height = 180,
}: WellnessLineChartProps) {
  const gridLines = [5, 4, 3, 2, 1];

  return (
    <View style={styles.chartWrap}>
      <View style={[styles.plotRow, { height }]}>
        <View style={styles.yAxis}>
          {gridLines.map((line) => (
            <Text key={line} style={styles.yLabel}>
              {line}
            </Text>
          ))}
        </View>

        <View style={styles.plotArea}>
          {gridLines.map((line) => (
            <View
              key={line}
              style={[
                styles.gridLine,
                { top: `${((5 - line) / 4) * 100}%` },
              ]}
            />
          ))}

          {series.map((entry) =>
            entry.points.length > 1 ? (
              <View key={`${entry.label}-lines`} style={styles.seriesLayer}>
                <ChartLineSegments points={entry.points} color={entry.color} />
              </View>
            ) : null,
          )}

          {series.map((entry) =>
            entry.points.length > 0 ? (
              <View key={entry.label} style={styles.seriesLayer}>
                {entry.points.map((value, index) => {
                  const normalized = Math.max(1, Math.min(5, value));
                  const pointStyle: ViewStyle = {
                    left: `${(index / Math.max(entry.points.length - 1, 1)) * 100}%`,
                    top: `${((5 - normalized) / 4) * 100}%`,
                    backgroundColor: entry.color,
                    borderColor: AuthColors.card,
                  };

                  return (
                    <View
                      key={`${entry.label}-${index}`}
                      style={[styles.point, pointStyle]}
                    />
                  );
                })}
              </View>
            ) : null,
          )}
        </View>
      </View>

      <View style={styles.xAxis}>
        {tickLabels.map((label) => (
          <Text key={label} style={styles.xLabel}>
            {label}
          </Text>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    position: 'relative',
    overflow: 'hidden',
    borderRadius: 8,
  },
  empty: {
    backgroundColor: AuthColors.surface,
    borderRadius: 8,
  },
  fill: {
    ...StyleSheet.absoluteFillObject,
    borderBottomLeftRadius: 8,
    borderBottomRightRadius: 8,
  },
  row: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 4,
    paddingHorizontal: 2,
    paddingBottom: 2,
  },
  cell: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-end',
    height: '100%',
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginBottom: 4,
  },
  bar: {
    width: '72%',
    minWidth: 4,
    borderRadius: 999,
    opacity: 0.85,
  },
  chartWrap: {
    marginTop: 4,
  },
  plotRow: {
    flexDirection: 'row',
    gap: 8,
  },
  yAxis: {
    width: 14,
    justifyContent: 'space-between',
    paddingVertical: 2,
  },
  yLabel: {
    fontSize: 11,
    color: AuthColors.textMuted,
    textAlign: 'right',
  },
  plotArea: {
    flex: 1,
    position: 'relative',
  },
  gridLine: {
    position: 'absolute',
    left: 0,
    right: 0,
    borderTopWidth: 1,
    borderColor: AuthColors.border,
    opacity: 0.7,
  },
  seriesLayer: {
    ...StyleSheet.absoluteFillObject,
  },
  lineSegment: {
    position: 'absolute',
    height: 2,
    borderRadius: 999,
    transformOrigin: 'left center',
  },
  point: {
    position: 'absolute',
    width: 8,
    height: 8,
    borderRadius: 4,
    marginLeft: -4,
    marginTop: -4,
    borderWidth: 1.5,
  },
  xAxis: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 10,
    marginLeft: 22,
  },
  xLabel: {
    fontSize: 11,
    color: AuthColors.textMuted,
  },
});
