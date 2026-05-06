import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactSection extends StatefulWidget {
  const EmergencyContactSection({super.key});

  @override
  State<EmergencyContactSection> createState() =>
      _EmergencyContactSectionState();
}

class _EmergencyContactSectionState extends State<EmergencyContactSection> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _savedName;
  String? _savedPhone;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedName = prefs.getString('emergency_name');
      _savedPhone = prefs.getString('emergency_phone');
    });
  }

  Future<void> _saveContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_name', _nameController.text);
    await prefs.setString('emergency_phone', _phoneController.text);
    await _loadContact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact Saved')),
      );
    }
  }

  Future<void> _makeCall() async {
    if (_savedPhone == null) return;
    final Uri url = Uri.parse('tel:$_savedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _editContact() {
    _nameController.text = _savedName ?? '';
    _phoneController.text = _savedPhone ?? '';
    setState(() {
      _savedName = null;
      _savedPhone = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.phone_in_talk, color: Colors.blueGrey),
                SizedBox(width: 10),
                Text(
                  'Emergency Contact',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_savedName == null) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Contact Name'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveContact,
                child: const Text('Save Contact'),
              ),
            ] else ...[
              ListTile(
                title: Text(_savedName!),
                subtitle: Text(_savedPhone!),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editContact,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _makeCall,
                icon: const Icon(Icons.call),
                label: const Text('CALL FOR SUPPORT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
