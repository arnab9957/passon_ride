// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'create_child_account_dialog.dart';
import 'link_existing_account_dialog.dart';
import 'user_avatar.dart';

class AccountSwitcherDialog extends StatelessWidget {
  const AccountSwitcherDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 580),
      builder: (_) => const AccountSwitcherDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childCount = appState.childProfiles.length;
    final hasReachedLimit = childCount >= 3;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.switch_account_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch Account',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Manage & Switch Linked Profiles',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Account Section
              const Text(
                'ACTIVE ACCOUNT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Active Account Card (Highlighted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: appState.isMotherAccount
                        ? [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.05),
                          ]
                        : [
                            Colors.purple.withOpacity(0.15),
                            Colors.purple.withOpacity(0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: appState.isMotherAccount ? AppColors.primary : Colors.purple,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      photoUrl: appState.activeUserPhotoUrl,
                      displayName: appState.activeUserDisplayName,
                      radius: 24,
                      backgroundColor: appState.isMotherAccount ? AppColors.primary : Colors.purple,
                      fontSize: 16,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName : "Account"} (${appState.isMotherAccount ? "M" : "C"})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appState.activeUserEmail,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Available Accounts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OTHER ACCOUNTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasReachedLimit ? Colors.red.withOpacity(0.12) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: hasReachedLimit ? Colors.red.shade300 : Colors.blue.shade200),
                    ),
                    child: Text(
                      '$childCount / 3 Child Accounts Used',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasReachedLimit ? Colors.red.shade900 : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 1. Mother Account Option (if not currently active)
              if (!appState.isMotherAccount && appState.motherProfile != null) ...[
                _buildAccountTile(
                  context,
                  title: '${appState.motherProfile!.name.isNotEmpty ? appState.motherProfile!.name : 'Account'} (M)',
                  subtitle: appState.motherProfile!.email,
                  photoUrl: appState.motherProfile!.profilePhoto,
                  tagColor: AppColors.primary,
                  isCurrent: false,
                  onTap: () async {
                    await appState.switchAccount(appState.activeMotherId);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],

              // 2. Child Accounts List
              if (appState.childProfiles.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerLowestDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                  ),
                  child: const Center(
                    child: Text(
                      'No child accounts created yet. You can create up to 3 independent child accounts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ] else ...[
                ...appState.childProfiles.map((child) {
                  final isChildActive = appState.isChildAccount && appState.activeAccountId == child.childId;
                  if (isChildActive) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildAccountTile(
                      context,
                      title: '${child.name} (C)',
                      subtitle: child.email,
                      photoUrl: child.profilePhoto,
                      tagColor: Colors.purple,
                      isCurrent: isChildActive,
                      onTap: () async {
                        await appState.switchAccount(child.childId);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }),
              ],

              const Divider(height: 28),

              // Action Buttons: Create Child & Link Account
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasReachedLimit
                          ? null
                          : () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => const CreateChildAccountDialog(),
                              );
                            },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ Create Child', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
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
                          : () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => const LinkExistingAccountDialog(),
                              );
                            },
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Link Existing', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              if (hasReachedLimit) ...[
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'You have reached the maximum limit of 3 child accounts.',
                    style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String photoUrl,
    required Color tagColor,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: isCurrent ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerLowestDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? tagColor
                : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: tagColor.withOpacity(0.15),
              backgroundImage: AppState.getImageProvider(photoUrl),
              child: photoUrl.isEmpty
                  ? Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: tagColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
