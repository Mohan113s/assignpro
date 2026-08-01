import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../features/leads/models/lead_model.dart';

class LeadDetailScreen extends StatefulWidget {
  final LeadModel lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late LeadModel _lead;
  final _noteCtrl = TextEditingController();
  bool _editingNote = false;
  bool _isSavingNote = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _noteCtrl.text = _lead.notes;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _isSavingNote = true);
    final updated = _lead.copyWith(notes: _noteCtrl.text.trim());
    await context.read<AppProvider>().updateLead(updated);
    if (!mounted) return;
    setState(() {
      _lead = updated;
      _isSavingNote = false;
      _editingNote = false;
    });
    AppSnackbar.success(context, 'Notes saved!');
  }

  Future<void> _callCustomer() async {
    final phone = _lead.phoneNumber.replaceAll(' ', '');
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppSnackbar.error(context, 'Cannot launch phone dialer.');
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdatingStatus = true);
    final updated = _lead.copyWith(status: status);
    await context.read<AppProvider>().updateLead(updated);
    if (!mounted) return;
    setState(() {
      _lead = updated;
      _isUpdatingStatus = false;
    });
    AppSnackbar.success(context, 'Status updated to "$status"');
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusPickerSheet(
        currentStatus: _lead.status,
        onSelected: (s) {
          Navigator.pop(context);
          _updateStatus(s);
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          _lead.customerName.isNotEmpty ? _lead.customerName : 'Lead Details',
        ),
        actions: [
          // Call customer button in app bar
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: _callCustomer,
            tooltip: 'Call Customer',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Customer info card ──
            _CustomerCard(lead: _lead, onCall: _callCustomer),
            const SizedBox(height: 16),

            // ── Status card ──
            _StatusCard(
              status: _lead.status,
              onUpdate: _showStatusPicker,
              isLoading: _isUpdatingStatus,
            ),
            const SizedBox(height: 16),

            // ── Details card ──
            _DetailsCard(lead: _lead, formatDate: _formatDate),
            const SizedBox(height: 16),

            // ── Notes card ──
            _NotesCard(
              lead: _lead,
              noteCtrl: _noteCtrl,
              isEditing: _editingNote,
              isSaving: _isSavingNote,
              onEdit: () => setState(() => _editingNote = true),
              onCancel: () {
                setState(() {
                  _editingNote = false;
                  _noteCtrl.text = _lead.notes;
                });
              },
              onSave: _saveNote,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // ── Bottom call action ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.dividerColor)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showStatusPicker,
                  icon: const Icon(Icons.update_rounded, size: 18),
                  label: const Text('Update Status'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callCustomer,
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Customer info card ────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onCall;
  const _CustomerCard({required this.lead, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                lead.customerName.isNotEmpty
                    ? lead.customerName[0].toUpperCase()
                    : '#',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.customerName.isNotEmpty
                      ? lead.customerName
                      : 'Unknown Customer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: lead.phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        lead.phoneNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCall,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final String status;
  final VoidCallback onUpdate;
  final bool isLoading;
  const _StatusCard({
    required this.status,
    required this.onUpdate,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.circle_notifications_rounded,
            color: AppTheme.primaryBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Text(
            'Current Status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          StatusChip(status: status),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onUpdate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Change',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details card ──────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final LeadModel lead;
  final String Function(DateTime) formatDate;
  const _DetailsCard({required this.lead, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lead Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _row(
            'Customer Name',
            lead.customerName.isNotEmpty ? lead.customerName : 'Unknown',
          ),
          _row('Phone Number', lead.phoneNumber),
          _row('Status', lead.status),
          _row('Assigned Date', formatDate(lead.createdAt)),
          _row('Last Updated', formatDate(lead.updatedAt)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notes card ────────────────────────────────────────────────────────────────
class _NotesCard extends StatelessWidget {
  final LeadModel lead;
  final TextEditingController noteCtrl;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _NotesCard({
    required this.lead,
    required this.noteCtrl,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing ? AppTheme.primaryBlue : AppTheme.dividerColor,
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Private Notes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isEditing)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (isEditing) ...[
            TextField(
              controller: noteCtrl,
              maxLines: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    'Write your notes here...\n'
                    'e.g. Customer interested in premium plan\n'
                    'Follow up on Monday',
                alignLabelWithHint: true,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    child: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Notes'),
                  ),
                ),
              ],
            ),
          ] else if (lead.notes.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 32,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No notes yet. Tap Edit to add notes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFECB3)),
              ),
              child: Text(
                lead.notes,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D4037),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status picker sheet ───────────────────────────────────────────────────────
class _StatusPickerSheet extends StatelessWidget {
  final String currentStatus;
  final void Function(String) onSelected;

  const _StatusPickerSheet({
    required this.currentStatus,
    required this.onSelected,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Follow Up':
        return const Color(0xFF3B82F6);
      case 'Interested':
        return const Color(0xFF10B981);
      case 'Not Interested':
        return const Color(0xFFEF4444);
      case 'Busy':
        return const Color(0xFF8B5CF6);
      case 'No Response':
        return const Color(0xFF6B7280);
      case 'Wrong Number':
        return const Color(0xFFEC4899);
      case 'Completed':
        return const Color(0xFF059669);
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...AppConstants.leadStatuses.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => onSelected(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: currentStatus == s
                          ? _statusColor(s).withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentStatus == s
                            ? _statusColor(s)
                            : AppTheme.dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _statusColor(s),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(
                              fontWeight: currentStatus == s
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: currentStatus == s
                                  ? _statusColor(s)
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (currentStatus == s)
                          Icon(
                            Icons.check_circle_rounded,
                            color: _statusColor(s),
                            size: 20,
                          ),
                      ],
                    ),
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
