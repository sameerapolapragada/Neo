import { SymbolView } from 'expo-symbols';
import { Tabs } from 'expo-router';
import { ColorValue, Platform } from 'react-native';

import { Colors } from '@/constants/theme';

function TabIcon({
  ios,
  android,
  color,
}: {
  ios: string;
  android: string;
  color: ColorValue;
}) {
  return (
    <SymbolView
      name={{ ios: ios as never, android: android as never }}
      tintColor={color}
      size={24}
    />
  );
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.tabInactive,
        tabBarStyle: {
          backgroundColor: Colors.card,
          borderTopColor: Colors.border,
          paddingTop: 4,
          height: Platform.OS === 'ios' ? 88 : 64,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '600',
          marginBottom: Platform.OS === 'ios' ? 0 : 8,
        },
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color }) => (
            <TabIcon ios="house.fill" android="home" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="snapshot"
        options={{
          title: 'Snapshot',
          tabBarIcon: ({ color }) => (
            <TabIcon ios="sparkles" android="auto_awesome" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="moments"
        options={{
          title: 'Moments',
          tabBarIcon: ({ color }) => (
            <TabIcon ios="heart.fill" android="favorite" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="timeline"
        options={{
          title: 'Timeline',
          tabBarIcon: ({ color }) => (
            <TabIcon ios="clock.fill" android="schedule" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color }) => (
            <TabIcon ios="person.fill" android="person" color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
