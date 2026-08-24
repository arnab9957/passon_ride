import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

/// Modal Dialog for Selecting Native Languages & Configuring LibreTranslate Server URL
class NativeLanguageSelectorDialog extends StatefulWidget {
  const NativeLanguageSelectorDialog({super.key});

  @override
  State<NativeLanguageSelectorDialog> createState() => _NativeLanguageSelectorDialogState();
}

class _NativeLanguageSelectorDialogState extends State<NativeLanguageSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();
  bool _showServerConfig = false;

  @override
  void initState() {
    super.initState();
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _serverController.text = langProvider.serverUrl;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final search = _searchController.text.toLowerCase().trim();

    final filteredLanguages = LanguageProvider.supportedLanguages.where((l) {
      return l.englishName.toLowerCase().contains(search) ||
          l.nativeName.toLowerCase().contains(search) ||
          l.code.toLowerCase().contains(search);
    }).toList();

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariantLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.g_translate_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Native Language Converter',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Powered by LibreTranslate Engine',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariantLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showServerConfig = !_showServerConfig;
                      });
                    },
                    icon: Icon(
                      _showServerConfig ? Icons.close : Icons.dns_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    tooltip: 'LibreTranslate Server Config',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // LibreTranslate Server Config Panel (optional collapse)
              if (_showServerConfig) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dns, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          const Text(
                            'Self-Hosted LibreTranslate Server URL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _serverController,
                        decoration: InputDecoration(
                          hintText: 'http://localhost:5000',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            langProvider.setServerUrl(_serverController.text.trim());
                            setState(() => _showServerConfig = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('LibreTranslate server set to ${_serverController.text.trim()}')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Save Server URL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search native language (e.g. Hindi, Bengali, Spanish...)',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outlineVariantLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Language List Items
              Expanded(
                child: ListView.separated(
                  itemCount: filteredLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filteredLanguages[index];
                    final isSelected = langProvider.currentLanguageCode == item.code;

                    return Material(
                      color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.6) : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          langProvider.setLanguage(item.code);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Text(item.flagEmoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nativeName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.primary : AppColors.onSurfaceLight,
                                      ),
                                    ),
                                    Text(
                                      item.englishName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariantLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
