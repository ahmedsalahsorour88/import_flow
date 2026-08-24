import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

class ConsultationStatusBadge extends StatelessWidget {
  final String status;

  const ConsultationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Color bg = Colors.grey;
    String displayStatus = status;

    if (status == 'Clearance Ready') {
      bg = Colors.green;
      displayStatus = l.statusClearanceReady;
    } else if (status == 'Blocked') {
      bg = Colors.red;
      displayStatus = l.statusBlocked;
    } else if (status == 'Action Required') {
      bg = Colors.orange;
      displayStatus = l.statusActionRequired;
    } else if (status == 'In Progress') {
      bg = Colors.blue;
      displayStatus = l.statusInProgress;
    } else if (status == 'Pending Review') {
      bg = Colors.amber.shade800;
      displayStatus = l.statusPendingReview;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(displayStatus, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class ConsultationDocStatusBadge extends StatelessWidget {
  final String status;

  const ConsultationDocStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Color bg = Colors.grey;
    String displayStatus = status;

    if (status == 'Approved') {
      bg = Colors.green;
      displayStatus = l.statusApproved;
    } else if (status == 'Rejected') {
      bg = Colors.red;
      displayStatus = l.statusRejected;
    } else if (status == 'Verified') {
      bg = Colors.blue;
      displayStatus = l.statusVerified;
    } else if (status == 'Received') {
      bg = Colors.orange;
      displayStatus = l.statusReceived;
    } else if (status == 'Pending') {
      bg = Colors.grey;
      displayStatus = l.statusPending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(displayStatus, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
