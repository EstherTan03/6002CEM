import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_navigation.dart';
import 'shared.dart';

import 'schedule_card.dart';


class SchedulePage extends StatefulWidget{
  final User user;

  const SchedulePage({Key? key, required this.user}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Map<String, List<String>> userYesVotes = {};
  Map<String, Map<String, dynamic>> eventVotes = {};

  @override
  void initState() {
    super.initState();
    if (widget.user.role == 'user') {
      fetchVotesFromFirestore(widget.user.username);
    }
    else {
      fetchAllEventVotes();
    }
  }

  // for user
  Future<void> fetchVotesFromFirestore(String username) async {
    final docRef = FirebaseFirestore.instance
        .collection('username')
        .doc(username)
        .collection('votes');

    final snapshot = await docRef.get();

    List<String> yesEventIds = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['vote'] == 'yes') {
        yesEventIds.add(doc.id);
      }
    }

    setState(() {
      userYesVotes = {'voted_yes': yesEventIds}; // Just using one key for now
    });
  }

  Future<void> fetchAllEventVotes() async {
    final snapshot = await FirebaseFirestore.instance.collection('event').get();

    final Map<String, Map<String, dynamic>> allVotes = {};
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Support both 'date' and 'end_date'
      final rawDate = data['date'] ?? data['end_date'];
      if (rawDate == null || rawDate.toString().isEmpty) continue;

      try {
        final parsedDate = dateFormat.parse(rawDate);
        // Skip past events
        if (parsedDate.isBefore(DateTime(today.year, today.month, today.day))) {
          continue;
        }

        allVotes[doc.id] = data;
      } catch (e) {
        // Skip if date parsing fails
        continue;
      }
    }

    setState(() {
      eventVotes = allVotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule'),
        leading: Builder(
          builder: (context) =>
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        backgroundColor: Color(0xFFF7CFD8),
      ),
      drawer: AppDrawer(
        user: widget.user,
      ),
      body: widget.user.role == 'user'
          ? buildUserVoteList(userYesVotes)
          : buildAdminEventVoteList(eventVotes),
    );
  }
}

