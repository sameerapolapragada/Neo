import AsyncStorage from '@react-native-async-storage/async-storage';

import { generateId } from '@/lib/id';
import type { AuthUser } from '@/types/auth';

const KEYS = {
  user: '@neo/auth_user',
  session: '@neo/auth_session',
} as const;

async function getStoredUser(): Promise<AuthUser | null> {
  const raw = await AsyncStorage.getItem(KEYS.user);
  if (!raw) return null;

  try {
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

export const auth = {
  async getSession(): Promise<AuthUser | null> {
    const sessionId = await AsyncStorage.getItem(KEYS.session);
    if (!sessionId) return null;

    const user = await getStoredUser();
    return user?.id === sessionId ? user : null;
  },

  async signUp(name: string, email: string, password: string): Promise<AuthUser> {
    const normalizedEmail = email.trim().toLowerCase();
    const user: AuthUser = {
      id: generateId(),
      name: name.trim(),
      email: normalizedEmail,
      password,
    };

    await AsyncStorage.setItem(KEYS.user, JSON.stringify(user));
    await AsyncStorage.setItem(KEYS.session, user.id);
    return user;
  },

  async signIn(email: string, password: string): Promise<AuthUser> {
    const user = await getStoredUser();
    const normalizedEmail = email.trim().toLowerCase();

    if (!user || user.email !== normalizedEmail || user.password !== password) {
      throw new Error('Invalid email or password');
    }

    await AsyncStorage.setItem(KEYS.session, user.id);
    return user;
  },

  async signOut(): Promise<void> {
    await AsyncStorage.removeItem(KEYS.session);
  },

  async hasAccount(): Promise<boolean> {
    return Boolean(await getStoredUser());
  },
};
