import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../features/leads/models/lead_model.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.regularUsers;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: RefreshIndicator(
        onRefresh: provider.initialize,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Overall Summary ──
            _OverallSummaryCard(provider: provider),
            const SizedBox(height: 20),

            // ── Status breakdown ──
            _StatusBreakdownCard(leads: provider.leads),
            const SizedBox(height: 20),

            // ── Per user breakdown ──
            const SectionHeader(title: 'Per User Summary'),
            const SizedBox(height: 12),

            if (users.isEmpty)
              const EmptyStateWidget(
                icon: Icons.people_outline_rounded,
                title: 'No users yet',
                subtitle: 'Add users from the Users tab to see reports',
              )
            else
              ...users.map(
                (u) => _UserReportCard(
                  user: u,
                  leads: provider.getLeadsForUser(u.id),
                  totalLeads: provider.totalLeads,
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Overall summary card ──────────────────────────────────────────────────────
class _OverallSummaryCard extends StatelessWidget {
  final AppProvider provider;
  const _OverallSummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final assigned = provider.totalAssignedLeads;
    final total = provider.totalLeads;
    final pct = total == 0 ? 0.0 : assigned / total;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lead Assignment Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _whiteStatItem('Total Leads', total.toString()),
              _whiteDivider(),
              _whiteStatItem('Assigned', assigned.toString()),
              _whiteDivider(),
              _whiteStatItem(
                'Unassigned',
                provider.totalUnassignedLeads.toString(),
              ),
              _whiteDivider(),
              _whiteStatItem('Users', provider.totalUsers.toString()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assignment Progress',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _whiteDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

// ── Status breakdown card ─────────────────────────────────────────────────────
class _StatusBreakdownCard extends StatelessWidget {
  final List<LeadModel> leads;
  const _StatusBreakdownCard({required this.leads});

  @override
  Widget build(BuildContext context) {
    final assigned = leads.where((l) => l.isAssigned).toList();
    final counts = <String, int>{};
    for (final s in AppConstants.leadStatuses) {
      counts[s] = assigned.where((l) => l.status == s).length;
    }
    final total = assigned.isEmpty ? 1 : assigned.length;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lead Status Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${assigned.length} assigned leads',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ...AppConstants.leadStatuses.map((s) {
            final count = counts[s] ?? 0;
            final pct = count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatusRow(status: s, count: count, pct: pct),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final int count;
  final double pct;
  const _StatusRow({
    required this.status,
    required this.count,
    required this.pct,
  });

  Color get _color {
    switch (status) {
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
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Per user report card ──────────────────────────────────────────────────────
class _UserReportCard extends StatelessWidget {
  final UserModel user;
  final List<LeadModel> leads;
  final int totalLeads;

  const _UserReportCard({
    required this.user,
    required this.leads,
    required this.totalLeads,
  });

  @override
  Widget build(BuildContext context) {
    final completed = leads.where((l) => l.status == 'Completed').length;
    final interested = leads.where((l) => l.status == 'Interested').length;
    final pending = leads.where((l) => l.status == 'Pending').length;
    final total = leads.length;
    final pct = totalLeads == 0 ? 0.0 : total / totalLeads;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: user.isActive
                      ? AppTheme.primaryBlue.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: user.isActive
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$total leads',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Share of total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share of total leads',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  '${(pct * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlue,
                ),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Mini status chips
            Row(
              children: [
                _miniStat('Pending', pending, const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _miniStat('Interested', interested, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _miniStat('Completed', completed, const Color(0xFF059669)),
                const Spacer(),
                if (!user.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10.5)),
        ],
      ),
    );
  }
}
