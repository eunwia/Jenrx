import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../utils/med_icons.dart';

class MedicineKitScreen extends StatefulWidget {
  const MedicineKitScreen({super.key});
  @override
  State<MedicineKitScreen> createState() => _MedicineKitScreenState();
}

class _MedicineKitScreenState extends State<MedicineKitScreen> {
  List<Map<String, dynamic>> _stock = [];
  List<Medication> _meds = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final stock = await db.getStock();
    final meds = await db.getActiveMedications();
    setState(() { _stock = stock; _meds = meds; });
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

  Future<void> _addStock() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'tablets');
    Medication? linked;

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
              const Text('Log New Purchase', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<Medication?>(
                decoration: const InputDecoration(labelText: 'Link to a medication (optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None / other item')),
                  ..._meds.map((m) => DropdownMenuItem(value: m, child: Text(m.name))),
                ],
                onChanged: (v) => setSheetState(() {
                  linked = v;
                  if (v != null) nameCtrl.text = v.name;
                }),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(labelText: 'Medicine Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: unitCtrl, style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Unit (tablets, ml)', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565F5), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    final qty = int.tryParse(qtyCtrl.text);
                    if (nameCtrl.text.trim().isEmpty || qty == null) return;
                    final db = DatabaseHelper.instance;
                    await db.insertStock(nameCtrl.text.trim(), qty, unitCtrl.text.trim(),
                        db.formatDate(DateTime.now()), linked?.id);
                    if (mounted) Navigator.pop(context);
                    _load();
                  },
                  child: const Text('Save Purchase', style: TextStyle(fontSize: 18)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1565F5), Color(0xFF3D8BFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Medicine Kit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 30),
                  onPressed: _addStock,
                ),
              ],
            ),
          ),
          if (_stock.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text('No medicine stock logged yet.', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._stock.map((item) {
              final runOut = _runOutDate(item);
              final fraction = _fractionLeft(item);
              final low = runOut != null && runOut.difference(DateTime.now()).inDays <= 5;

              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                  border: low ? Border.all(color: Colors.orange, width: 1.5) : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: (low ? Colors.orange : const Color(0xFF1565F5)).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication, color: low ? Colors.orange : const Color(0xFF1565F5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('${item['quantity']} ${item['unit']} • bought ${formatDateReadable(item['date_bought'])}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          if (fraction != null && runOut != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 6,
                                backgroundColor: Colors.grey[300],
                                color: low ? Colors.orange : const Color(0xFF1565F5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Est. runs out: ${formatDateReadable(DatabaseHelper.instance.formatDate(runOut))}',
                              style: TextStyle(fontSize: 12, color: low ? Colors.orange[800] : Colors.grey[600], fontWeight: low ? FontWeight.bold : null),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteStock(item['id'] as int);
                        _load();
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}