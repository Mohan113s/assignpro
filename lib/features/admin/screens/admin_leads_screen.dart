import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../features/leads/models/lead_model.dart';

class AdminLeadsScreen extends StatefulWidget {
  const AdminLeadsScreen({super.key});

  @override
  State<AdminLeadsScreen> createState() => _AdminLeadsScreenState();
}

class _AdminLeadsScreenState extends State<AdminLeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isDistributing = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _importCSV() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final lines = content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // Skip header if present
      int start = 0;
      if (lines.isNotEmpty) {
        final firstFields = lines[0].split(',');
        if (firstFields.any(
          (f) =>
              f.toLowerCase().contains('name') ||
              f.toLowerCase().contains('phone'),
        )) {
          start = 1;
        }
      }

      final leads = <LeadModel>[];
      for (int i = start; i < lines.length; i++) {
        final cols = lines[i].split(',');
        if (cols.isEmpty) continue;

        String phone = '';
        String name = '';

        if (cols.length == 1) {
          phone = cols[0].trim().replaceAll('"', '');
        } else {
          name = cols[0].trim().replaceAll('"', '');
          phone = cols[1].trim().replaceAll('"', '');
        }

        if (phone.isEmpty) continue;

        leads.add(LeadModel(customerName: name, phoneNumber: phone));
      }

      if (!mounted) return;

      if (leads.isEmpty) {
        AppSnackbar.error(context, 'No valid leads found in the CSV file.');
        setState(() => _isImporting = false);
        return;
      }

      await context.read<AppProvider>().importLeads(leads);

      if (mounted) {
        AppSnackbar.success(
          context,
          '${leads.length} leads imported successfully!',
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _distribute() async {
    final provider = context.read<AppProvider>();
    if (provider.totalLeads == 0) {
      AppSnackbar.error(context, 'No leads to distribute.');
      return;
    }
    if (provider.regularUsers.where((u) => u.isActive).isEmpty) {
      AppSnackbar.error(context, 'No active users to assign leads to.');
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Distribute Leads',
      content:
          'This will redistribute ALL ${provider.totalLeads} leads equally among '
          '${provider.regularUsers.where((u) => u.isActive).length} active users. '
          'Existing assignments will be reset. Continue?',
      confirmText: 'Distribute',
      confirmColor: AppTheme.primaryBlue,
    );

    if (!confirmed) return;
    setState(() => _isDistributing = true);

    final count = await provider.distributeLeads();
    if (mounted) {
      setState(() => _isDistributing = false);
      AppSnackbar.success(context, '$count leads distributed successfully!');
    }
  }

  Future<void> _clearLeads() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clear All Leads',
      content:
          'This will permanently delete ALL leads. This action cannot be undone.',
      confirmText: 'Clear All',
    );
    if (confirmed && mounted) {
      await context.read<AppProvider>().clearAllLeads();
      AppSnackbar.success(context, 'All leads cleared.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allLeads = provider.leads
        .where(
          (l) =>
              l.customerName.toLowerCase().contains(_query) ||
              l.phoneNumber.contains(_query),
        )
        .toList();
    final assignedLeads = allLeads.where((l) => l.isAssigned).toList();
    final unassignedLeads = allLeads.where((l) => !l.isAssigned).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          // Action bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.upload_file_rounded,
                        label: 'Import CSV',
                        onTap: _isImporting ? null : _importCSV,
                        loading: _isImporting,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.shuffle_rounded,
                        label: 'Distribute',
                        onTap: _isDistributing ? null : _distribute,
                        loading: _isDistributing,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear',
                      onTap: _clearLeads,
                      color: AppTheme.errorColor,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search leads...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryBlue.withOpacity(0.05),
            child: Row(
              children: [
                Text(
                  'Total: ${provider.totalLeads}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Assigned: ${provider.totalAssignedLeads}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Remaining: ${provider.totalUnassignedLeads}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Assigned (${assignedLeads.length})'),
                Tab(text: 'Unassigned (${unassignedLeads.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _LeadsList(leads: assignedLeads, showUser: true),
                _LeadsList(leads: unassignedLeads, showUser: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool loading;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = AppTheme.primaryBlue,
    this.loading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 12)
              : const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _LeadsList extends StatelessWidget {
  final List<LeadModel> leads;
  final bool showUser;

  const _LeadsList({required this.leads, required this.showUser});

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.contacts_outlined,
        title: 'No leads here',
        subtitle: showUser
            ? 'Distribute leads to see assigned ones'
            : 'All leads have been assigned',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (_, i) {
        final lead = leads[i];
        final provider = context.read<AppProvider>();
        final user = lead.assignedUserId != null
            ? provider.getUserById(lead.assignedUserId!)
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.customerName.isNotEmpty
                          ? lead.customerName
                          : 'Unknown Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      lead.phoneNumber,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (showUser && user != null)
                      Text(
                        'Assigned to: ${user.name}',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              StatusChip(status: lead.status),
            ],
          ),
        );
      },
    );
  }
}
