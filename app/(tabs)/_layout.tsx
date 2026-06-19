import { Tabs } from 'expo-router';

import { LifeTabBar } from '@/components/LifeTabBar';
import { AuthColors } from '@/constants/authTheme';

export default function TabLayout() {
  return (
    <Tabs
      tabBar={(props) => <LifeTabBar {...props} />}
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: AuthColors.primary,
        tabBarInactiveTintColor: AuthColors.textMuted,
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
        }}
      />
      <Tabs.Screen
        name="add"
        options={{
          title: 'Add',
        }}
      />
      <Tabs.Screen
        name="snapshot"
        options={{
          href: null,
          title: 'Snapshot',
        }}
      />
      <Tabs.Screen
        name="moments"
        options={{
          title: 'Wellness',
        }}
      />
      <Tabs.Screen
        name="timeline"
        options={{
          href: null,
          title: 'Timeline',
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
        }}
      />
      <Tabs.Screen
        name="weight-tracker"
        options={{
          href: null,
          title: 'Weight Tracker',
        }}
      />
    </Tabs>
  );
}
