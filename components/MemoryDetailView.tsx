import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { useState } from 'react';
import { Pressable, Share, StyleSheet, Text, View } from 'react-native';
import { withAppFont } from '@/constants/fonts';

import { AuthColors, AuthShadow, AuthTypography } from '@/constants/authTheme';
import { formatMemoryDate, parseMemoryDate } from '@/utils/memoryDate';
import type { Memory } from '@/types';

const DEFAULT_PHOTO = require('@/assets/images/memory-detail-default.jpg');

interface MemoryDetailViewProps {
  memory: Memory;
  currentIndex: number;
  totalCount: number;
  liked: boolean;
  onBack: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onToggleLike: () => void;
  onPrevious: () => void;
  onNext: () => void;
}

export function MemoryDetailView({
  memory,
  currentIndex,
  totalCount,
  liked,
  onBack,
  onEdit,
  onDelete,
  onToggleLike,
  onPrevious,
  onNext,
}: MemoryDetailViewProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  const hasPrevious = currentIndex > 0;
  const hasNext = currentIndex < totalCount - 1;

  function closeMenu() {
    setMenuOpen(false);
  }

  function handleEdit() {
    closeMenu();
    onEdit();
  }

  function handleDelete() {
    closeMenu();
    onDelete();
  }

  async function handleShare() {
    try {
      await Share.share({
        title: memory.title,
        message: `${memory.title}\n\n${memory.description}`,
      });
    } catch {
      // User dismissed share sheet.
    }
  }

  return (
    <View style={styles.card}>
      {menuOpen ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Close menu"
          onPress={closeMenu}
          style={styles.dismissOverlay}
        />
      ) : null}

      <View style={styles.heroWrap}>
        <Image
          source={memory.photo_uri ? { uri: memory.photo_uri } : DEFAULT_PHOTO}
          style={styles.heroImage}
          contentFit="cover"
        />

        <View style={styles.heroOverlay}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Go back"
            onPress={onBack}
            style={({ pressed }) => [styles.heroButton, pressed && styles.pressed]}>
            <Ionicons name="arrow-back" size={22} color={AuthColors.background} />
          </Pressable>

          <View style={styles.menuAnchor}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Memory options"
              accessibilityState={{ expanded: menuOpen }}
              onPress={() => setMenuOpen((open) => !open)}
              style={({ pressed }) => [styles.heroButton, pressed && styles.pressed]}>
              <Ionicons name="ellipsis-horizontal" size={22} color={AuthColors.background} />
            </Pressable>

            {menuOpen ? (
              <View style={styles.dropdown}>
                <Pressable
                  accessibilityRole="button"
                  onPress={handleEdit}
                  style={({ pressed }) => [styles.dropdownItem, pressed && styles.dropdownItemPressed]}>
                  <Ionicons name="pencil-outline" size={16} color={AuthColors.text} />
                  <Text style={styles.dropdownLabel}>Edit</Text>
                </Pressable>
                <View style={styles.dropdownDivider} />
                <Pressable
                  accessibilityRole="button"
                  onPress={handleDelete}
                  style={({ pressed }) => [styles.dropdownItem, pressed && styles.dropdownItemPressed]}>
                  <Ionicons name="trash-outline" size={16} color={AuthColors.error} />
                  <Text style={[styles.dropdownLabel, styles.dropdownLabelDanger]}>Delete</Text>
                </Pressable>
              </View>
            ) : null}
          </View>
        </View>
      </View>

      <View style={styles.body}>
        <View style={styles.titleRow}>
          <Text style={styles.title}>{memory.title}</Text>

          <View style={styles.actions}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={liked ? 'Unlike memory' : 'Like memory'}
              onPress={onToggleLike}
              style={({ pressed }) => [styles.actionButton, pressed && styles.pressed]}>
              <Ionicons
                name={liked ? 'heart' : 'heart-outline'}
                size={22}
                color={liked ? AuthColors.primary : AuthColors.textMuted}
              />
            </Pressable>

            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Share memory"
              onPress={handleShare}
              style={({ pressed }) => [styles.actionButton, pressed && styles.pressed]}>
              <Ionicons name="share-social-outline" size={22} color={AuthColors.textMuted} />
            </Pressable>
          </View>
        </View>

        <Text style={styles.date}>{formatMemoryDate(parseMemoryDate(memory.created_at))}</Text>
        <Text style={styles.description}>{memory.description}</Text>
      </View>

      <View style={styles.footer}>
        <Pressable
          accessibilityRole="button"
          disabled={!hasPrevious}
          onPress={onPrevious}
          style={({ pressed }) => [
            styles.navButton,
            !hasPrevious && styles.navButtonDisabled,
            pressed && hasPrevious && styles.pressed,
          ]}>
          <Ionicons
            name="chevron-back"
            size={16}
            color={hasPrevious ? AuthColors.primaryDark : AuthColors.textMuted}
          />
          <Text style={[styles.navLabel, !hasPrevious && styles.navLabelDisabled]}>Previous</Text>
        </Pressable>

        <Text style={styles.counter}>
          {currentIndex + 1} of {totalCount}
        </Text>

        <Pressable
          accessibilityRole="button"
          disabled={!hasNext}
          onPress={onNext}
          style={({ pressed }) => [
            styles.navButton,
            !hasNext && styles.navButtonDisabled,
            pressed && hasNext && styles.pressed,
          ]}>
          <Text style={[styles.navLabel, !hasNext && styles.navLabelDisabled]}>Next</Text>
          <Ionicons
            name="chevron-forward"
            size={16}
            color={hasNext ? AuthColors.primaryDark : AuthColors.textMuted}
          />
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    position: 'relative',
    backgroundColor: AuthColors.card,
    borderRadius: 24,
    overflow: 'hidden',
    ...AuthShadow.card,
  },
  dismissOverlay: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 1,
  },
  heroWrap: {
    position: 'relative',
    zIndex: 2,
    height: 360,
    backgroundColor: AuthColors.surface,
  },
  heroImage: {
    width: '100%',
    height: '100%',
  },
  heroOverlay: {
    position: 'absolute',
    top: 12,
    left: 12,
    right: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  heroButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(45, 38, 64, 0.28)',
  },
  menuAnchor: {
    position: 'relative',
    zIndex: 3,
  },
  dropdown: {
    position: 'absolute',
    top: 46,
    right: 0,
    minWidth: 132,
    backgroundColor: AuthColors.background,
    borderRadius: 12,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: AuthColors.border,
    ...AuthShadow.card,
  },
  dropdownItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  dropdownItemPressed: {
    backgroundColor: AuthColors.primarySoft,
  },
  dropdownDivider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: AuthColors.border,
    marginHorizontal: 8,
  },
  dropdownLabel: {
    ...AuthTypography.label,
    fontSize: 14,
    color: AuthColors.text,
  },
  dropdownLabelDanger: {
    color: AuthColors.error,
  },
  body: {
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 8,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: 12,
  },
  title: {
    flex: 1,
    fontSize: 24,
    lineHeight: 30,
    ...withAppFont('700'),
    color: AuthColors.text,
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 2,
  },
  actionButton: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  date: {
    ...AuthTypography.body,
    fontSize: 14,
    color: AuthColors.textMuted,
    marginTop: 6,
    marginBottom: 14,
  },
  description: {
    ...AuthTypography.body,
    fontSize: 16,
    lineHeight: 24,
    color: AuthColors.text,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 18,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: AuthColors.border,
  },
  navButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: AuthColors.primarySoft,
    borderRadius: 999,
    paddingHorizontal: 14,
    paddingVertical: 10,
    minWidth: 108,
    justifyContent: 'center',
  },
  navButtonDisabled: {
    opacity: 0.45,
  },
  navLabel: {
    ...AuthTypography.label,
    fontSize: 14,
    color: AuthColors.primaryDark,
  },
  navLabelDisabled: {
    color: AuthColors.textMuted,
  },
  counter: {
    ...AuthTypography.body,
    fontSize: 14,
    fontWeight: '600',
    color: AuthColors.textMuted,
  },
  pressed: {
    opacity: 0.85,
  },
});
