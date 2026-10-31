import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/whatsapp_launcher_service.dart';

class WhatsAppLogo extends StatelessWidget {
  final double size;

  const WhatsAppLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset('public/wp.jpg', width: size, height: size, fit: BoxFit.cover),
    );
  }
}

/// Floating contact button for a listing. Falls back to the host's profile number.
class WhatsAppFloatingButton extends StatelessWidget {
  final String phone;
  final String hostId;
  final String message;

  const WhatsAppFloatingButton({
    super.key,
    required this.phone,
    required this.hostId,
    required this.message,
  });

  Future<void> _open(BuildContext context) async {
    var target = phone;
    if (!WhatsAppLauncherService.isUsablePhone(target) && hostId.isNotEmpty) {
      final service = Provider.of<AppState>(context, listen: false).supabaseService;
      target = (await service.getUserProfile(hostId))?.phoneNumber ?? '';
    }
    if (!context.mounted) return;
    if (!WhatsAppLauncherService.isUsablePhone(target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This host has not added a WhatsApp number yet. Please use in-app chat.')),
      );
      return;
    }
    await WhatsAppLauncherService.launchWhatsApp(phoneNumber: target, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Message on WhatsApp',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(context),
          child: const Padding(padding: EdgeInsets.all(4), child: WhatsAppLogo(size: 48)),
        ),
      ),
    );
  }
}
