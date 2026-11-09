import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/family_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyVM = Provider.of<FamilyViewModel>(context);
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);
    final family = familyVM.myFamily;

    return Scaffold(
      backgroundColor: const Color(0xFF141221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Family / Club System', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: family == null
          ? _buildNoFamilyView(context, familyVM)
          : _buildFamilyDetailsView(context, family, familyVM, homeVM),
    );
  }

  Widget _buildNoFamilyView(BuildContext context, FamilyViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_outlined, size: 64, color: Colors.tealAccent),
          const SizedBox(height: 16),
          const Text('You are not in a Family yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Join an active club to unlock family gifts, rankings, and events!', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => _showCreateFamilyDialog(context, vm),
            child: const Text('Create a Family'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyDetailsView(BuildContext context, FamilyModel family, FamilyViewModel vm, HomeViewModel homeVM) {
    final myRole = family.getUserRole(vm.currentUserId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(family.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.tealAccent, borderRadius: BorderRadius.circular(8)),
                    child: Text('Lv.${family.level}', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(family.uniqueTag, style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(family.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(family.announcement, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Family XP: ${family.xp}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.monetization_on, size: 16),
                    label: const Text('Donate 100 Coins', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (homeVM.coinBalance >= 100) {
                        vm.contributeCoins(100, (coins) => homeVM.deductCoins(coins));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donated 100 coins to Family XP!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insufficient Coins!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Members List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Members (${family.members.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (myRole == FamilyRole.owner || myRole == FamilyRole.leader)
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 14, color: Colors.tealAccent),
                label: const Text('Edit Notice', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                onPressed: () => _showEditAnnouncementDialog(context, vm),
              ),
          ],
        ),
        const SizedBox(height: 12),

        ...family.members.map((member) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Contributed: ${member.contributionCoins} coins', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: member.role == FamilyRole.owner ? Colors.amber : (member.role == FamilyRole.leader ? Colors.cyanAccent : Colors.white24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member.role.name.toUpperCase(),
                    style: TextStyle(
                      color: member.role == FamilyRole.member ? Colors.white : Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if ((myRole == FamilyRole.owner || myRole == FamilyRole.leader) && member.role == FamilyRole.member)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => vm.kickMember(member.id),
                  ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showCreateFamilyDialog(BuildContext context, FamilyViewModel vm) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        title: const Text('Create Family', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Family Name', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                vm.createFamily(nameCtrl.text.trim(), descCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditAnnouncementDialog(BuildContext context, FamilyViewModel vm) {
    final ctrl = TextEditingController(text: vm.myFamily?.announcement ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF221F38),
        title: const Text('Update Family Notice', style: TextStyle(color: Colors.white)),
        content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              vm.updateAnnouncement(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
