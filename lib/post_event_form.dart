// post_event
import 'package:flutter/material.dart';

Widget buildFairForm({
  required BuildContext context,
  required String? selectedEventType,
  required String description,
  required DateTime? selectedDateStart,
  required DateTime? selectedDateEnd,
  required Function(DateTime) onStartDatePicked,
  required Function(DateTime) onEndDatePicked,
  required VoidCallback onSubmit,  // <-- Add this
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Fair Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
      const SizedBox(height: 5),
      Text(selectedEventType ?? '', style: TextStyle(fontSize: 20)),
      const SizedBox(height: 15),
      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
      const SizedBox(height: 5),
      Text(
        description,
        style: TextStyle(fontSize: 20),
      ),
      const SizedBox(height: 15),
      const Text('Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
      const SizedBox(height: 5),
      const Text('Setia Spice Arena', style: TextStyle(fontSize: 20)),
      const SizedBox(height: 15),
      const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
      const SizedBox(height: 5),
      Text(
        selectedEventType == 'MEF' ? '11am - 6pm' : '11am - 7pm',
        style: const TextStyle(fontSize: 20),
      ),

      const SizedBox(height: 15),
      Row(
        children: [
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDateStart ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (date != null) onStartDatePicked(date);
            },
            child: Text(selectedDateStart == null
                ? 'Pick Start Date'
                : 'Start: ${selectedDateStart.day}/${selectedDateStart.month}/${selectedDateStart.year}'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDateEnd ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (date != null) onEndDatePicked(date);
            },
            child: Text(selectedDateEnd == null
                ? 'Pick End Date'
                : 'End: ${selectedDateEnd.day}/${selectedDateEnd.month}/${selectedDateEnd.year}'),
          ),
        ],
      ),
      Row(
        children: [
          ElevatedButton(
            onPressed: onSubmit,
            child: Text('Submit Event'),
          ),
        ],
      )
    ],
  );
}

Widget buildLeadsForm({
  required BuildContext context,
  required String? selectedEventType,
  required DateTime? selectedDate,
  required TimeOfDay? selectedTime,
  required int maxUsers, // total users from DB
  required int maxParticipants,
  required Function(DateTime) onDatePicked,
  required Function(TimeOfDay) onTimePicked,
  required Function(int) onMaxParticipantsChanged,
  required VoidCallback onSubmit,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 5),
      Text(selectedEventType ?? '', style: TextStyle(fontSize: 20)),
      const SizedBox(height: 10),
      Row(
        children: [
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (date != null) onDatePicked(date);
            },
            child: Text(selectedDate == null
                ? 'Pick Date'
                : 'Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
              );
              if (time != null) onTimePicked(time);
            },
            child: Text(selectedTime == null
                ? 'Pick Time'
                : 'Time : ${selectedTime.format(context)}'
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text('Max Participants:', style: TextStyle(fontSize: 16)),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: maxParticipants > 1
                ? () => onMaxParticipantsChanged(maxParticipants - 1)
                : null, // disable if 1 or less
          ),
          Text(
            '$maxParticipants',
            style: TextStyle(fontSize: 18),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: maxParticipants < maxUsers
                ? () => onMaxParticipantsChanged(maxParticipants + 1)
                : null, // disable if at maxUsers
          ),
        ],
      ),
      Text('Max allowed: $maxUsers'),
      const SizedBox(height: 30),
      Center(
        child: ElevatedButton(
          onPressed: onSubmit,
          child: Text('Submit Event'),
        ),
      ),
    ],
  );
}

Widget buildAGMForm({
  required BuildContext context,
  required String? selectedEventType,
  required DateTime? selectedDate,
  required TimeOfDay? selectedStartTime,
  required TimeOfDay? selectedEndTime,
  required String? venue,
  required Function(DateTime) onDatePicked,
  required Function(TimeOfDay) onStartTimePicked,
  required Function(TimeOfDay) onEndTimePicked,
  required Function(String) onVenueChanged,
  required VoidCallback onSubmit,
}) {
  final venueController = TextEditingController(text: venue);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 5),
      Text(selectedEventType ?? '', style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 10),

      // Venue Input
      TextField(
        controller: venueController,
        decoration: const InputDecoration(
          labelText: 'Enter Venue',
          border: OutlineInputBorder(),
        ),
        onChanged: onVenueChanged,
      ),
      const SizedBox(height: 15),

      // Date Picker
      Row(
        children: [
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (date != null) onDatePicked(date);
            },
            child: Text(selectedDate == null
                ? 'Pick Date'
                : 'Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
          ),
        ],
      ),
      const SizedBox(height: 15),

      // Time Pickers
      Row(
        children: [
          ElevatedButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedStartTime ?? TimeOfDay.now(),
              );
              if (time != null) onStartTimePicked(time);
            },
            child: Text(selectedStartTime == null
                ? 'Start Time'
                :"Start : ${selectedStartTime.format(context)}"
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedEndTime ?? TimeOfDay.now(),
              );
              if (time != null) onEndTimePicked(time);
            },
            child: Text(selectedEndTime == null
                ? 'End Time'
                : "End : ${selectedEndTime.format(context)}"
            ),
          ),
        ],
      ),

      const SizedBox(height: 30),

      // Submit Button
      Center(
        child: ElevatedButton(
          onPressed: onSubmit,
          child: const Text('Submit Event'),
        ),
      ),
    ],
  );
}

