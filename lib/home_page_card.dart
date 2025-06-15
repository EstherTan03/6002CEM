// home_page
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared.dart';
import 'home_page_vote_detail.dart';
import 'home_page_event_list.dart';

class HomePageCard extends StatelessWidget {
  final User currentUser;

  const HomePageCard({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('event').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No events available'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final docId = doc.id;
            final data = doc.data() as Map<String, dynamic>;

            // Merge all unique fields into one list
            final allPossibleFields = {
              ...AGM,
              ...MEF,
              ...Star_Fair,
              ...leads,
            }.toList();

            List<String> fields = allPossibleFields;

            Map<String, String> labels = leadDisplayLabels;

            return buildHomePageCardFromDoc(
              docId,
              fields,
              labels,
              data['name'] ?? 'Event Title',
              currentUser,
            );
          },
        );
      },
    );
  }
}

Widget buildHomePageCardFromDoc(String docName, List<String> fields,
    Map<String, String> fieldLabels, String title, User user,) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('event').doc(docName).get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return SizedBox();
      }

      final data = snapshot.data!.data() as Map<String, dynamic>;

      final rawDate = data['end_date'] ?? data['date'];
      if (rawDate == null) return SizedBox();

      try {
        final parsedDate = DateFormat('dd/MM/yyyy').parse(rawDate);
        if (parsedDate.isBefore(DateTime.now())) {
          return SizedBox();
        }
      } catch (e) {
        return SizedBox();
      }

      // Check if this event is a "leads" event by presence of 'max_participant' field
      final bool isLeadsEvent = data.containsKey('max_participant');

      Future<int> getYesVoteCount() async {
        final doc = await FirebaseFirestore.instance.collection('event').doc('lead').get();
        final yesVotes = doc.data()?['vote']?['yes'] as Map<String, dynamic>?;

        return yesVotes?.length ?? 0;
      }

      if (isLeadsEvent) {
        // For leads, get yes vote count and pass to UI
        return FutureBuilder<int>(
          future: getYesVoteCount(),
          builder: (context, yesCountSnapshot) {
            if (yesCountSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!yesCountSnapshot.hasData) return SizedBox();

            final yesVotes = yesCountSnapshot.data!;
            final maxParticipants = data['max_participant'] ?? 0;

            return _buildVoteSection(
              context,
              docName,
              fields,
              fieldLabels,
              data,
              user,
              yesVotes,
              maxParticipants,
            );
          },
        );
      } else {
        // For other events, just build vote section without counting yes votes
        return _buildVoteSection(
          context,
          docName,
          fields,
          fieldLabels,
          data,
          user,
          null,
          null,
        );
      }
    },
  );
}

Widget _buildVoteSection(BuildContext context, String docName, List<String> fields,
    Map<String, String> fieldLabels, Map<String, dynamic> data, User user,
    int? yesVotes, int? maxParticipants,)
{
  return FutureBuilder<String?>(
    future: getUserVote(docName, user.username),
    builder: (context, voteSnapshot) {
      if (voteSnapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      String? userVote = voteSnapshot.data; // 'yes', 'no', or null

      final bool votingClosed = (yesVotes != null && maxParticipants != null && yesVotes >= maxParticipants);

      return StatefulBuilder(builder: (context, setState) {
        Future<void> onVote(bool vote) async {
          await submitVote(docName, user.username, vote);

          setState(() {
            userVote = vote ? 'yes' : 'no';
          });
        }

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...fields.map((field) {
                  final value = data[field];
                  final label = fieldLabels[field] ?? field;

                  return value != null
                      ? Text('$label: $value', style: TextStyle(fontSize: 16))
                      : SizedBox();
                }).toList(),

                SizedBox(height: 10),

                if (votingClosed)
                  Text('Voting is closed: maximum participants reached', style: TextStyle(color: Colors.red))
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: (userVote == 'yes' || votingClosed) ? null : () => onVote(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (userVote == 'yes') ? Colors.grey : Colors.green,
                        ),
                        child: Text('Yes'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: (userVote == 'no' || votingClosed) ? null : () => onVote(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (userVote == 'no') ? Colors.grey : Colors.red,
                        ),
                        child: Text('No'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      });
    },
  );
}