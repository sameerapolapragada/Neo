import { useWindowDimensions } from 'react-native';

export type ScreenSize = 'small' | 'medium' | 'large';

export function useResponsive() {
  const { width, height } = useWindowDimensions();

  const screenSize: ScreenSize =
    width < 360 ? 'small' : width < 414 ? 'medium' : 'large';

  return {
    width,
    height,
    screenSize,
    isSmall: screenSize === 'small',
    isLarge: screenSize === 'large',
    horizontalPadding: screenSize === 'small' ? 16 : screenSize === 'medium' ? 20 : 24,
    verticalPadding: screenSize === 'small' ? 16 : 24,
    photoSize: screenSize === 'small' ? 112 : screenSize === 'medium' ? 132 : 152,
    heroLogoSize: screenSize === 'small' ? 80 : screenSize === 'medium' ? 96 : 108,
    maxContentWidth: Math.min(width - 32, 500),
  };
}
