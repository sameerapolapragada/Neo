import { router } from 'expo-router';
import { Platform, ScrollView, StyleSheet } from 'react-native';

import { MoreFeaturesView } from '@/components/MoreFeaturesView';
import { SafeScreen } from '@/components/SafeScreen';
import { AuthColors } from '@/constants/authTheme';
import { Spacing } from '@/constants/theme';
import { useResponsive } from '@/hooks/useResponsive';

export default function MoreFeaturesScreen() {
  const { horizontalPadding } = useResponsive();

  return (
    <SafeScreen style={styles.screen} edges={['top']}>
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingHorizontal: horizontalPadding },
        ]}
        showsVerticalScrollIndicator={false}>
        <MoreFeaturesView onBack={() => router.back()} />
      </ScrollView>
    </SafeScreen>
  );
}

const styles = StyleSheet.create({
  screen: {
    backgroundColor: AuthColors.screenBackground,
  },
  content: {
    flexGrow: 1,
    paddingTop: Spacing.sm,
    paddingBottom: Platform.OS === 'ios' ? 40 : 24,
  },
});
