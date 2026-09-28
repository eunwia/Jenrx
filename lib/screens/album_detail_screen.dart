import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';
import '../utils/med_icons.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Map<String, dynamic> album;
  const AlbumDetailScreen({super.key, required this.album});
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getAlbumItems(widget.album['id'] as int);
    setState(() => _items = items);
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'rx_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(picked.path).copy('${dir.path}/$fileName');

    final db = DatabaseHelper.instance;
    await db.insertAlbumItem(widget.album['id'] as int, savedImage.path, db.formatDate(DateTime.now()));
    _load();
  }

  void _viewFull(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: InteractiveViewer(child: Image.file(File(item['image_path']))),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Added ${formatDateReadable(item['date_added'])}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async {
                          await DatabaseHelper.instance.deleteAlbumItem(item['id'] as int);
                          if (mounted) Navigator.pop(context);
                          _load();
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete Photo', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.album['title'])),
      body: _items.isEmpty
          ? const Center(child: Text('No photos yet.', style: TextStyle(fontSize: 18)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                return GestureDetector(
                  onTap: () => _viewFull(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(item['image_path']), fit: BoxFit.cover),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565F5),
        onPressed: _addPhoto,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}