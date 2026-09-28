import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../utils/album_colors.dart';
import '../utils/med_icons.dart';
import 'album_detail_screen.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});
  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  List<Map<String, dynamic>> _albums = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final albums = await DatabaseHelper.instance.getAlbums();
    setState(() => _albums = albums);
  }

  Widget _colorPicker(String selected, void Function(String) onPick, StateSetter setSheetState) {
    return Wrap(
      spacing: 10,
      children: albumColorHex.map((hex) {
        final isSelected = hex == selected;
        return GestureDetector(
          onTap: () => setSheetState(() => onPick(hex)),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: colorFromHex(hex),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.black87, width: 3) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _createAlbum() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedColor = albumColorHex[0];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Album', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(labelText: 'Title', hintText: "e.g. November Reseta's", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Doctor visit, Nov 15', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              const Text('Album Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _colorPicker(selectedColor, (hex) => selectedColor = hex, setSheetState),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565F5), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final db = DatabaseHelper.instance;
                    await db.insertAlbum(titleCtrl.text.trim(),
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        db.formatDate(DateTime.now()), selectedColor);
                    if (mounted) Navigator.pop(context);
                    _load();
                  },
                  child: const Text('Create Album', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editAlbum(Map<String, dynamic> album) async {
    final ctrl = TextEditingController(text: album['title']);
    String selectedColor = album['color'] ?? albumColorHex[0];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Album', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: ctrl, style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              const Text('Album Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _colorPicker(selectedColor, (hex) => selectedColor = hex, setSheetState),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565F5), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    await DatabaseHelper.instance.updateAlbum(album['id'] as int, ctrl.text.trim(), selectedColor);
                    if (mounted) Navigator.pop(context);
                    _load();
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions & Lab Results')),
      body: _albums.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('No albums yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _albums.length,
              itemBuilder: (context, i) {
                final album = _albums[i];
                final color = colorFromHex(album['color'] ?? '1565F5');
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => AlbumDetailScreen(album: album)));
                    _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                          child: Icon(Icons.folder, color: color, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(album['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              if (album['description'] != null)
                                Text(album['description'], style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                              Text(formatDateReadable(album['date_created']),
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black54),
                          onPressed: () => _editAlbum(album),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565F5),
        onPressed: _createAlbum,
        child: const Icon(Icons.create_new_folder, color: Colors.white),
      ),
    );
  }
}