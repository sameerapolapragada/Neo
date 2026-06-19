import { Ionicons } from '@expo/vector-icons';
import { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AuthColors, AuthShadow, AuthTypography } from '@/constants/authTheme';

type TabConfig = {
  routeName: string;
  label: string;
  icon: React.ComponentProps<typeof Ionicons>['name'];
  activeIcon?: React.ComponentProps<typeof Ionicons>['name'];
};

const LEFT_TABS: TabConfig[] = [
  { routeName: 'index', label: 'Home', icon: 'home-outline', activeIcon: 'home' },
];

const RIGHT_TABS: TabConfig[] = [
  { routeName: 'moments', label: 'Wellness', icon: 'heart-outline', activeIcon: 'heart' },
  { routeName: 'profile', label: 'Profile', icon: 'person-outline', activeIcon: 'person' },
];

export function LifeTabBar({ state, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const activeColor = AuthColors.onboardingPrimary;
  const addRouteIndex = state.routes.findIndex((route) => route.name === 'add');
  const addFocused = state.index === addRouteIndex;

  function navigateTo(routeName: string) {
    const route = state.routes.find((item) => item.name === routeName);
    if (!route) return;

    const index = state.routes.indexOf(route);
    const event = navigation.emit({
      type: 'tabPress',
      target: route.key,
      canPreventDefault: true,
    });

    if (!event.defaultPrevented) {
      navigation.navigate(route.name);
    }

    if (state.index !== index) {
      navigation.navigate(route.name);
    }
  }

  function renderTab(tab: TabConfig) {
    const routeIndex = state.routes.findIndex((route) => route.name === tab.routeName);
    const focused = state.index === routeIndex;
    const iconName = focused && tab.activeIcon ? tab.activeIcon : tab.icon;

    return (
      <Pressable
        key={tab.routeName}
        accessibilityRole="button"
        accessibilityState={{ selected: focused }}
        onPress={() => navigateTo(tab.routeName)}
        style={styles.tab}>
        <Ionicons
          name={iconName}
          size={22}
          color={focused ? activeColor : AuthColors.textMuted}
        />
        <Text style={[styles.tabLabel, focused && styles.tabLabelActive]}>{tab.label}</Text>
      </Pressable>
    );
  }

  return (
    <View style={[styles.wrap, { paddingBottom: Math.max(insets.bottom, 8) }]}>
      <View style={styles.bar}>
        {LEFT_TABS.map(renderTab)}

        <View style={styles.fabSpacer}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Add memory"
            accessibilityState={{ selected: addFocused }}
            onPress={() => navigateTo('add')}
            style={({ pressed }) => [styles.fab, pressed && styles.pressed]}>
            <Ionicons name="add" size={28} color={AuthColors.background} />
          </Pressable>
          <Text style={[styles.fabLabel, addFocused && styles.tabLabelActive]}>Add</Text>
        </View>

        {RIGHT_TABS.map(renderTab)}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: AuthColors.card,
    borderTopWidth: 1,
    borderTopColor: AuthColors.border,
    paddingTop: 10,
    ...AuthShadow.soft,
  },
  bar: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-around',
    paddingHorizontal: 12,
    minHeight: 54,
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    paddingBottom: 4,
  },
  tabLabel: {
    ...AuthTypography.label,
    fontSize: 11,
    color: AuthColors.textMuted,
  },
  tabLabelActive: {
    color: AuthColors.onboardingPrimary,
  },
  fabSpacer: {
    flex: 1,
    alignItems: 'center',
    marginTop: -28,
    gap: 4,
  },
  fabLabel: {
    ...AuthTypography.label,
    fontSize: 11,
    color: AuthColors.textMuted,
    marginTop: 2,
  },
  fab: {
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: AuthColors.onboardingPrimary,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 4,
    borderColor: AuthColors.card,
    ...AuthShadow.card,
  },
  pressed: {
    opacity: 0.88,
  },
});
