import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_navigation.dart';
import 'shared.dart';
import 'post_event_form.dart';
import 'services/audit_logger.dart'; // 👈 add this

class PostEvent extends StatefulWidget {
  final User user;

  const PostEvent({Key? key, required this.user}) : super(key: key);

  @override
  State<PostEvent> createState() => _PostEventState();
}

class _PostEventState extends State<PostEvent> {
  CollectionReference event = FirebaseFirestore.instance.collection('event');
  String? _selectedEventType;

  String get description {
    if (_selectedEventType == null) return '';
    return 'For those who are supporting $_selectedEventType, please reach IICP and gather at level 2 lobby latest by 10am. '
        'Transportation will be provided to-and-fro between IICP and the event venue.';
  }

  DateTime? selectedDate;
  DateTime? selectedDateStart;
  DateTime? selectedDateEnd;

  TimeOfDay? selectedTime;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  int maxUsers = 0;
  int? maxParticipants;
  String? venue;

  Future<void> clearVotesFromAllUsers(String eventKey) async {
    final usersCollection = FirebaseFirestore.instance.collection('username');
    final usersSnapshot = await usersCollection.get();

    for (final userDoc in usersSnapshot.docs) {
      final voteDocRef = usersCollection.doc(userDoc.id).collection('votes').doc(eventKey);

      final voteDoc = await voteDocRef.get();
      if (voteDoc.exists) {
        await voteDocRef.delete();
      }
    }
  }

  Future<int> fetchTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('username').get();
    return snapshot.docs.length;
  }

  void submitFairEvent() async {
    if (selectedDateStart == null || selectedDateEnd == null || _selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      // 🔎 log validation fail
      await AuditLogger.logPerDay(
        action: 'EVENT_SUBMIT_INVALID',
        meta: {
          'eventType': 'FAIR',
          'eventName': _selectedEventType,
          'reason': 'missing date(s) or event type',
        },
        uid: widget.user.username,
        email: widget.user.email,
      );
      return;
    }

    String dateRange =
        '${selectedDateStart!.day.toString().padLeft(2, '0')}/${selectedDateStart!.month.toString().padLeft(2, '0')}/${selectedDateStart!.year} - '
        '${selectedDateEnd!.day.toString().padLeft(2, '0')}/${selectedDateEnd!.month.toString().padLeft(2, '0')}/${selectedDateEnd!.year}';

    String venue = 'Setia Spice Arena';
    String description = this.description;

    String time;
    if (_selectedEventType == 'Star Fair') {
      time = '11:00 - 19:00';
    } else if (_selectedEventType == 'MEF') {
      time = '11:00 - 18:00';
    } else {
      time = 'To be decided';
    }

    String eventKey = _selectedEventType!.replaceAll(' ', '_');

    Map<String, dynamic> eventData = {
      'name': _selectedEventType,
      'description': description,
      'venue': venue,
      'time': time,
      'start_date':
      '${selectedDateStart!.day.toString().padLeft(2, '0')}/${selectedDateStart!.month.toString().padLeft(2, '0')}/${selectedDateStart!.year}',
      'end_date':
      '${selectedDateEnd!.day.toString().padLeft(2, '0')}/${selectedDateEnd!.month.toString().padLeft(2, '0')}/${selectedDateEnd!.year}',
      'date_range': dateRange,
    };

    try {
      await event.doc(eventKey).set(eventData);

      await clearVotesFromAllUsers(eventKey);

      // 🔎 log success
      await AuditLogger.logPerDay(
        action: 'EVENT_CREATED',
        meta: {
          'eventType': 'FAIR',
          'eventName': _selectedEventType,
          'eventId': eventKey,
        },
        uid: widget.user.username,
        email: widget.user.email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fair event posted successfully!')),
      );

      setState(() {
        selectedDateStart = null;
        selectedDateEnd = null;
      });
    } catch (e) {
      // 🔎 log error
      await AuditLogger.logPerDay(
        action: 'EVENT_CREATE_ERROR',
        meta: {
          'eventType': 'FAIR',
          'eventName': _selectedEventType,
          'error': e.toString(),
        },
        uid: widget.user.username,
        email: widget.user.email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post event: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTotalUsers().then((count) {
      setState(() {
        maxUsers = count;
      });
    });
  }

  void submitLeadsEvent() async {
    if (selectedDate == null || selectedTime == null || _selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      // 🔎 log validation fail
      await AuditLogger.logPerDay(
        action: 'EVENT_SUBMIT_INVALID',
        meta: {
          'eventType': 'LEADS',
          'eventName': _selectedEventType,
          'reason': 'missing date or time or event type',
        },
        uid: widget.user.username,
        email: widget.user.email,
      );
      return;
    }

    String date =
        '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}';

    String time =
        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

    String venue = 'ADCO';

    Map<String, dynamic> eventData = {
      'name': _selectedEventType,
      'venue': venue,
      'time': time,
      'date': date,
      'max_participant': maxParticipants ?? 1,
    };

    try {
      await event.doc('lead').set(eventData);
      await clearVotesFromAllUsers('lead');

      // 🔎 log success
      await AuditLogger.logPerDay(
        action: 'EVENT_CREATED',
        meta: {
          'eventType': 'LEADS',
          'eventName': _selectedEventType,
          'eventId': 'lead',
          'max_participant': maxParticipants ?? 1,
        },
        uid: widget.user.username,
        email: widget.user.email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leads event posted successfully!')),
      );

      setState(() {
        selectedDate = null;
        selectedTime = null;
      });
    } catch (e) {
      // 🔎 log error
      await AuditLogger.logPerDay(
        action: 'EVENT_CREATE_ERROR',
        meta: {
          'eventType': 'LEADS',
          'eventName': _selectedEventType,
          'error': e.toString(),
        },
        uid: widget.user.username,
        email: widget.user.email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post event: $e')),
      );
    }
  }

  void submitAGMEvent() async {
    if (selectedDate == null ||
        selectedStartTime == null ||
        selectedEndTime == null ||
        venue == null ||
        venue!.isEmpty ||
        _selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      // 🔎 log validation fail
      await AuditLogger.logPerDay(
        action: 'EVENT_SUBMIT_INVALID',
        meta: {
          'eventType': 'AGM',
          'eventName': _selectedEventType,
          'reason': 'missing date/time/venue or event type',
        },
        uid: widget.user.username,
        email: widget.user.email,
      );
      return;
    }

    String date =
        '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}';
    String timeRange =
        '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')} - '
        '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}';

    Map<String, dynamic> eventData = {
      'name': _selectedEventType,
      'venue': venue,
      'time': timeRange,
      'date': date,
    };

    try {
      await event.doc('agm').set(eventData);
      await clearVotesFromAllUsers('agm');

      // 🔎 log success
      await AuditLogger.logPerDay(
        action: 'EVENT_CREATED',
        meta: {
          'eventType': 'AGM',
          'eventName': _selectedEventType,
          'eventId': 'agm',
          'venue': venue,
        },
        uid: widget.user.username,
        email: widget.user.email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AGM event posted successfully!')),
      );

      setState(() {
        selectedDate = null;
        selectedStartTime = null;
        selectedEndTime = null;
        venue = '';
      });
    } catch (e) {
      // 🔎 log error
      await AuditLogger.logPerDay(
        action: 'EVENT_CREATE_ERROR',
        meta: {
          'eventType': 'AGM',
          'eventName': _selectedEventType,
          'error': e.toString(),
        },
        uid: widget.user.username,
        email: widget.user.email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post AGM: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Event'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xFFFFF1D5),
      ),
      drawer: AppDrawer(user: widget.user),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Event Type',
                border: OutlineInputBorder(),
              ),
              value: _selectedEventType,
              items: ['MEF', 'Star Fair', 'AGM', 'Leads']
                  .map((String event) => DropdownMenuItem<String>(
                value: event,
                child: Text(event),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEventType = value;
                  selectedDate = null;
                  selectedTime = null;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_selectedEventType != null) ...[
              if (_selectedEventType == 'MEF' || _selectedEventType == 'Star Fair')
                buildFairForm(
                  context: context,
                  selectedEventType: _selectedEventType,
                  description: description,
                  selectedDateStart: selectedDateStart,
                  selectedDateEnd: selectedDateEnd,
                  onStartDatePicked: (date) => setState(() => selectedDateStart = date),
                  onEndDatePicked: (date) => setState(() => selectedDateEnd = date),
                  onSubmit: submitFairEvent,
                ),
              if (_selectedEventType == 'AGM')
                buildAGMForm(
                  context: context,
                  selectedEventType: _selectedEventType,
                  selectedDate: selectedDate,
                  selectedStartTime: selectedStartTime,
                  selectedEndTime: selectedEndTime,
                  venue: venue,
                  onDatePicked: (date) => setState(() => selectedDate = date),
                  onStartTimePicked: (time) => setState(() => selectedStartTime = time),
                  onEndTimePicked: (time) => setState(() => selectedEndTime = time),
                  onVenueChanged: (value) => venue = value,
                  onSubmit: submitAGMEvent,
                ),
              if (_selectedEventType == 'Leads')
                buildLeadsForm(
                  context: context,
                  selectedEventType: _selectedEventType,
                  selectedDate: selectedDate,
                  selectedTime: selectedTime,
                  maxUsers: maxUsers,
                  maxParticipants: maxParticipants ?? 1,
                  onDatePicked: (date) => setState(() => selectedDate = date),
                  onTimePicked: (time) => setState(() => selectedTime = time),
                  onMaxParticipantsChanged: (value) => setState(() => maxParticipants = value),
                  onSubmit: submitLeadsEvent,
                ),
            ]
          ],
        ),
      ),
    );
  }
}
