import 'package:flutter/material.dart';
import 'medicine_kit_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Stocks')),
      body: const SingleChildScrollView(child: MedicineKitScreen()),
    );
  }
}