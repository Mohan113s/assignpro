import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../features/leads/models/lead_model.dart';
import '../../../features/auth/models/user_model.dart';

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
  bool _isImporting = false;

  // Multi-select for manual assignment
  final Set<String> _selectedLeadIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        _selectedLeadIds.clear();
        _selectionMode = false;
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedLeadIds.contains(id)) {
        _selectedLeadIds.remove(id);
      } else {
        _selectedLeadIds.add(id);
      }
      _selectionMode = _selectedLeadIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedLeadIds.clear();
      _selectionMode = false;
    });
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
          '${leads.length} leads imported! Now assign them to users.',
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showAssignDialog(List<LeadModel> selectedLeads) async {
    final provider = context.read<AppProvider>();
    final activeUsers = provider.regularUsers.where((u) => u.isActive).toList();

    if (activeUsers.isEmpty) {
      AppSnackbar.error(context, 'No active users found. Create users first.');
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AssignBottomSheet(
        selectedLeads: selectedLeads,
        activeUsers: activeUsers,
        onAssigned: _clearSelection,
      ),
    );
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
      _clearSelection();
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
          // ── Top action bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
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
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear',
                      onTap: _clearLeads,
                      color: AppTheme.errorColor,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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

          // ── Stats strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryBlue.withOpacity(0.05),
            child: Row(
              children: [
                _statPill(
                  'Total',
                  provider.totalLeads.toString(),
                  AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                _statPill(
                  'Assigned',
                  provider.totalAssignedLeads.toString(),
                  AppTheme.successColor,
                ),
                const SizedBox(width: 12),
                _statPill(
                  'Unassigned',
                  provider.totalUnassignedLeads.toString(),
                  AppTheme.warningColor,
                ),
              ],
            ),
          ),

          // ── Selection bar (visible when leads selected) ──
          if (_selectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primaryBlue,
              child: Row(
                children: [
                  Text(
                    '${_selectedLeadIds.length} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearSelection,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final sel = provider.leads
                          .where((l) => _selectedLeadIds.contains(l.id))
                          .toList();
                      _showAssignDialog(sel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text(
                      'Assign',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

          // ── Tabs ──
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Unassigned (${unassignedLeads.length})'),
                Tab(text: 'Assigned (${assignedLeads.length})'),
              ],
            ),
          ),

          // ── Assigned tab tip ──
          if (!_selectionMode &&
              _tabCtrl.index == 0 &&
              unassignedLeads.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF8E1),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: Color(0xFF856404),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Long press or tap checkbox to select leads, then tap Assign',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF856404),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // UNASSIGNED — selectable
                _buildLeadsList(
                  leads: unassignedLeads,
                  showUser: false,
                  selectable: true,
                  provider: provider,
                ),
                // ASSIGNED — with reassign/unassign option
                _buildLeadsList(
                  leads: assignedLeads,
                  showUser: true,
                  selectable: false,
                  provider: provider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsList({
    required List<LeadModel> leads,
    required bool showUser,
    required bool selectable,
    required AppProvider provider,
  }) {
    if (leads.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.contacts_outlined,
        title: showUser ? 'No assigned leads' : 'No unassigned leads',
        subtitle: showUser
            ? 'All leads are unassigned. Select from Unassigned tab.'
            : 'Import CSV or all leads are already assigned.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: leads.length,
      itemBuilder: (_, i) {
        final lead = leads[i];
        final isSelected = _selectedLeadIds.contains(lead.id);
        final assignedUser = lead.assignedUserId != null
            ? provider.getUserById(lead.assignedUserId!)
            : null;

        return GestureDetector(
          onLongPress: selectable ? () => _toggleSelect(lead.id) : null,
          onTap: selectable && _selectionMode
              ? () => _toggleSelect(lead.id)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.07)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (selectable && _selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
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
                      const SizedBox(height: 2),
                      Text(
                        lead.phoneNumber,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (showUser && assignedUser != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 12,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                assignedUser.name,
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(status: lead.status),
                    if (showUser)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _reassignLead(context, lead),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Reassign',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _unassignLead(context, lead),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Unassign',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reassignLead(BuildContext context, LeadModel lead) async {
    final provider = context.read<AppProvider>();
    final activeUsers = provider.regularUsers.where((u) => u.isActive).toList();
    if (activeUsers.isEmpty) {
      AppSnackbar.error(context, 'No active users available.');
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AssignBottomSheet(
        selectedLeads: [lead],
        activeUsers: activeUsers,
        onAssigned: () {},
      ),
    );
  }

  Future<void> _unassignLead(BuildContext context, LeadModel lead) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Unassign Lead',
      content:
          'Remove this lead assignment from "${lead.customerName.isNotEmpty ? lead.customerName : lead.phoneNumber}"?',
      confirmText: 'Unassign',
    );
    if (confirmed && mounted) {
      await context.read<AppProvider>().unassignLead(lead);
      AppSnackbar.success(context, 'Lead unassigned.');
    }
  }

  Widget _statPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Action button widget ──────────────────────────────────────────────────────
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Assign bottom sheet ───────────────────────────────────────────────────────
class _AssignBottomSheet extends StatefulWidget {
  final List<LeadModel> selectedLeads;
  final List<UserModel> activeUsers;
  final VoidCallback onAssigned;

  const _AssignBottomSheet({
    required this.selectedLeads,
    required this.activeUsers,
    required this.onAssigned,
  });

  @override
  State<_AssignBottomSheet> createState() => _AssignBottomSheetState();
}

class _AssignBottomSheetState extends State<_AssignBottomSheet> {
  String? _selectedUserId;
  bool _isAssigning = false;

  Future<void> _assign() async {
    if (_selectedUserId == null) {
      AppSnackbar.error(context, 'Please select a user to assign leads to.');
      return;
    }
    setState(() => _isAssigning = true);
    await context.read<AppProvider>().assignLeadsToUser(
      widget.selectedLeads,
      _selectedUserId!,
    );
    if (!mounted) return;
    setState(() => _isAssigning = false);
    widget.onAssigned();
    Navigator.pop(context);
    AppSnackbar.success(
      context,
      '${widget.selectedLeads.length} lead(s) assigned successfully!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Leads',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.selectedLeads.length} lead(s) selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Select User',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // User list (scrollable if many)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.activeUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final user = widget.activeUsers[i];
                  final isSelected = _selectedUserId == user.id;
                  final provider = context.read<AppProvider>();
                  final currentLeadCount = provider
                      .getLeadsForUser(user.id)
                      .length;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedUserId = user.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlue.withOpacity(0.07)
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.primaryBlue.withOpacity(0.12),
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$currentLeadCount leads currently assigned',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryBlue,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAssigning ? null : _assign,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isAssigning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Assign ${widget.selectedLeads.length} Lead(s)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
