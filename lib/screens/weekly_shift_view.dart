import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyShiftView extends StatefulWidget {
  const WeeklyShiftView({super.key});

  @override
  _WeeklyShiftViewState createState() => _WeeklyShiftViewState();
}

class _WeeklyShiftViewState extends State<WeeklyShiftView> {
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Shift View'),
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () => setState(() {
              _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
              _selectedDay = DateTime.now();
            }),
          )
        ],
      ),
      body: Column(
        children: [
          _buildWeekNavigation(),
          _buildDayTabs(),
          Expanded(child: _buildShiftList()),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    String weekRange = "${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd').format(_currentWeekStart.add(Duration(days: 6)))}";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () => setState(() {
            _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
          }),
        ),
        Text(
          weekRange,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: () => setState(() {
            _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
          }),
        ),
      ],
    );
  }

  Widget _buildDayTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        DateTime day = _currentWeekStart.add(Duration(days: index));
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(day),
                style: TextStyle(
                  fontWeight: _selectedDay == day ? FontWeight.bold : FontWeight.normal,
                  color: _selectedDay == day ? Colors.blue : Colors.black,
                ),
              ),
              Text(DateFormat('dd').format(day)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShiftList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shifts')
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var shifts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: shifts.length,
          itemBuilder: (context, index) {
            var shift = shifts[index].data() as Map<String, dynamic>;
            bool isFull = (shift['assignedWorkers'] as List).length >= shift['maxWorkers'];
            bool isAssigned = (shift['assignedWorkers'] as List).contains(FirebaseAuth.instance.currentUser?.uid);

            return Card(
              color: isAssigned
                  ? Colors.green.shade50
                  : isFull
                      ? Colors.red.shade50
                      : Colors.white,
              child: ListTile(
                title: Text("${shift['department']} (${shift['startTime']} - ${shift['endTime']})"),
                subtitle: Text("${shift['assignedWorkers'].length}/${shift['maxWorkers']} workers assigned"),
                trailing: isAssigned
                    ? _buildStatusLabel("במשמרת", Colors.green, Icons.check_circle)
                    : isFull
                        ? _buildStatusLabel("מלא", Colors.red, Icons.block)
                        : ElevatedButton(
                            onPressed: () => _joinShift(shift['id']),
                            child: Text("הצטרף"),
                          ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusLabel(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _joinShift(String shiftId) async {
    await FirebaseFirestore.instance.collection('shifts').doc(shiftId).update({
      'requestedWorkers': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid])
    });
  }
}
