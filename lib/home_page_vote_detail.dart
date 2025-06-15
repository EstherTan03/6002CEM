// home_page_card
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Get user's vote for event
Future<String?> getUserVote(String eventDoc, String userName) async {
  final userVoteRef = _firestore
      .collection('username')
      .doc(userName)
      .collection('votes')
      .doc(eventDoc);

  final snapshot = await userVoteRef.get();
  if (!snapshot.exists) return null;
  return snapshot.data()?['vote'] as String?;
}

Future<void> submitVote(String eventId, String userName, bool vote) async {
  final eventRef = FirebaseFirestore.instance.collection('event').doc(eventId);
  final userVoteRef = FirebaseFirestore.instance
      .collection('username')
      .doc(userName)
      .collection('votes')
      .doc(eventId);

  final votePath = vote ? 'vote.yes.$userName' : 'vote.no.$userName';
  final oppositeVotePath = vote ? 'vote.no.$userName' : 'vote.yes.$userName';

  final batch = FirebaseFirestore.instance.batch();

  // Set current vote in event document nested map
  batch.update(eventRef, {votePath: true});

  // Remove opposite vote if exists
  batch.update(eventRef, {oppositeVotePath: FieldValue.delete()});

  // Set current vote in user's votes collection
  batch.set(userVoteRef, {'vote': vote ? 'yes' : 'no'});

  await batch.commit();
}

Future<void> cancelVote(String eventId, String userName) async {
  final eventRef = FirebaseFirestore.instance.collection('event').doc(eventId);
  final userVoteRef = FirebaseFirestore.instance
      .collection('username')
      .doc(userName)
      .collection('votes')
      .doc(eventId);

  final batch = FirebaseFirestore.instance.batch();

  // Delete user's vote from both yes and no maps in event doc
  batch.update(eventRef, {
    'vote.yes.$userName': FieldValue.delete(),
    'vote.no.$userName': FieldValue.delete(),
  });

  // Delete user's vote document from their votes collection
  batch.delete(userVoteRef);

  await batch.commit();
}
