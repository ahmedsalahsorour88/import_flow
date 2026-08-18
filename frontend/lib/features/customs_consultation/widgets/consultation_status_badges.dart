import 'package:flutter/material.dart';

class ConsultationStatusBadge extends StatelessWidget {
  final String status;

  const ConsultationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey;
    if (status == 'Clearance Ready') bg = Colors.green;
    if (status == 'Blocked') bg = Colors.red;
    if (status == 'Action Required') bg = Colors.orange;
    if (status == 'In Progress') bg = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class ConsultationDocStatusBadge extends StatelessWidget {
  final String status;

  const ConsultationDocStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey;
    if (status == 'Approved') bg = Colors.green;
    if (status == 'Rejected') bg = Colors.red;
    if (status == 'Verified') bg = Colors.blue;
    if (status == 'Received') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
