import { StyleSheet, Text, View, type ViewStyle } from 'react-native';

import { AuthColors } from '@/constants/authTheme';

interface WeightLineChartProps {
  points: number[];
  tickLabels: string[];
  yMin: number;
  yMax: number;
  yStep: number;
  color?: string;
  height?: number;
}

function ChartLineSegments({
  points,
  color,
  yMin,
  yMax,
}: {
  points: number[];
  color: string;
  yMin: number;
  yMax: number;
}) {
  if (points.length < 2) return null;

  const range = Math.max(yMax - yMin, 1);
  const denominator = Math.max(points.length - 1, 1);

  function toTop(value: number): number {
    return ((yMax - value) / range) * 100;
  }

  return (
    <>
      {points.slice(1).map((value, index) => {
        const previous = points[index];
        const x1 = index / denominator;
        const x2 = (index + 1) / denominator;
        const y1 = toTop(previous);
        const y2 = toTop(value);
        const dx = (x2 - x1) * 100;
        const dy = y2 - y1;
        const length = Math.sqrt(dx * dx + dy * dy);
        const angle = (Math.atan2(dy, dx) * 180) / Math.PI;

        return (
          <View
            key={`${index}-${value}`}
            style={[
              styles.lineSegment,
              {
                left: `${x1 * 100}%`,
                top: `${y1}%`,
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

export function WeightLineChart({
  points,
  tickLabels,
  yMin,
  yMax,
  yStep,
  color = AuthColors.primary,
  height = 168,
}: WeightLineChartProps) {
  const range = Math.max(yMax - yMin, 1);
  const gridValues: number[] = [];

  for (let value = yMax; value >= yMin; value -= yStep) {
    gridValues.push(value);
  }

  function toTop(value: number): number {
    return ((yMax - value) / range) * 100;
  }

  return (
    <View style={styles.chartWrap}>
      <View style={[styles.plotRow, { height }]}>
        <View style={styles.yAxis}>
          {gridValues.map((line) => (
            <Text key={line} style={styles.yLabel}>
              {line}
            </Text>
          ))}
        </View>

        <View style={styles.plotArea}>
          {gridValues.map((line) => (
            <View
              key={line}
              style={[
                styles.gridLine,
                { top: `${toTop(line)}%` },
              ]}
            />
          ))}

          {points.length > 1 ? (
            <View style={styles.seriesLayer}>
              <ChartLineSegments points={points} color={color} yMin={yMin} yMax={yMax} />
            </View>
          ) : null}

          {points.length > 0 ? (
            <View style={styles.seriesLayer}>
              {points.map((value, index) => {
                const pointStyle: ViewStyle = {
                  left: `${(index / Math.max(points.length - 1, 1)) * 100}%`,
                  top: `${toTop(value)}%`,
                  backgroundColor: color,
                  borderColor: AuthColors.card,
                };

                return (
                  <View key={`${index}-${value}`} style={[styles.point, pointStyle]} />
                );
              })}
            </View>
          ) : null}
        </View>
      </View>

      <View style={styles.xAxis}>
        {tickLabels.map((label, index) => (
          <Text key={`${label}-${index}`} style={styles.xLabel}>
            {label}
          </Text>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  chartWrap: {
    marginTop: 8,
  },
  plotRow: {
    flexDirection: 'row',
    gap: 8,
  },
  yAxis: {
    width: 22,
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
    marginLeft: 30,
  },
  xLabel: {
    fontSize: 11,
    color: AuthColors.textMuted,
  },
});
