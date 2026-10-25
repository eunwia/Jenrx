import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/album_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/empty_state.dart';
import 'album_detail_screen.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  List<Map<String, dynamic>> _albums = [];
  Map<int, Map<String, dynamic>> _summaries = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final albums = await db.getAlbums();
    final summaries = await db.getAlbumSummaries();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _summaries = summaries;
      _loading = false;
    });
  }

  int get _totalPhotos =>
      _summaries.values.fold(0, (sum, s) => sum + (s['count'] as int));

  Widget _colorPicker(
      String selected, void Function(String) onPick, StateSetter setSheetState) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: albumColorHex.map((hex) {
        final isSelected = hex == selected;
        final color = colorFromHex(hex);
        return GestureDetector(
          onTap: () => setSheetState(() => onPick(hex)),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black87, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
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
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (modalContext, setSheetState) => CustomBottomSheet(
          title: 'Create Record Album',
          subtitle: 'Organize prescriptions, lab tests, and medical photos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Album Title *',
                  hintText: "e.g. Doctor Prescriptions, Blood Tests",
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Cardiologist clinic visits 2026',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Album Theme Color',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _colorPicker(selectedColor, (hex) => selectedColor = hex, setSheetState),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final db = DatabaseHelper.instance;
                    await db.insertAlbum(
                      titleCtrl.text.trim(),
                      descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      db.formatDate(DateTime.now()),
                      selectedColor,
                    );
                    if (bottomSheetContext.mounted) {
                      Navigator.pop(bottomSheetContext);
                    }
                    if (mounted) _load();
                  },
                  child: const Text('Create Album', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editAlbum(Map<String, dynamic> album) async {
    final titleCtrl = TextEditingController(text: album['title']);
    final descCtrl = TextEditingController(text: album['description'] ?? '');
    String selectedColor = album['color'] ?? albumColorHex[0];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (modalContext, setSheetState) => CustomBottomSheet(
          title: 'Edit Album',
          subtitle: 'Update album details or delete',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Album Title *',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Album Theme Color',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _colorPicker(selectedColor, (hex) => selectedColor = hex, setSheetState),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await DatabaseHelper.instance.updateAlbum(
                      album['id'] as int,
                      titleCtrl.text.trim(),
                      descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      selectedColor,
                    );
                    if (bottomSheetContext.mounted) {
                      Navigator.pop(bottomSheetContext);
                    }
                    if (mounted) _load();
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.2),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: bottomSheetContext,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Delete Album?'),
                        content: const Text('This will remove the album and all stored photos inside it.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await DatabaseHelper.instance.deleteAlbum(album['id'] as int);
                      if (bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                      }
                      if (mounted) _load();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Delete Album'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, bool isDark) {
    final color = colorFromHex(album['color'] ?? '1565F5');
    final summary = _summaries[album['id'] as int];
    final count = (summary?['count'] as int?) ?? 0;
    final cover = summary?['cover'] as String?;
    final desc = album['description'] as String?;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)),
        );
        _load();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Album Cover / Folder Thumbnail
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null && File(cover).existsSync())
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.file(
                      File(cover),
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      errorBuilder: (_, _, _) => _buildFolderPlaceholder(color, isDark),
                    ),
                  )
                else
                  _buildFolderPlaceholder(color, isDark),

                // Top Accent Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Edit Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _editAlbum(album),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Album Details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc != null && desc.isNotEmpty
                      ? desc
                      : (count == 0 ? 'Empty album' : '$count photos'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderPlaceholder(Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Center(
        child: Icon(
          Icons.folder_rounded,
          size: 54,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          // Header Card
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescriptions & Lab Records',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_albums.length} album${_albums.length == 1 ? '' : 's'} • $_totalPhotos photo${_totalPhotos == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_albums.isEmpty) ...[
            EmptyStateView(
              icon: Icons.photo_library_outlined,
              title: 'No Medical Albums Yet',
              description: 'Save photos of your doctor prescriptions, laboratory results, and medical notes here.',
              actionLabel: 'Create New Album',
              onAction: _createAlbum,
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: _albums.length,
              itemBuilder: (context, i) => _buildAlbumCard(_albums[i], isDark),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _createAlbum,
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
        label: const Text('New Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
