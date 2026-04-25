class StaffMember {
  final String id;
  final String name;
  final String role;
  final String status; // available, busy, dispatched, standby, off-duty
  final String zone;
  final String? currentIncident;
  final String? fcmToken;
  final double? lat;
  final double? lng;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.zone,
    this.currentIncident,
    this.fcmToken,
    this.lat,
    this.lng,
  });

  factory StaffMember.fromRtdb(String key, Map<String, dynamic> data) {
    return StaffMember(
      id:              key,
      name:            data['name'] ?? 'Unknown',
      role:            data['role'] ?? 'Staff',
      status:          data['status'] ?? 'available',
      zone:            data['zone'] ?? 'Lobby',
      currentIncident: data['current_incident'],
      fcmToken:        data['fcm_token'],
      lat:             (data['lat'] as num?)?.toDouble(),
      lng:             (data['lng'] as num?)?.toDouble(),
    );
  }

  bool get isAvailable => status == 'available' || status == 'standby';
  bool get isBusy      => status == 'busy' || status == 'dispatched';

  String get statusEmoji {
    switch (status) {
      case 'available':  return '🟢';
      case 'standby':    return '🟡';
      case 'busy':       return '🔴';
      case 'dispatched': return '🔴';
      case 'off-duty':   return '⚫';
      default:           return '⚪';
    }
  }
}
