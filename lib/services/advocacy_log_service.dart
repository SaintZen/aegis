import 'package:anxiety_anchor/models/advocacy_log_entry.dart';

class AdvocacyLogService {
  static List<AdvocacyLogEntry> getTemplates() {
    return [
      AdvocacyLogEntry(
        title: 'Request for Internal Appeal',
        purpose: 'Claim Denials',
        summary:
            'A structured appeal request that demands technical criteria and '
            'a peer-to-peer review pathway.',
      ),
      AdvocacyLogEntry(
        title: 'Peer-to-Peer Script',
        purpose: 'Peer-to-Peer',
        summary:
            'A concise script for clinicians to use when speaking directly '
            'with the insurance medical director.',
      ),
      AdvocacyLogEntry(
        title: 'State Commissioner Grievance',
        purpose: 'Grievance Filing',
        summary:
            'An escalation template for the State Insurance Commissioner '
            'to preserve statutory rights.',
      ),
    ];
  }
}
