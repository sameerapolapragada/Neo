import { Alert } from 'react-native';

export function confirmDeleteMemory(onDelete: () => void): void {
  Alert.alert('Delete this memory?', 'This action cannot be undone.', [
    { text: 'Cancel', style: 'cancel' },
    { text: 'Delete', style: 'destructive', onPress: onDelete },
  ]);
}
