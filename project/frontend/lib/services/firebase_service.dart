import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../models/staff_member.dart';

final firebaseServiceProvider = Provider((_) => FirebaseService());

class FirebaseService {
  final _rtdb      = FirebaseDatabase.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authState => _auth.authStateChanges();

  // ── Live Incident Stream (RTDB <100ms latency) ─────────────────────────────
  Stream<List<Incident>> incidentStream(String hotelId) {
    return _rtdb
        .ref('hotels/$hotelId/incidents')
        .orderByChild('created_at')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries
          .map((e) => Incident.fromRtdb(e.key.toString(), Map<String, dynamic>.from(e.value)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // ── Staff Stream ───────────────────────────────────────────────────────────
  Stream<List<StaffMember>> staffStream(String hotelId) {
    return _rtdb.ref('hotels/$hotelId/staff').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries
          .map((e) => StaffMember.fromRtdb(e.key.toString(), Map<String, dynamic>.from(e.value)))
          .toList();
    });
  }

  // ── Create Incident ────────────────────────────────────────────────────────
  Future<String> createIncident(String hotelId, Map<String, dynamic> data) async {
    final ref = _rtdb.ref('hotels/$hotelId/incidents').push();
    final incidentId = 'INC-${DateTime.now().millisecondsSinceEpoch}';
    await ref.set({
      ...data,
      'id': incidentId,
      'status': 'active',
      'created_at': ServerValue.timestamp,
    });
    // Mirror to Firestore for analytics
    await _firestore.collection('incidents').doc(incidentId).set({
      ...data,
      'id': incidentId,
      'hotel_id': hotelId,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });
    return incidentId;
  }

  // ── Update Incident ────────────────────────────────────────────────────────
  Future<void> updateIncident(String hotelId, String incidentId, Map<String, dynamic> updates) async {
    await _rtdb.ref('hotels/$hotelId/incidents/$incidentId').update({
      ...updates,
      'updated_at': ServerValue.timestamp,
    });
    await _firestore.collection('incidents').doc(incidentId).update({
      ...updates,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Assign Staff ───────────────────────────────────────────────────────────
  Future<void> assignStaff(String hotelId, String staffId, String incidentId, String zone) async {
    await _rtdb.ref('hotels/$hotelId/staff/$staffId').update({
      'status': 'dispatched',
      'current_incident': incidentId,
      'assigned_zone': zone,
      'dispatched_at': ServerValue.timestamp,
    });
  }

  // ── PA Broadcast log ──────────────────────────────────────────────────────
  Future<void> logPABroadcast(String hotelId, String message, List<String> zones) async {
    await _firestore.collection('pa_broadcasts').add({
      'hotel_id': hotelId,
      'message': message,
      'zones': zones,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ── Zone Status ────────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>> zoneStatusStream(String hotelId) {
    return _rtdb.ref('hotels/$hotelId/zones').onValue.map((event) =>
        Map<String, dynamic>.from(event.snapshot.value as Map? ?? {}));
  }
}
