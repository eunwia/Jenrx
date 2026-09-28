import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../utils/album_colors.dart';
import 'album_detail_screen.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});
  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  List<Map<String, dynamic>> _albums = [];
  Map<int, Map<String, dynamic>> _summaries = {};

  static const _shape = BorderRadius.only(
    topLeft: Radius.circular(22),
    topRight: Radius.circular(22),
    bottomLeft: Radius.circular(40),
    bottomRight: Radius.circular(40),
  );

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final albums = await db.getAlbums();
    final summaries = await db.getAlbumSummaries();
    if (!mounted) return;
    setState(() { _albums = albums; _summaries = summaries; });
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

  Widget _backCard(Color c, double angle) => Transform.rotate(
        angle: angle,
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.9,
          child: Container(decoration: BoxDecoration(color: c, borderRadius: _shape)),
        ),
      );

  Widget _tile(Map<String, dynamic> album) {
    final color = colorFromHex(album['color'] ?? '1565F5');
    final summary = _summaries[album['id'] as int];
    final count = (summary?['count'] as int?) ?? 0;
    final cover = summary?['cover'] as String?;
    final desc = album['description'] as String?;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    const folderIcon = Center(child: Icon(Icons.folder, color: Colors.white, size: 44));

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)));
        _load();
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                _backCard(color.withOpacity(0.35), -0.14),
                _backCard(color.withOpacity(0.6), 0.12),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  heightFactor: 0.9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: _shape,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: _shape,
                      child: cover != null
                          ? Image.file(File(cover),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              cacheWidth: 300,
                              errorBuilder: (_, __, ___) => folderIcon)
                          : folderIcon,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _editAlbum(album),
                      child: const SizedBox(
                        width: 44, height: 44,
                        child: Icon(Icons.edit, size: 20, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(album['title'],
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 2),
          Text(count == 0 ? 'Empty' : '$count ${count == 1 ? 'photo' : 'photos'}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          if (desc != null && desc.isNotEmpty)
            Text(desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? null : const Color(0xFFF3F0EA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Prescriptions & Lab Results'),
        backgroundColor: bg,
        scrolledUnderElevation: 0,
      ),
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
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.68,
              ),
              itemCount: _albums.length,
              itemBuilder: (context, i) => _tile(_albums[i]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? const Color(0xFF1565F5) : const Color(0xFF2B1210),
        shape: const CircleBorder(),
        onPressed: _createAlbum,
        child: const Icon(Icons.create_new_folder, color: Colors.white),
      ),
    );
  }
}