import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../features/leads/models/lead_model.dart';
import 'lead_detail_screen.dart';

class UserLeadsScreen extends StatefulWidget {
  const UserLeadsScreen({super.key});

  @override
  State<UserLeadsScreen> createState() => _UserLeadsScreenState();
}

class _UserLeadsScreenState extends State<UserLeadsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filterStatus = 'All';

  final List<String> _statuses = ['All', ...AppConstants.leadStatuses];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    var leads = provider.myLeads;

    if (_filterStatus != 'All') {
      leads = leads.where((l) => l.status == _filterStatus).toList();
    }

    if (_query.isNotEmpty) {
      leads = leads
          .where(
            (l) =>
                l.customerName.toLowerCase().contains(_query) ||
                l.phoneNumber.contains(_query),
          )
          .toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
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
          ),

          // Status filter chips
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final selected = s == _filterStatus;
                return FilterChip(
                  label: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _filterStatus = s),
                  backgroundColor: AppTheme.surfaceColor,
                  selectedColor: AppTheme.primaryBlue,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),

          // Count bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.primaryBlue.withOpacity(0.05),
            child: Row(
              children: [
                Text(
                  '${leads.length} leads',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.touch_app_rounded,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Tap to view details & notes',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          Expanded(
            child: leads.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.contacts_outlined,
                    title: 'No leads found',
                    subtitle: _query.isNotEmpty || _filterStatus != 'All'
                        ? 'Try adjusting your filters'
                        : 'No leads have been assigned to you yet',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: leads.length,
                    itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Lead card ─────────────────────────────────────────────────────────────────
class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lead.customerName.isNotEmpty
                            ? lead.customerName[0].toUpperCase()
                            : '#',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lead.phoneNumber,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(status: lead.status),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),

              // Show note preview if exists
              if (lead.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFECB3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: Color(0xFF8B6914),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lead.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
