// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/supabase_auth_dialog.dart';
import '../widgets/advanced_feedback_modal.dart';
import '../widgets/native_language_selector_dialog.dart';
import '../widgets/tr_text.dart';
import '../i18n/strings.g.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'feedback_dashboard_screen.dart';
import '../widgets/account_switcher_dialog.dart';
import '../widgets/create_child_account_dialog.dart';
import '../widgets/link_existing_account_dialog.dart';
import '../widgets/mother_child_account_card.dart';
import '../widgets/user_avatar.dart';
import 'admin/admin_layout_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = appState.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Firebase User Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.outlineVariantDark
                    : AppColors.outlineVariantLight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;

                final avatarWidget = Stack(
                  children: [
                    UserAvatar(
                      photoUrl: appState.activeUserPhotoUrl,
                      displayName: appState.activeUserDisplayName,
                      radius: 34,
                      backgroundColor: appState.isSignedIn
                          ? AppColors.primary
                          : Colors.grey,
                      onTap: appState.isSignedIn
                          ? () => _pickAndUploadAvatar(context, appState)
                          : null,
                    ),
                    if (appState.isSignedIn)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _pickAndUploadAvatar(context, appState),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                final userInfoWidget = Column(
                  crossAxisAlignment: isNarrow
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          appState.isSignedIn
                              ? appState.activeUserDisplayName
                              : 'Guest User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (appState.isSignedIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: appState.activeUserRole == 'Host'
                                  ? Colors.purple.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appState.activeUserRole.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: appState.activeUserRole == 'Host'
                                    ? Colors.purple.shade900
                                    : Colors.blue.shade900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appState.isSignedIn
                          ? appState.activeUserEmail
                          : 'Sign in to access rentals & tours',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (profile?.phoneNumber.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        '📞 ${profile!.phoneNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (appState.isSignedIn) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield,
                              size: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Trust Score: ${appState.activeUserTrustScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (profile?.role == 'Admin') ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLayoutScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings, size: 16),
                          label: const Text('Admin Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ] else
                      ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const SupabaseAuthDialog(),
                        ),
                        icon: const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Sign In with Supabase',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                );

                return Column(
                  children: [
                    if (isNarrow) ...[
                      Center(child: avatarWidget),
                      const SizedBox(height: 12),
                      userInfoWidget,
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatarWidget,
                          const SizedBox(width: 14),
                          Expanded(child: userInfoWidget),
                        ],
                      ),
                    ],
                    if (profile?.bio.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bio: ${profile!.bio}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],

                    if (appState.isSignedIn) ...[
                      const Divider(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _showEditProfileDialog(context, appState),
                              icon: const Icon(Icons.edit, size: 16),
                              label: TrText(t.profile.editProfile),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                await appState.toggleUserRole();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Switched to ${appState.activeUserRole} Mode',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: TrText(
                                appState.activeUserRole == 'Host'
                                    ? 'Switch to Rider'
                                    : 'Become a Host',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Mother - Child Account Architecture & Switcher Card
          if (appState.isSignedIn || appState.savedAccounts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const MotherChildAccountCard(),
          ],

          const SizedBox(height: 24),

          // Quick Navigation Menu
          TrText(
            t.profile.accountPreferences,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          _buildProfileMenuTile(
            context,
            t.profile.darkMode,
            t.profile.darkModeSubtitle,
            Icons.dark_mode_outlined,
            trailing: Switch(
              value: isDark,
              onChanged: (_) => appState.toggleTheme(),
              activeColor: AppColors.secondary,
            ),
          ),

          Consumer<LanguageProvider>(
            builder: (context, langProvider, _) {
              return _buildProfileMenuTile(
                context,
                t.profile.language,
                'Active: ${langProvider.activeLanguage.nativeName} (${langProvider.activeLanguage.flagEmoji})',
                Icons.g_translate_outlined,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NativeLanguageSelectorDialog(),
                  );
                },
              );
            },
          ),

          if (appState.isSignedIn)
            _buildProfileMenuTile(
              context,
              t.profile.passwordReset,
              t.profile.passwordResetSubtitle,
              Icons.lock_reset_outlined,
              onTap: () async {
                try {
                  await appState.supabaseAuthService.sendPasswordResetEmail(
                    appState.activeUserEmail,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password reset email sent to ${appState.activeUserEmail}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),

          _buildProfileMenuTile(
            context,
            t.profile.documents,
            t.profile.documentsSubtitle,
            Icons.badge_outlined,
            onTap: () =>
                appState.setNavIndex(14), // Documents & Licenses screen
          ),

          _buildProfileMenuTile(
            context,
            t.profile.trustReputation,
            t.profile.trustReputationSubtitle,
            Icons.shield_outlined,
            onTap: () => appState.setNavIndex(15), // Kinetic trust screen
          ),

          _buildProfileMenuTile(
            context,
            t.profile.financials,
            t.profile.financialsSubtitle,
            Icons.account_balance_outlined,
            onTap: () => appState.setNavIndex(9), // Earnings
          ),

          _buildProfileMenuTile(
            context,
            t.profile.aiGenerator,
            t.profile.aiGeneratorSubtitle,
            Icons.auto_awesome_outlined,
            onTap: () => appState.setNavIndex(12), // AI generator
          ),

          _buildProfileMenuTile(
            context,
            t.profile.inAppPortal,
            t.profile.inAppPortalSubtitle,
            Icons.language,
            onTap: () => appState.setNavIndex(17), // Web View Portal
          ),

          _buildProfileMenuTile(
            context,
            t.profile.feedback,
            t.profile.feedbackSubtitle,
            Icons.rate_review_outlined,
            onTap: () {
              if (!appState.isSignedIn) {
                showDialog(
                  context: context,
                  builder: (_) => const SupabaseAuthDialog(),
                );
                return;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AdvancedFeedbackModal(),
              );
            },
          ),

          _buildProfileMenuTile(
            context,
            t.profile.feedbackInsights,
            t.profile.feedbackInsightsSubtitle,
            Icons.analytics_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FeedbackDashboardScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Logout
          if (appState.isSignedIn)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await appState.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged Out of Supabase Session'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: TrText(
                  t.profile.logout,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController(
      text: appState.activeUserDisplayName,
    );
    final phoneCtrl = TextEditingController(
      text: appState.userProfile?.phoneNumber ?? '',
    );
    final bioCtrl = TextEditingController(
      text: appState.userProfile?.bio ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newBio = bioCtrl.text.trim();

              // Close the dialog immediately
              Navigator.of(ctx, rootNavigator: true).pop();

              // Trigger state & backend update
              await appState.updateUserProfileDetails(
                displayName: newName,
                phoneNumber: newPhone,
                bio: newBio,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.outlineVariantDark
              : AppColors.outlineVariantLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TrText(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      TrText(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ] else ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    AppState appState,
  ) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile avatar photo...')),
        );
        final bytes = await file.readAsBytes();
        final fileName =
            'avatar_${appState.userProfile?.uid ?? appState.supabaseUser?.id ?? 'user'}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // 1. Try ImageKit upload
        String? avatarUrl = await appState.imageKitService.uploadImage(
          bytes: bytes,
          fileName: fileName,
          folder: '/avatars',
        );

        // 2. Fallback to Supabase Storage if ImageKit failed
        if (avatarUrl == null || avatarUrl.isEmpty) {
          avatarUrl = await appState.supabaseService.uploadImageToSupabaseStorage(
            bytes: bytes,
            fileName: fileName,
            bucket: 'vehicles',
          );
        }

        // 3. Fallback to base64 data URI if network uploads failed
        if (avatarUrl == null || avatarUrl.isEmpty) {
          avatarUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }

        await appState.updateUserProfileDetails(photoUrl: avatarUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile avatar photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting avatar photo: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Widget _buildAccountArchitectureCard(BuildContext context, AppState appState, bool isDark) {
    final childCount = appState.childProfiles.length;
    final hasReachedLimit = childCount >= 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    appState.isMotherAccount ? Icons.family_restroom_rounded : Icons.person_rounded,
                    color: appState.isMotherAccount ? AppColors.primary : Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ACCOUNT ARCHITECTURE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (appState.isMotherAccount ? AppColors.primary : Colors.purple).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appState.isMotherAccount ? 'Primary Profile' : 'Sub Profile',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: appState.isMotherAccount ? AppColors.primary : Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Account Pill & Quick Switch button
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: appState.isMotherAccount
                    ? [
                        AppColors.primary.withOpacity(0.12),
                        AppColors.primary.withOpacity(0.04),
                      ]
                    : [
                        Colors.purple.withOpacity(0.12),
                        Colors.purple.withOpacity(0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (appState.isMotherAccount ? AppColors.primary : Colors.purple).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                UserAvatar(
                  photoUrl: appState.activeUserPhotoUrl,
                  displayName: appState.activeUserDisplayName,
                  radius: 20,
                  backgroundColor: appState.isMotherAccount ? AppColors.primary : Colors.purple,
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
                              '${appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName : "Account"} (${appState.isMotherAccount ? "M" : "C"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        appState.activeUserEmail,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => AccountSwitcherDialog.show(context),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                  label: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appState.isMotherAccount ? AppColors.primary : Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mother Mode: Linked Children List & Actions
          if (appState.isMotherAccount) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LINKED CHILD PROFILES',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.9, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasReachedLimit ? Colors.red.withOpacity(0.12) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$childCount / 3 Used',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: hasReachedLimit ? Colors.red.shade800 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (appState.childProfiles.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowestDark : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                ),
                child: const Text(
                  'No child accounts created yet. You can create or link up to 3 independent accounts.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ] else ...[
              ...appState.childProfiles.map((child) {
                final childVehicles = appState.getVehiclesHostedByChild(child.childId);
                final childBookings = appState.getBookingsForChild(child.childId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerLowestDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.purple.withOpacity(0.15),
                            child: Text(
                              child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      child.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Child', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple)),
                                    ),
                                  ],
                                ),
                                Text(
                                  child.email,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => appState.switchAccount(child.childId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.withOpacity(0.12),
                              foregroundColor: Colors.purple,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Hosting & Booking Metrics
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: childVehicles.isNotEmpty
                                  ? Colors.teal.withOpacity(0.12)
                                  : (isDark ? Colors.white10 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_car, size: 12, color: childVehicles.isNotEmpty ? Colors.teal : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${childVehicles.length} Hosted ${childVehicles.length == 1 ? "Vehicle" : "Vehicles"}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: childVehicles.isNotEmpty ? (isDark ? Colors.tealAccent : Colors.teal.shade800) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: childBookings.isNotEmpty
                                  ? Colors.blue.withOpacity(0.12)
                                  : (isDark ? Colors.white10 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long, size: 12, color: childBookings.isNotEmpty ? Colors.blue : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${childBookings.length} ${childBookings.length == 1 ? "Booking" : "Bookings"}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: childBookings.isNotEmpty ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade800) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (childVehicles.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: childVehicles.take(3).map((v) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white12 : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '• ${v.title} (\$${v.pricePerDay.toStringAsFixed(0)}/d)',
                                style: const TextStyle(fontSize: 9),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 10),

            // Action Buttons for Mother Profile
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasReachedLimit
                        ? null
                        : () => showDialog(
                              context: context,
                              builder: (_) => const CreateChildAccountDialog(),
                            ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('+ Create Child', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasReachedLimit
                        ? null
                        : () => showDialog(
                              context: context,
                              builder: (_) => const LinkExistingAccountDialog(),
                            ),
                    icon: const Icon(Icons.link, size: 14),
                    label: const Text('Link Account', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildChildBookingsDashboard(context, appState, isDark),
          ] else ...[
            // Child Mode Notice & Switch to Mother
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: Colors.purple),
                      SizedBox(width: 6),
                      Text(
                        'Independent Child Account Mode',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your bookings and hosting fleet are completely private and separated from other accounts.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => appState.switchAccount(appState.activeMotherId),
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: const Text('Switch back to Mother Profile', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildBookingsDashboard(BuildContext context, AppState appState, bool isDark) {
    final childBookings = appState.childAccountBookings;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : Colors.purple.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, size: 16, color: Colors.purple),
                  SizedBox(width: 6),
                  Text(
                    'CHILD ACCOUNTS BOOKINGS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.9,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: childBookings.isNotEmpty
                      ? Colors.purple.withOpacity(0.12)
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${childBookings.length} Recorded',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: childBookings.isNotEmpty ? Colors.purple : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (childBookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : Colors.purple.shade50.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_note_outlined, size: 28, color: Colors.purple.withOpacity(0.5)),
                  const SizedBox(height: 6),
                  const Text(
                    'No vehicle bookings from child profiles yet',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'When any vehicle booking is made by a linked child account (or when a child\'s vehicle is booked), full rental details, dates, and unlock PINs will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ...childBookings.map((b) {
              final child = appState.getChildProfileForBooking(b);
              final isHostBooking = child != null && b.hostId == child.childId;
              final statusLower = b.status.toLowerCase();
              final statusColor = statusLower == 'active'
                  ? Colors.green
                  : (statusLower == 'confirmed'
                      ? Colors.blue
                      : (statusLower == 'pending' ? Colors.orange : Colors.grey));

              final startStr = dateFormat.format(b.startDate);
              final endStr = dateFormat.format(b.endDate);
              final childDisplayName = child?.name.isNotEmpty == true
                  ? child!.name
                  : (b.accountName.isNotEmpty ? b.accountName : 'Child Account');

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : Colors.purple.shade50.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.outlineVariantDark : Colors.purple.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            b.vehicleImageUrl,
                            width: 50,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 50,
                              height: 38,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.directions_car, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.vehicleTitle,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isHostBooking
                                          ? 'Host: $childDisplayName'
                                          : 'Rider: $childDisplayName',
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '₹${b.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b.status.toUpperCase(),
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$startStr → $endStr',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        ),
                        const Spacer(),
                        if (b.unlockPasscode.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.key, size: 10, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  'PIN: ${b.unlockPasscode}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showChildBookingDetailsModal(context, b, child, appState),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View Full Details', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ),
                        if (child != null) ...[
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () => appState.switchAccount(child.childId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.withOpacity(0.15),
                              foregroundColor: Colors.purple,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Switch to Child', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showChildBookingDetailsModal(BuildContext context, Booking booking, ChildProfile? child, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Child Booking Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      child?.name ?? (booking.accountName.isNotEmpty ? booking.accountName : 'Child'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Vehicle Snapshot
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      booking.vehicleImageUrl,
                      width: 70,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 70,
                        height: 52,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.directions_car),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.vehicleTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Host / Provider: ${booking.hostName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('Booking ID: ${booking.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Dates & Financials
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RENTAL PERIOD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('${dateFormat.format(booking.startDate)} -', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(dateFormat.format(booking.endDate), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TOTAL RENTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text('Status: ${booking.status}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Keyless Passcode Box
              if (booking.unlockPasscode.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DIGITAL KEYLESS UNLOCK PIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                          const SizedBox(height: 2),
                          Text(booking.unlockPasscode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4)),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: booking.unlockPasscode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unlock PIN copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18, color: Colors.amber),
                        tooltip: 'Copy PIN',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  if (child != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          appState.switchAccount(child.childId);
                        },
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Switch Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
