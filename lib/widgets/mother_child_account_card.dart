// ignore_for_file: deprecated_member_use, unnecessary_underscores, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'account_switcher_dialog.dart';
import 'create_child_account_dialog.dart';
import 'link_existing_account_dialog.dart';
import 'user_avatar.dart';

/// Modern, responsive, and user-friendly viewer for Mother & Child Profile Architecture.
class MotherChildAccountCard extends StatefulWidget {
  const MotherChildAccountCard({super.key});

  @override
  State<MotherChildAccountCard> createState() => _MotherChildAccountCardState();
}

class _MotherChildAccountCardState extends State<MotherChildAccountCard> {

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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header + Visual Slot Gauge
                      _buildSlotsHeader(context, childCount, hasReachedLimit, isDark),
                      const SizedBox(height: 12),

                      // Responsive 3-Slot Visual Grid
                      _buildThreeSlotsGrid(
                        context,
                        appState,
                        childProfiles,
                        isDark,
                        isWide,
                        isTablet,
                      ),
                      if (!hasReachedLimit) ...[
                        const SizedBox(height: 8),
                        // Quick Action Buttons
                        _buildActionButtons(context, hasReachedLimit, isDark, isWide),
                      ],
                    ],
                  ),
                ),

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
                    child: UserAvatar(
                      photoUrl: appState.activeUserPhotoUrl,
                      displayName: appState.activeUserDisplayName,
                      radius: 26,
                      backgroundColor: activeColor,
                      fontSize: 18,
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
                        isMother ? 'M' : 'C',
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
                      '${appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName : "Account"} (${isMother ? "M" : "C"})',
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
        Expanded(
          child: Column(
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
                  fontSize: 10.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

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
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (hasReachedLimit ? Colors.red : Colors.purple)
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                );
              }),
              const SizedBox(width: 2),
              Text(
                '$childCount / 3',
                style: TextStyle(
                  fontSize: 10.5,
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
  // RESPONSIVE 3-SLOT LIST / GRID
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slots,
    );
  }

  // ==========================================
  // OCCUPIED SLOT CARD (Compact & Sleek)
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLowestDark
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentActive
              ? (isDark ? Colors.purpleAccent.withOpacity(0.6) : Colors.purple)
              : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
          width: isCurrentActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentActive
                ? Colors.purple.withOpacity(0.08)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: isCurrentActive ? 8 : 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isCurrentActive ? null : () => appState.switchAccount(child.childId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 1. Avatar with Slot # Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: Colors.purple.withOpacity(0.12),
                      backgroundImage: AppState.getImageProvider(child.profilePhoto),
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
                    Positioned(
                      right: -3,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isCurrentActive ? Colors.green : Colors.purple,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isDark
                                ? AppColors.surfaceContainerLowestDark
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '#$slotNumber',
                          style: const TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // 2. Identity Info & Inline Metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              child.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        child.email,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _buildMicroMetric(
                            icon: Icons.directions_car_rounded,
                            label: '${childVehicles.length} Fleet',
                            color: childVehicles.isNotEmpty ? Colors.teal : Colors.grey,
                            isDark: isDark,
                            isActive: childVehicles.isNotEmpty,
                          ),
                          const SizedBox(width: 6),
                          _buildMicroMetric(
                            icon: Icons.receipt_long_rounded,
                            label: '${childBookings.length} Bookings',
                            color: childBookings.isNotEmpty ? Colors.blue : Colors.grey,
                            isDark: isDark,
                            isActive: childBookings.isNotEmpty,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Trailing Switch Action / Active Pill & Menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrentActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => appState.switchAccount(child.childId),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 13),
                        label: const Text(
                          'Switch',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 2),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MICRO METRIC PILL (Fleet & Booking counter)
  // ==========================================
  Widget _buildMicroMetric({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.1)
            : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? (isDark ? color : color.withOpacity(0.9))
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY SLOT CARD (Compact Add / Link Row)
  // ==========================================
  Widget _buildEmptySlotCard(
    BuildContext context,
    int slotNumber,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLowestDark.withOpacity(0.4)
            : Colors.grey.shade50.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark.withOpacity(0.6) : Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              size: 17,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'SLOT #$slotNumber',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AVAILABLE',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Add an independent child account',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CreateChildAccountDialog(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '+ Create',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const LinkExistingAccountDialog(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: Colors.purple.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '🔗 Link',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.purple),
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
    if (hasReachedLimit) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const CreateChildAccountDialog(),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 14),
            label: const Text(
              'Create Child',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LinkExistingAccountDialog(),
            ),
            icon: const Icon(Icons.link_rounded, size: 14),
            label: const Text(
              'Link Account',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: BorderSide(color: Colors.purple.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
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
                  backgroundImage: AppState.getImageProvider(child.profilePhoto),
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
                              'LINKED PROFILE (C)',
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
