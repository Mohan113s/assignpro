import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../features/settings/models/app_settings.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppProvider>().settings;
    _companyCtrl = TextEditingController(text: settings.companyName);
    _phoneCtrl = TextEditingController(text: settings.adminSupportPhone);
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await context.read<AppProvider>().updateSettings(
      AppSettings(
        companyName: _companyCtrl.text.trim(),
        adminSupportPhone: _phoneCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    AppSnackbar.success(context, 'Settings saved successfully!');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Administrator',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Company Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      prefixIcon: Icon(Icons.business_rounded, size: 20),
                    ),
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Company name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Admin Support Phone',
                      hintText: '+91 9640898061',
                      prefixIcon: Icon(Icons.support_agent_rounded, size: 20),
                      helperText:
                          'Users will call this number via "Contact Admin"',
                    ),
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Phone number is required'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'System Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Users',
                  value: provider.totalUsers.toString(),
                  icon: Icons.people_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  label: 'Total Leads',
                  value: provider.totalLeads.toString(),
                  icon: Icons.contacts_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
