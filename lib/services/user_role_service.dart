import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRoleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String?> getCurrentRole() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) return 'customer';

    return doc.data()?['role'] ?? 'customer';
  }

  static Future<bool> isCustomer() async {
    final role = await getCurrentRole();
    return role == 'customer';
  }

  static Future<bool> isCaterer() async {
    final role = await getCurrentRole();
    return role == 'caterer';
  }
}
