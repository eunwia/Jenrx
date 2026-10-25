import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'medicine_kit_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kitKey = GlobalKey<MedicineKitScreenState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kit & Stocks'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 84), // bottom padding for FAB
        child: MedicineKitScreen(
          key: kitKey,
          isStandalone: true,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log New Purchase',
        backgroundColor: AppColors.primary,
        elevation: 3,
        shape: const CircleBorder(),
        onPressed: () => kitKey.currentState?.addStock(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}
