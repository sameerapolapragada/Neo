import { Platform, type TextStyle } from 'react-native';

export const AppFonts = {
  regular: Platform.select({
    web: 'Comic Sans MS, Comic Sans, cursive',
    default: 'ComicNeue_400Regular',
  }) as string,
  bold: Platform.select({
    web: 'Comic Sans MS, Comic Sans, cursive',
    default: 'ComicNeue_700Bold',
  }) as string,
};

type FontWeight = '400' | '600' | '700' | '800';

export function withAppFont(
  weight: FontWeight = '400',
): Pick<TextStyle, 'fontFamily' | 'fontWeight'> {
  if (Platform.OS === 'web') {
    return {
      fontFamily: AppFonts.regular,
      fontWeight: weight === '800' ? '700' : weight,
    };
  }

  if (weight === '400') {
    return { fontFamily: AppFonts.regular };
  }

  return { fontFamily: AppFonts.bold };
}
