import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../theme/app_theme.dart';
import '../utils/med_icons.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/interactive_medicine_kit.dart';

class MedicineKitScreen extends StatefulWidget {
  final bool isStandalone;
  const MedicineKitScreen({super.key, this.isStandalone = false});

  @override
  State<MedicineKitScreen> createState() => MedicineKitScreenState();
}

class MedicineKitScreenState extends State<MedicineKitScreen> {
  List<Map<String, dynamic>> _stock = [];
  List<Medication> _meds = [];
  bool _loading = true;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    load();
    // Fallback: ensure inventory cards reveal even if animations are fast or disabled
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && !_revealed) {
        setState(() => _revealed = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations && !_revealed) {
      _revealed = true;
    }
  }

  Future<void> load() async {
    final db = DatabaseHelper.instance;
    final stock = await db.getStock();
    final meds = await db.getActiveMedications();
    if (!mounted) return;
    setState(() {
      _stock = stock;
      _meds = meds;
      _loading = false;
    });
  }

  Medication? _linkedMed(Map<String, dynamic> item) {
    final medId = item['medication_id'];
    if (medId == null) return null;
    for (final m in _meds) {
      if (m.id == medId) return m;
    }
    return null;
  }

  DateTime? _runOutDate(Map<String, dynamic> item) {
    final med = _linkedMed(item);
    if (med == null || med.timeList.isEmpty) return null;
    final bought = DateTime.parse(item['date_bought']);
    final daysLeft = (item['quantity'] as int) / med.timeList.length;
    return bought.add(Duration(days: daysLeft.floor()));
  }

  double? _fractionLeft(Map<String, dynamic> item) {
    final med = _linkedMed(item);
    if (med == null || med.timeList.isEmpty) return null;
    final bought = DateTime.parse(item['date_bought']);
    final totalDays = (item['quantity'] as int) / med.timeList.length;
    final daysPassed = DateTime.now().difference(bought).inDays;
    final fraction = 1 - (daysPassed / totalDays);
    return fraction.clamp(0.0, 1.0);
  }

  Future<void> addStock() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'tablets');
    Medication? linked;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (modalContext, setSheetState) => CustomBottomSheet(
          title: 'Log New Purchase',
          subtitle: 'Add medicines or health supplies to your inventory',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Medication?>(
                isExpanded: true,
                initialValue: linked,
                decoration: const InputDecoration(
                  labelText: 'Link to a Scheduled Medication',
                  hintText: 'Select medication to track run-out dates',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None / General item', overflow: TextOverflow.ellipsis),
                  ),
                  ..._meds.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setSheetState(() {
                  linked = v;
                  if (v != null) nameCtrl.text = v.name;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Medicine Name *',
                  hintText: 'e.g. Paracetamol, Metformin',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        hintText: '30',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'tablets, ml, caps',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final qty = int.tryParse(qtyCtrl.text);
                        if (nameCtrl.text.trim().isEmpty || qty == null) return;
                        final db = DatabaseHelper.instance;
                        await db.insertStock(
                          nameCtrl.text.trim(),
                          qty,
                          unitCtrl.text.trim(),
                          db.formatDate(DateTime.now()),
                          linked?.id,
                        );
                        if (bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                        }
                        if (mounted) load();
                      },
                      child: const Text('Save to Kit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

    final lowStockItems = _stock.where((item) {
      final runOut = _runOutDate(item);
      return runOut != null && runOut.difference(DateTime.now()).inDays <= 5;
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3D Interactive Medicine Kit with Hinge Opening & Mascot Reveal
          InteractiveMedicineKit(
            totalItems: _stock.length,
            lowStockCount: lowStockItems,
            onAddStock: addStock,
            onAnimationComplete: () {
              if (mounted && !_revealed) {
                setState(() => _revealed = true);
              }
            },
          ),

          const SizedBox(height: 16),

          // Smoothly Animated Stock List / Empty State
          AnimatedOpacity(
            opacity: _revealed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: _revealed ? Offset.zero : const Offset(0, 0.05),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_stock.isEmpty) ...[
                    EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'Medicine Kit is Empty',
                      description: 'Log your purchased medications and bottles to automatically track when supplies run low.',
                      actionLabel: 'Log First Purchase',
                      onAction: addStock,
                    ),
                  ] else ...[
                    ..._stock.map((item) {
                      final runOut = _runOutDate(item);
                      final fraction = _fractionLeft(item);
                      final isLow = runOut != null && runOut.difference(DateTime.now()).inDays <= 5;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          border: isLow
                              ? Border.all(color: AppColors.warning, width: 1.2)
                              : null,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isLow ? AppColors.warning : AppColors.primary)
                                      .withValues(alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: isLow ? AppColors.warning : AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isLow)
                                          const StatusBadge(
                                            label: 'Low Stock',
                                            variant: BadgeVariant.warning,
                                            fontSize: 10,
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['quantity']} ${item['unit']} • Bought ${formatDateReadable(item['date_bought'])}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    if (fraction != null && runOut != null) ...[
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: fraction,
                                          minHeight: 6,
                                          backgroundColor: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFE5E9F0),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isLow ? AppColors.warning : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Est. runs out: ${formatDateReadable(DatabaseHelper.instance.formatDate(runOut))}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isLow ? FontWeight.w700 : FontWeight.w500,
                                          color: isLow
                                              ? AppColors.warning
                                              : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remove from Kit?'),
                                      content: Text('Remove ${item['name']} from stock?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await DatabaseHelper.instance.deleteStock(item['id'] as int);
                                    load();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
