import React from 'react';
import { StyleSheet, type StyleProp, type TextStyle } from 'react-native';

import { AppFonts, withAppFont } from '@/constants/fonts';

function getFontPatch(style: StyleProp<TextStyle> | undefined) {
  const flat = StyleSheet.flatten(style);
  if (flat?.fontFamily) {
    return null;
  }

  const weight = flat?.fontWeight;
  if (
    weight === '700' ||
    weight === '800' ||
    weight === 'bold' ||
    weight === 700 ||
    weight === 800
  ) {
    return withAppFont('700');
  }

  if (weight === '600' || weight === 600) {
    return withAppFont('600');
  }

  return withAppFont('400');
}

function patchComponent<T extends React.ComponentType<any>>(Original: T, displayName: string): T {
  const Wrapped = React.forwardRef<any, React.ComponentProps<T>>((props, ref) => {
    const patch = getFontPatch(props.style);
    return React.createElement(Original, {
      ...props,
      ref,
      style: patch ? [patch, props.style] : props.style,
    });
  });

  Wrapped.displayName = displayName;
  return Wrapped as unknown as T;
}

export function patchGlobalFonts() {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const ReactNative = require('react-native') as typeof import('react-native') & {
    __neoFontsPatched?: boolean;
  };

  if (ReactNative.__neoFontsPatched) {
    return;
  }

  Object.defineProperty(ReactNative, 'Text', {
    configurable: true,
    enumerable: true,
    value: patchComponent(ReactNative.Text, 'Text'),
  });

  Object.defineProperty(ReactNative, 'TextInput', {
    configurable: true,
    enumerable: true,
    value: patchComponent(ReactNative.TextInput, 'TextInput'),
  });

  ReactNative.__neoFontsPatched = true;
}

patchGlobalFonts();
