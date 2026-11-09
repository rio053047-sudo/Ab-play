import 'package:flutter/material.dart';

enum AdminPermissionLevel {
  superAdmin,
  admin,
  moderator,
}

class AdminActionLog {
  final String id;
  final String adminName;
  final String action;
  final String target;
  final DateTime timestamp;

  AdminActionLog({
    required this.id,
    required this.adminName,
    required this.action,
    required this.target,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  AdminPermissionLevel _currentLevel = AdminPermissionLevel.superAdmin;

  final List<AdminActionLog> _logs = [
    AdminActionLog(id: 'l1', adminName: 'SuperAdmin_Dev', action: 'Configured Jackpot Rate (5%)', target: 'Server Economy'),
    AdminActionLog(id: 'l2', adminName: 'Mod_Alex', action: 'Muted abusive user for 10m', target: 'User #9982'),
    AdminActionLog(id: 'l3', adminName: 'Admin_Sarah', action: 'Approved Club Banner', target: 'Family #PHOENIX'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Admin & Moderation Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          DropdownButton<AdminPermissionLevel>(
            value: _currentLevel,
            dropdownColor: const Color(0xFF221F38),
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: AdminPermissionLevel.superAdmin, child: Text('Super Admin')),
              DropdownMenuItem(value: AdminPermissionLevel.admin, child: Text('Admin')),
              DropdownMenuItem(value: AdminPermissionLevel.moderator, child: Text('Moderator')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _currentLevel = val);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Role Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentLevel == AdminPermissionLevel.superAdmin
                    ? [const Color(0xFFB00020), const Color(0xFFFF5252)]
                    : (_currentLevel == AdminPermissionLevel.admin
                        ? [const Color(0xFF3F51B5), const Color(0xFF2196F3)]
                        : [const Color(0xFF00796B), const Color(0xFF009688)]),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Tier: ${_currentLevel.name.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _getPermissionDescription(),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tools Section
          const Text('Administrative Controls', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Super Admin Controls
          if (_currentLevel == AdminPermissionLevel.superAdmin) ...[
            _buildAdminTile(
              icon: Icons.account_balance_wallet,
              color: Colors.amber,
              title: 'Economy & Jackpot Configuration',
              subtitle: 'Configure reward limits, coin multipliers & gift scale',
              onTap: () => _showDialog('Configured platform gift economics & anti-fraud limits.'),
            ),
            _buildAdminTile(
              icon: Icons.manage_accounts,
              color: Colors.redAccent,
              title: 'Admin Permissions & RBAC',
              subtitle: 'Assign staff permissions and role overrides',
              onTap: () => _showDialog('Updated staff permissions and assigned Moderator roles.'),
            ),
          ],

          // Admin Controls
          if (_currentLevel == AdminPermissionLevel.superAdmin || _currentLevel == AdminPermissionLevel.admin) ...[
            _buildAdminTile(
              icon: Icons.event,
              color: Colors.purpleAccent,
              title: 'Live Event Scheduler',
              subtitle: 'Deploy daily challenges & season competitions',
              onTap: () => _showDialog('Created new 24h Ludo Grand Prix tournament event.'),
            ),
            _buildAdminTile(
              icon: Icons.meeting_room,
              color: Colors.cyanAccent,
              title: 'Voice Room Overrides',
              subtitle: 'Inspect live voice rooms and force close violator rooms',
              onTap: () => _showDialog('Inspected room list and verified room safety policies.'),
            ),
          ],

          // Moderator Controls
          _buildAdminTile(
            icon: Icons.mic_off,
            color: Colors.orangeAccent,
            title: 'Mute / Kick Room Moderation',
            subtitle: 'Apply temporary timeouts or kick toxic participants',
            onTap: () => _showDialog('Actioned user timeout for 15 minutes due to audio noise.'),
          ),
          _buildAdminTile(
            icon: Icons.report,
            color: Colors.greenAccent,
            title: 'Player Reports Queue',
            subtitle: 'Process flagged user reports and safety reviews',
            onTap: () => _showDialog('Reviewed 4 reports. Dismissed false report, warned 1 user.'),
          ),

          const SizedBox(height: 20),
          const Text('Audit Action Logs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ..._logs.map((log) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.white38, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('${log.adminName} • Target: ${log.target}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                Text('${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getPermissionDescription() {
    switch (_currentLevel) {
      case AdminPermissionLevel.superAdmin:
        return 'Full platform control, wallet economy, RBAC, and system settings.';
      case AdminPermissionLevel.admin:
        return 'Events scheduling, user management, and room overrides.';
      case AdminPermissionLevel.moderator:
        return 'Room safety, mute/kick, and community report resolution.';
    }
  }

  Widget _buildAdminTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }

  void _showDialog(String logAction) {
    setState(() {
      _logs.insert(
        0,
        AdminActionLog(
          id: 'l_${DateTime.now().millisecondsSinceEpoch}',
          adminName: _currentLevel == AdminPermissionLevel.superAdmin ? 'SuperAdmin_Dev' : (_currentLevel == AdminPermissionLevel.admin ? 'Admin_Sarah' : 'Mod_Alex'),
          action: logAction,
          target: 'Platform Core',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action executed and logged to audit trail!')),
    );
  }
}
