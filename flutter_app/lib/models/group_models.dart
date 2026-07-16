import 'farm_models.dart';

/// A cattle group (Account → Cattle Groups). Mirrors the `GROUPS` array in
/// prototype.html. Members reference a cow by its farm id + cow number.
class GroupMember {
  final String farmId;
  final int no;
  const GroupMember(this.farmId, this.no);
}

class CattleGroup {
  final String id;
  String name;
  List<GroupMember> members;
  CattleGroup({required this.id, required this.name, List<GroupMember>? members}) : members = members ?? [];

  bool has(String farmId, int no) => members.any((m) => m.farmId == farmId && m.no == no);
  void toggle(String farmId, int no, bool on) {
    final present = has(farmId, no);
    if (on && !present) members.add(GroupMember(farmId, no));
    if (!on && present) members.removeWhere((m) => m.farmId == farmId && m.no == no);
  }
}

/// Shared in-memory groups (seed matches prototype.html).
final List<CattleGroup> kGroups = [
  CattleGroup(id: 'g1', name: 'Desi'),
  CattleGroup(id: 'g2', name: 'Jersey', members: [const GroupMember('sunrise', 1), const GroupMember('greenvilla', 1)]),
  CattleGroup(id: 'g3', name: 'Holstein Friesian', members: [const GroupMember('sunrise', 2)]),
  CattleGroup(id: 'g4', name: 'Sahiwal', members: [const GroupMember('sunrise', 4), const GroupMember('stones', 2)]),
];

/// Every cow across all farms, paired with its farm (for the picker sheets).
class FlatCow {
  final FarmModel farm;
  final CowModel cow;
  const FlatCow(this.farm, this.cow);
}

List<FlatCow> allCowsFlat() {
  final out = <FlatCow>[];
  for (final f in kFarms) {
    for (final c in f.cows) {
      out.add(FlatCow(f, c));
    }
  }
  return out;
}
