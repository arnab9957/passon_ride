// ignore_for_file: deprecated_member_use, unnecessary_underscores, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'account_switcher_dialog.dart';
import 'create_child_account_dialog.dart';
import 'link_existing_account_dialog.dart';
import 'customer_booking_details_dialog.dart';

/// Modern, responsive, and user-friendly viewer for Mother & Child Profile Architecture.
class MotherChildAccountCard extends StatefulWidget {
  const MotherChildAccountCard({super.key});

  @override
  State<MotherChildAccountCard> createState() => _MotherChildAccountCardState();
}

class _MotherChildAccountCardState extends State<MotherChildAccountCard>
    with SingleTickerProviderStateMixin {
  int _oversightTabIndex = 0; // 0: Fleet, 1: Bookings
  bool _isOversightExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMother = appState.isMotherAccount;
    final childProfiles = appState.childProfiles;
    final childCount = childProfiles.length;
    final hasReachedLimit = childCount >= 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final isTablet = constraints.maxWidth > 500 && constraints.maxWidth <= 700;

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.outlineVariantDark
                  : AppColors.outlineVariantLight.withOpacity(0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER & ACTIVE ACCOUNT HERO
              _buildHeroHeader(context, appState, isDark, isMother, isWide),

              // 2. CHILD MODE NOTICE (If currently operating as child)
              if (!isMother) ...[
                _buildChildModeBanner(context, appState, isDark),
              ],

              // 3. MOTHER VIEW: 3-SLOT ARCHITECTURE & CONTROLS
              if (isMother) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header + Visual Slot Gauge
                      _buildSlotsHeader(context, childCount, hasReachedLimit, isDark),
                      const SizedBox(height: 14),

                      // Responsive 3-Slot Visual Grid
                      _buildThreeSlotsGrid(
                        context,
                        appState,
                        childProfiles,
                        isDark,
                        isWide,
                        isTablet,
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Buttons
                      _buildActionButtons(context, hasReachedLimit, isDark, isWide),
                    ],
                  ),
                ),

                // 4. FLEET & BOOKINGS OVERSIGHT DECK (Collapsible / Tabbed)
                if (childProfiles.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildOversightDeck(context, appState, isDark, isWide),
                ],
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // HERO HEADER (Active Account & Status)
  // ==========================================
  Widget _buildHeroHeader(
    BuildContext context,
    AppState appState,
    bool isDark,
    bool isMother,
    bool isWide,
  ) {
    final activeColor = isMother ? AppColors.primary : Colors.purple;
    final gradientColors = isMother
        ? (isDark
            ? [const Color(0xFF132F2B), const Color(0xFF0F1E24)]
            : [const Color(0xFFE8F5E9), const Color(0xFFE0F2F1)])
        : (isDark
            ? [const Color(0xFF2C1338), const Color(0xFF1A0F26)]
            : [const Color(0xFFF3E5F5), const Color(0xFFEDE7F6)]);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border(
          bottom: BorderSide(
            color: activeColor.withOpacity(isDark ? 0.25 : 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isMother
                          ? Icons.hub_rounded
                          : Icons.person_pin_circle_rounded,
                      color: activeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCOUNT ARCHITECTURE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: activeColor,
                        ),
                      ),
                      Text(
                        isMother
                          ? 'Mother Profile Hub'
                          : 'Independent Child Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Cloud Sync Live Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activeColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Supabase Sync',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Identity Card
          Row(
            children: [
              // Avatar with Ring Glow
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [activeColor, activeColor.withOpacity(0.3)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: activeColor,
                      backgroundImage: appState.activeUserPhotoUrl.isNotEmpty
                          ? NetworkImage(appState.activeUserPhotoUrl)
                          : null,
                      child: appState.activeUserPhotoUrl.isEmpty
                          ? Text(
                              appState.activeUserDisplayName.isNotEmpty
                                  ? appState.activeUserDisplayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        isMother ? 'MOTHER' : 'CHILD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name, Email, & ID badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.activeUserDisplayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appState.activeUserEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Copyable ID Tag
                    InkWell(
                      onTap: () {
                        final idToCopy = isMother
                            ? appState.activeMotherId
                            : appState.activeAccountId;
                        Clipboard.setData(ClipboardData(text: idToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied ${isMother ? "Mother" : "Child"} ID: $idToCopy'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fingerprint, size: 12, color: activeColor),
                            const SizedBox(width: 4),
                            Text(
                              isMother
                                  ? (appState.activeMotherId.isNotEmpty
                                      ? appState.activeMotherId
                                      : 'Mother ID')
                                  : appState.activeAccountId,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy_rounded, size: 11, color: activeColor.withOpacity(0.8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Switch Account Action Button
              ElevatedButton.icon(
                onPressed: () => AccountSwitcherDialog.show(context),
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text(
                  'Switch',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CHILD MODE BANNER (When child is active)
  // ==========================================
  Widget _buildChildModeBanner(BuildContext context, AppState appState, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autonomous Child Account Active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Personal bookings, rides, and vehicles are isolated and private to this account.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => appState.switchAccount(appState.activeMotherId),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                'Return to Mother Profile Hub',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SLOTS HEADER & ALLOCATION GAUGE
  // ==========================================
  Widget _buildSlotsHeader(
    BuildContext context,
    int childCount,
    bool hasReachedLimit,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LINKED CHILD ACCOUNTS (MAX 3)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Independent profiles managed under this Mother Hub',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),

        // 3-Bar Segmented Visual Gauge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasReachedLimit
                ? Colors.red.withOpacity(0.12)
                : Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasReachedLimit
                  ? Colors.red.withOpacity(0.3)
                  : Colors.purple.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Segmented Dots
              ...List.generate(3, (index) {
                final isFilled = index < childCount;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (hasReachedLimit ? Colors.red : Colors.purple)
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                '$childCount / 3',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: hasReachedLimit ? Colors.red : Colors.purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // RESPONSIVE 3-SLOT GRID
  // ==========================================
  Widget _buildThreeSlotsGrid(
    BuildContext context,
    AppState appState,
    List<ChildProfile> childProfiles,
    bool isDark,
    bool isWide,
    bool isTablet,
  ) {
    // 3 slots
    final slots = List.generate(3, (index) {
      if (index < childProfiles.length) {
        return _buildOccupiedSlotCard(
          context,
          appState,
          childProfiles[index],
          index + 1,
          isDark,
        );
      } else {
        return _buildEmptySlotCard(
          context,
          index + 1,
          isDark,
        );
      }
    });

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: slots
            .map((s) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: s,
                  ),
                ))
            .toList(),
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: slots[0]),
              const SizedBox(width: 8),
              Expanded(child: slots[1]),
            ],
          ),
          const SizedBox(height: 8),
          slots[2],
        ],
      );
    }

    // Mobile: Vertical Stack
    return Column(
      children: slots
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: s,
              ))
          .toList(),
    );
  }

  // ==========================================
  // OCCUPIED SLOT CARD
  // ==========================================
  Widget _buildOccupiedSlotCard(
    BuildContext context,
    AppState appState,
    ChildProfile child,
    int slotNumber,
    bool isDark,
  ) {
    final childVehicles = appState.getVehiclesHostedByChild(child.childId);
    final childBookings = appState.getBookingsForChild(child.childId);
    final isCurrentActive = appState.activeAccountId == child.childId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLowestDark
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentActive
              ? Colors.purple
              : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
          width: isCurrentActive ? 2 : 1,
        ),
        boxShadow: isCurrentActive
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SLOT #$slotNumber',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (isCurrentActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ACTIVE NOW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                )
              else
                // Menu for options (Details, Unlink)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 140),
                  onSelected: (val) {
                    if (val == 'details') {
                      _showChildDetailsModal(context, appState, child, isDark);
                    } else if (val == 'unlink') {
                      _showUnlinkConfirmationDialog(context, appState, child);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('View Details', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'unlink',
                      child: Row(
                        children: [
                          Icon(Icons.link_off_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Unlink Account', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Avatar + Name + Email
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.withOpacity(0.15),
                backgroundImage: child.profilePhoto.isNotEmpty
                    ? NetworkImage(child.profilePhoto)
                    : null,
                child: child.profilePhoto.isEmpty
                    ? Text(
                        child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      child.email,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metrics Pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: childVehicles.isNotEmpty
                        ? Colors.teal.withOpacity(0.12)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 12,
                        color: childVehicles.isNotEmpty ? Colors.teal : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${childVehicles.length} Fleet',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: childVehicles.isNotEmpty
                              ? (isDark ? Colors.tealAccent : Colors.teal.shade800)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: childBookings.isNotEmpty
                        ? Colors.blue.withOpacity(0.12)
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 12,
                        color: childBookings.isNotEmpty ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${childBookings.length} Bookings',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: childBookings.isNotEmpty
                              ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade800)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Switch Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCurrentActive
                  ? null
                  : () => appState.switchAccount(child.childId),
              icon: Icon(
                isCurrentActive ? Icons.check_circle : Icons.swap_horiz_rounded,
                size: 13,
              ),
              label: Text(
                isCurrentActive ? 'Active Account' : 'Switch To Account',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentActive
                    ? (isDark ? Colors.white12 : Colors.grey.shade200)
                    : Colors.purple,
                foregroundColor: isCurrentActive ? Colors.grey : Colors.white,
                elevation: isCurrentActive ? 0 : 1,
                padding: const EdgeInsets.symmetric(vertical: 7),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY SLOT CARD (Add / Link CTA)
  // ==========================================
  Widget _buildEmptySlotCard(
    BuildContext context,
    int slotNumber,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLowestDark.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SLOT #$slotNumber',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'AVAILABLE',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              size: 20,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Empty Slot',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'Add up to 3 independent accounts',
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Quick Action for this slot
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const CreateChildAccountDialog(),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    '+ Create',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const LinkExistingAccountDialog(),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    side: BorderSide(color: Colors.purple.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    '🔗 Link',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION BUTTONS (+ Create Child / Link)
  // ==========================================
  Widget _buildActionButtons(
    BuildContext context,
    bool hasReachedLimit,
    bool isDark,
    bool isWide,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasReachedLimit
                ? null
                : () => showDialog(
                      context: context,
                      builder: (_) => const CreateChildAccountDialog(),
                    ),
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: const Text(
              'Create Child Profile',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasReachedLimit
                ? null
                : () => showDialog(
                      context: context,
                      builder: (_) => const LinkExistingAccountDialog(),
                    ),
            icon: const Icon(Icons.link_rounded, size: 16),
            label: const Text(
              'Link Existing Account',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: BorderSide(color: Colors.purple.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // OVERSIGHT DECK (FLEET & BOOKINGS FEED)
  // ==========================================
  Widget _buildOversightDeck(
    BuildContext context,
    AppState appState,
    bool isDark,
    bool isWide,
  ) {
    final allChildVehicles = appState.allChildHostedVehicles;
    final childBookings = appState.childAccountBookings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expand / Collapse Header
          InkWell(
            onTap: () {
              setState(() {
                _isOversightExpanded = !_isOversightExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics_outlined, size: 16, color: Colors.purple),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CHILD OVERSIGHT DECK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${allChildVehicles.length} Fleet • ${childBookings.length} Bookings',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isOversightExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          if (_isOversightExpanded) ...[
            const SizedBox(height: 12),

            // Segmented Tab Selector
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _oversightTabIndex = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _oversightTabIndex == 0
                            ? Colors.purple.withOpacity(0.15)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _oversightTabIndex == 0
                              ? Colors.purple
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            size: 15,
                            color: _oversightTabIndex == 0 ? Colors.purple : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Child Fleet (${allChildVehicles.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _oversightTabIndex == 0 ? Colors.purple : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _oversightTabIndex = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _oversightTabIndex == 1
                            ? Colors.purple.withOpacity(0.15)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _oversightTabIndex == 1
                              ? Colors.purple
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 15,
                            color: _oversightTabIndex == 1 ? Colors.purple : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Child Bookings (${childBookings.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _oversightTabIndex == 1 ? Colors.purple : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Content
            if (_oversightTabIndex == 0)
              _buildFleetTab(context, appState, allChildVehicles, isDark)
            else
              _buildBookingsTab(context, appState, childBookings, isDark),
          ],
        ],
      ),
    );
  }

  // Fleet Oversight List
  Widget _buildFleetTab(
    BuildContext context,
    AppState appState,
    List<Vehicle> vehicles,
    bool isDark,
  ) {
    if (vehicles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No vehicles hosted by child accounts yet',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: vehicles.map((v) {
        final hostAccount = appState.childProfiles.firstWhere(
          (c) => c.childId == v.ownerAccountId || c.childId == v.hostId,
          orElse: () => ChildProfile(
            childId: v.ownerAccountId,
            motherId: appState.activeMotherId,
            name: v.hostName,
            email: '',
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  v.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.directions_car, size: 24, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Hosted by ${hostAccount.name}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\$${v.pricePerDay.toStringAsFixed(0)}/day',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: v.status.toLowerCase() == 'available'
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: v.status.toLowerCase() == 'available'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Bookings Oversight Feed
  Widget _buildBookingsTab(
    BuildContext context,
    AppState appState,
    List<Booking> bookings,
    bool isDark,
  ) {
    if (bookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note_outlined, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No vehicle bookings from child profiles yet',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd');

    return Column(
      children: bookings.map((b) {
        final child = appState.getChildProfileForBooking(b);
        final displayName = child?.name ?? (b.childName.isNotEmpty ? b.childName : (b.accountName.isNotEmpty ? b.accountName : 'Child Account'));
        final isHosting = b.isChildHosting;

        final badgeColor = isHosting ? Colors.teal : Colors.purple;
        final iconColor = isHosting ? Colors.teal : Colors.blue;

        return InkWell(
          onTap: () {
            showCustomerBookingDetailsDialog(context, b);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHosting
                    ? (isDark ? Colors.teal.withOpacity(0.35) : Colors.teal.withOpacity(0.25))
                    : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
                width: isHosting ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHosting ? Icons.car_rental_rounded : Icons.receipt_rounded,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.vehicleTitle.isNotEmpty ? b.vehicleTitle : 'Booking #${b.id}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isHosting)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'INCOMING FLEET',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${dateFormat.format(b.startDate)} - ${dateFormat.format(b.endDate)} • ₹${b.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isHosting ? 'Host: $displayName' : displayName,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isHosting || b.hasCustomerDetails) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF19232F) : const Color(0xFFF2F7FB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Customer: ${b.customerName.isNotEmpty ? b.customerName : "Rider"}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (b.customerPhone.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• ${b.customerPhone}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'View Dossier',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.lightBlueAccent : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: isDark ? Colors.lightBlueAccent : AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // MODAL: CHILD ACCOUNT DETAILS
  // ==========================================
  void _showChildDetailsModal(
    BuildContext context,
    AppState appState,
    ChildProfile child,
    bool isDark,
  ) {
    final cVehicles = appState.getVehiclesHostedByChild(child.childId);
    final cBookings = appState.getBookingsForChild(child.childId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.purple.withOpacity(0.15),
                  backgroundImage: child.profilePhoto.isNotEmpty
                      ? NetworkImage(child.profilePhoto)
                      : null,
                  child: child.profilePhoto.isEmpty
                      ? Text(
                          child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CHILD PROFILE',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(child.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (child.phone.isNotEmpty)
                        Text('📞 ${child.phone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Metadata summary cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fleet Hosted', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          '${cVehicles.length} Vehicles',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bookings Recorded', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          '${cBookings.length} Bookings',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      appState.switchAccount(child.childId);
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Switch to this Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showUnlinkConfirmationDialog(context, appState, child);
                  },
                  icon: const Icon(Icons.link_off, size: 16, color: Colors.red),
                  label: const Text('Unlink', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONFIRMATION: UNLINK CHILD ACCOUNT
  // ==========================================
  void _showUnlinkConfirmationDialog(
    BuildContext context,
    AppState appState,
    ChildProfile child,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Unlink Child Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${child.name}" from your Mother Hub?\n\nThis frees up 1 child account slot. Their vehicle listings and past bookings will remain intact.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await appState.deleteChildAccount(child.childId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.success
                          ? 'Child account "${child.name}" unlinked successfully.'
                          : (res.error ?? 'Failed to unlink child account.'),
                    ),
                    backgroundColor: res.success ? Colors.green.shade700 : Colors.red.shade800,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Unlink Account'),
          ),
        ],
      ),
    );
  }
}
