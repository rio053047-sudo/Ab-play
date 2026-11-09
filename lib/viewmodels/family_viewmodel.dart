import 'package:flutter/foundation.dart';

enum FamilyRole {
  owner,
  leader,
  member,
}

class FamilyMember {
  final String id;
  final String name;
  FamilyRole role;
  int contributionCoins;
  DateTime joinedAt;

  FamilyMember({
    required this.id,
    required this.name,
    this.role = FamilyRole.member,
    this.contributionCoins = 0,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();
}

class FamilyModel {
  final String id;
  final String uniqueTag;
  String name;
  String description;
  String announcement;
  int level;
  int xp;
  List<FamilyMember> members;
  List<String> joinRequests;

  FamilyModel({
    required this.id,
    required this.uniqueTag,
    required this.name,
    required this.description,
    this.announcement = 'Welcome to our Family! Stay active and contribute daily.',
    this.level = 1,
    this.xp = 1200,
    List<FamilyMember>? members,
    List<String>? joinRequests,
  })  : members = members ?? [],
        joinRequests = joinRequests ?? [];

  FamilyRole? getUserRole(String userId) {
    final m = members.firstWhere((x) => x.id == userId, orElse: () => FamilyMember(id: '', name: ''));
    if (m.id.isEmpty) return null;
    return m.role;
  }
}

class FamilyViewModel extends ChangeNotifier {
  final String _currentUserId = '8842109';
  final String _currentUserName = 'AbPlay_Gamer';

  FamilyModel? _myFamily;

  final List<FamilyModel> _allFamilies = [
    FamilyModel(
      id: 'fam_1',
      uniqueTag: '#PHOENIX',
      name: 'Ab-Play Phoenix',
      description: 'The premier competitive gaming & party family!',
      level: 4,
      xp: 8500,
      members: [
        FamilyMember(id: '8842109', name: 'AbPlay_Gamer', role: FamilyRole.owner, contributionCoins: 1200),
        FamilyMember(id: 'u_101', name: 'Sophia VIP', role: FamilyRole.leader, contributionCoins: 900),
        FamilyMember(id: 'u_102', name: 'Leo Gamer', role: FamilyRole.member, contributionCoins: 450),
      ],
    ),
    FamilyModel(
      id: 'fam_2',
      uniqueTag: '#ROYAL',
      name: 'Royal Knights Club',
      description: 'Lounge, voice chill, and daily Ludo matches.',
      level: 2,
      xp: 3200,
      members: [
        FamilyMember(id: 'u_999', name: 'KingArthur', role: FamilyRole.owner, contributionCoins: 2000),
      ],
    ),
  ];

  FamilyViewModel() {
    _myFamily = _allFamilies.first;
  }

  FamilyModel? get myFamily => _myFamily;
  List<FamilyModel> get allFamilies => List.unmodifiable(_allFamilies);
  String get currentUserId => _currentUserId;

  void createFamily(String name, String desc) {
    final newFam = FamilyModel(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
      uniqueTag: '#${name.toUpperCase().replaceAll(' ', '')}',
      name: name,
      description: desc,
      members: [
        FamilyMember(id: _currentUserId, name: _currentUserName, role: FamilyRole.owner),
      ],
    );
    _allFamilies.add(newFam);
    _myFamily = newFam;
    notifyListeners();
  }

  bool contributeCoins(int amount, void Function(int) deductUserCoins) {
    if (_myFamily == null) return false;
    deductUserCoins(amount);
    _myFamily!.xp += amount;
    _myFamily!.level = (_myFamily!.xp / 2000).floor() + 1;

    final member = _myFamily!.members.firstWhere((m) => m.id == _currentUserId);
    member.contributionCoins += amount;
    notifyListeners();
    return true;
  }

  void updateAnnouncement(String newAnnouncement) {
    if (_myFamily == null) return;
    final role = _myFamily!.getUserRole(_currentUserId);
    if (role == FamilyRole.owner || role == FamilyRole.leader) {
      _myFamily!.announcement = newAnnouncement;
      notifyListeners();
    }
  }

  void kickMember(String memberId) {
    if (_myFamily == null) return;
    final myRole = _myFamily!.getUserRole(_currentUserId);
    if (myRole == FamilyRole.owner || myRole == FamilyRole.leader) {
      _myFamily!.members.removeWhere((m) => m.id == memberId && m.role == FamilyRole.member);
      notifyListeners();
    }
  }
}
