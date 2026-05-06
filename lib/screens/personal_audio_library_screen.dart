import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PersonalAudioLibraryScreen extends StatefulWidget {
  const PersonalAudioLibraryScreen({super.key});

  @override
  State<PersonalAudioLibraryScreen> createState() =>
      _PersonalAudioLibraryScreenState();
}

class _PersonalAudioLibraryScreenState
    extends State<PersonalAudioLibraryScreen> {
  final AudioPlayer _player = AudioPlayer();
  final List<Map<String, String>> _personalTracks = [];
  final Set<String> _activeTracks = {};
  final Map<String, AudioPlayer> _atmospherePlayers = {};

  final List<Map<String, dynamic>> _atmosphereTracks = [
    {'name': 'Wilderness Wind', 'icon': Icons.air, 'file': 'wind.mp3'},
    {
      'name': 'Crackling Campfire',
      'icon': Icons.local_fire_department,
      'file': 'fire.mp3',
    },
    {'name': 'Low Rain', 'icon': Icons.umbrella, 'file': 'rain.mp3'},
    {'name': 'Night Forest', 'icon': Icons.nights_stay, 'file': 'crickets.mp3'},
  ];

  @override
  void dispose() {
    for (final player in _atmospherePlayers.values) {
      player.dispose();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickPersonalAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path == null) return;
      setState(() {
        _personalTracks.add({
          'name': file.name,
          'path': file.path!,
        });
      });
    }
  }

  Future<void> _playLocalFile(String? path) async {
    if (path == null || path.isEmpty) return;
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> _exportToPsychologist(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final confirm = await _showPermissionDialog();
    if (!confirm) return;
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'My Verbal Diary for our next session.',
    );
  }

  Future<bool> _showPermissionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Export'),
        content: const Text(
          'No data is shared automatically. By clicking "Share", you are choosing to send this file to your provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  Future<void> _toggleAtmosphere(Map<String, dynamic> track) async {
    final name = track['name'] as String;
    final file = track['file'] as String;
    if (_activeTracks.contains(name)) {
      _activeTracks.remove(name);
      final existing = _atmospherePlayers.remove(name);
      await existing?.stop();
      await existing?.dispose();
      setState(() {});
      return;
    }

    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/$file'));
    _atmospherePlayers[name] = player;
    _activeTracks.add(name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Audio Library')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.blue, size: 40),
            title: const Text(
              'Upload Your Own Audio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Add music or spoken word that helps you.'),
            onTap: _pickPersonalAudio,
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Atmosphere Mixer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAtmosphereGrid(),
          const SizedBox(height: 20),
          const Text(
            'Your Library',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            itemCount: _personalTracks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final track = _personalTracks[index];
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(track['name'] ?? 'Untitled'),
                trailing: IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => _exportToPsychologist(track['path']),
                ),
                onTap: () => _playLocalFile(track['path']),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphereGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: _atmosphereTracks.length,
      itemBuilder: (context, index) {
        final track = _atmosphereTracks[index];
        final name = track['name'] as String;
        final icon = track['icon'] as IconData;
        final isActive = _activeTracks.contains(name);
        return GestureDetector(
          onTap: () => _toggleAtmosphere(track),
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1565C0)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isActive ? Colors.white : Colors.white24,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
