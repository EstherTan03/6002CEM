import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// schedule_page
Widget buildUserVoteList(Map<String, List<String>> userYesVotes) {
  if (userYesVotes.isEmpty || userYesVotes['voted_yes']!.isEmpty) {
    return Center(child: Text("No votes recorded."));
  }

  return ListView.builder(
    itemCount: userYesVotes['voted_yes']!.length,
    itemBuilder: (context, index) {
      final eventId = userYesVotes['voted_yes']![index];
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('event')
            .doc(eventId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox.shrink();
          if (!snapshot.data!.exists) return SizedBox.shrink();

          final eventData = snapshot.data!.data() as Map<String, dynamic>;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              title: Text(eventData['name'] ?? 'Unknown Event',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    eventData['date'] != null
                        ? "Date: ${eventData['date']}"
                        : "Date: ${eventData['date_range']}",
                  ),
                  Text("Time: ${eventData['time'] ?? '-'}"),
                  Text("Venue: ${eventData['venue'] ?? '-'}"),
                ],
              ),
              leading: Icon(Icons.event_available, color: Colors.green),
            ),
          );
        },
      );
    },
  );
}

Widget buildAdminEventVoteList(Map<String, Map<String, dynamic>> eventVotes) {
  if (eventVotes.isEmpty) {
    return Center(child: CircularProgressIndicator());
  }

  return ListView(
    children: eventVotes.entries.map((entry) {
      final eventId = entry.key;
      final eventData = entry.value;

      final eventName = eventData['name'] ?? eventId;
      final eventDate = eventData['date'] ?? eventData['date_range'] ?? 'Unknown Date';
      final eventTime = eventData['time'] ?? 'Unknown Time';
      final eventVenue = eventData['venue'] ?? 'Unknown Venue';

      final voteData = eventData['vote'] as Map<String, dynamic>? ?? {};
      final yesMap = voteData['yes'] as Map<String, dynamic>? ?? {};
      final noMap = voteData['no'] as Map<String, dynamic>? ?? {};

      final yesVoters = yesMap.keys.toList();
      final noVoters = noMap.keys.toList();

      return Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: ExpansionTile(
          title: Text(
            eventName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Date : $eventDate \nTime : $eventTime\nVenue: $eventVenue',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          children: [
            Divider(),
            ListTile(
              title: Text('Yes Votes (${yesVoters.length}):'),
              subtitle: Text(
                  yesVoters.isNotEmpty ? yesVoters.join(', ') : 'No votes'),
            ),
            ListTile(
              title: Text('No Votes (${noVoters.length}):'),
              subtitle: Text(
                  noVoters.isNotEmpty ? noVoters.join(', ') : 'No votes'),
            ),
            ListTile(
              title: Text('Total Votes: ${yesVoters.length + noVoters.length}'),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

