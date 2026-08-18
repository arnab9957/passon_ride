import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/supabase_auth_dialog.dart';

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
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: appState.isSignedIn ? () => _pickAndUploadAvatar(context, appState) : null,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: appState.isSignedIn ? AppColors.primary : Colors.grey,
                            backgroundImage: appState.activeUserPhotoUrl.isNotEmpty
                                ? NetworkImage(appState.imageKitService.buildImageUrl(appState.activeUserPhotoUrl))
                                : null,
                            child: appState.activeUserPhotoUrl.isEmpty
                                ? Text(
                                    appState.activeUserDisplayName.isNotEmpty
                                        ? appState.activeUserDisplayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
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
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appState.isSignedIn ? appState.activeUserDisplayName : 'Guest User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (appState.isSignedIn)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          const SizedBox(height: 2),
                          Text(
                            appState.isSignedIn ? appState.activeUserEmail : 'Sign in to access rentals & tours',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (profile?.phoneNumber.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              '📞 ${profile!.phoneNumber}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (appState.isSignedIn)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(color: Colors.green.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shield, size: 12, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Trust Score: ${appState.activeUserTrustScore.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => const SupabaseAuthDialog(),
                              ),
                              icon: const Icon(Icons.lock_outline, size: 16, color: Colors.white),
                              label: const Text('Sign In with Supabase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile?.bio.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bio: ${profile!.bio}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                ],
                if (appState.isSignedIn) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditProfileDialog(context, appState),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profile'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await appState.toggleUserRole();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Switched to ${appState.activeUserRole} Mode')),
                            );
                          }
                        },
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: Text(appState.activeUserRole == 'Host' ? 'Switch to Rider' : 'Become a Host'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Navigation Menu
          const Text('Account & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _buildProfileMenuTile(
            context,
            'Dark Mode Theme',
            'Toggle dark or light app theme',
            Icons.dark_mode_outlined,
            trailing: Switch(
              value: isDark,
              onChanged: (_) => appState.toggleTheme(),
              activeColor: AppColors.secondary,
            ),
          ),

          if (appState.isSignedIn)
            _buildProfileMenuTile(
              context,
              'Password Reset',
              'Send security password reset email',
              Icons.lock_reset_outlined,
              onTap: () async {
                try {
                  await appState.supabaseAuthService.sendPasswordResetEmail(appState.activeUserEmail);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password reset email sent to ${appState.activeUserEmail}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),

          _buildProfileMenuTile(
            context,
            'Documents & Licenses',
            'Driving license, Aadhar card & government ID',
            Icons.badge_outlined,
            onTap: () => appState.setNavIndex(14), // Documents & Licenses screen
          ),

          _buildProfileMenuTile(
            context,
            'Kinetic Trust Reputation',
            'View trust score breakdown & badges',
            Icons.shield_outlined,
            onTap: () => appState.setNavIndex(15), // Kinetic trust screen
          ),

          _buildProfileMenuTile(
            context,
            'Provider Financials',
            'Earnings, payouts & banking info',
            Icons.account_balance_outlined,
            onTap: () => appState.setNavIndex(9), // Earnings
          ),

          _buildProfileMenuTile(
            context,
            'AI Tour Generator',
            'Create itinerary using AI Co-Pilot',
            Icons.auto_awesome_outlined,
            onTap: () => appState.setNavIndex(12), // AI generator
          ),

          _buildProfileMenuTile(
            context,
            'In-App Web Portal',
            'Embed and view any external website directly',
            Icons.language,
            onTap: () => appState.setNavIndex(17), // Web View Portal
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
                      const SnackBar(content: Text('Logged Out of Supabase Session')),
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Log Out Supabase Session', style: TextStyle(color: Colors.redAccent)),
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
    final nameCtrl = TextEditingController(text: appState.activeUserDisplayName);
    final phoneCtrl = TextEditingController(text: appState.userProfile?.phoneNumber ?? '');
    final bioCtrl = TextEditingController(text: appState.userProfile?.bio ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline)),
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
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newBio = bioCtrl.text.trim();

              // Close the dialog immediately
              Navigator.of(ctx, rootNavigator: true).pop();

              // Trigger state & backend update
              appState.updateUserProfileDetails(
                displayName: newName,
                phoneNumber: newPhone,
                bio: newBio,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
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
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildServiceStatusRow({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String statusText,
    required bool isOk,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          children: [
            Icon(isOk ? Icons.check_circle : Icons.error, size: 12, color: isOk ? Colors.green : Colors.red),
            const SizedBox(width: 4),
            Text(statusText, style: TextStyle(fontSize: 10, color: isOk ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, AppState appState) async {
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
        final ikUrl = await appState.imageKitService.uploadImage(
          bytes: bytes,
          fileName: 'avatar_${appState.userProfile?.uid ?? appState.supabaseUser?.id ?? 'user'}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folder: '/avatars',
        );

        final avatarUrl = ikUrl ?? 'data:image/jpeg;base64,${bytes}';
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
          SnackBar(content: Text('Error selecting avatar photo: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }
}

