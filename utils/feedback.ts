import { Alert, Platform } from 'react-native';

import { getErrorMessage } from '@/lib/errors';

export function showSaveError(action: string, error: unknown): void {
  Alert.alert(`${action} failed`, getErrorMessage(error, 'Please try again.'));
}

export function showRemoteFallbackNotice(remoteFailed: boolean): void {
  if (!remoteFailed) return;

  Alert.alert(
    'Saved on this device',
    'Cloud sync is unavailable right now. Your data is stored locally and safe offline.',
  );
}

export function showPermissionAlert(type: 'photos'): void {
  const message =
    type === 'photos'
      ? 'Allow photo library access in Settings to add pet and memory photos.'
      : 'Permission is required to continue.';

  Alert.alert('Permission needed', message);
}

export function showValidationAlert(message: string): void {
  Alert.alert('Check your entries', message);
}

export const pickerHeight = Platform.OS === 'ios' ? 132 : 52;
