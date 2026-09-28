import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'bp_screen.dart';
import 'album_list_screen.dart';
import 'add_medication_screen.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(key: _dashboardKey),
      const CalendarScreen(),
      const BpScreen(),
      AlbumListScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: _index == 0
            ? Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Image.asset('assets/images/jen_logo_name.png', height: 44, fit: BoxFit.contain, alignment: Alignment.centerLeft),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, size: 28, color: Color(0xFF1565F5)),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen())),
                        ),
                        Image.asset('assets/images/jen_home.png', height: 72),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const StockScreen())),
                      child: Container(
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
                              child: Text('View Medicine Stocks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const Icon(Icons.visibility, color: Colors.white, size: 26),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: screens[0]),
                ],
              )
            : screens[_index],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565F5),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddMedicationScreen()));
          if (result == true) _dashboardKey.currentState?.refresh();
        },
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 30,
                  color: _index == 0 ? const Color(0xFF1565F5) : Colors.grey),
              onPressed: () => setState(() => _index = 0),
            ),
            IconButton(
              icon: Icon(Icons.calendar_month, size: 30,
                  color: _index == 1 ? const Color(0xFF1565F5) : Colors.grey),
              onPressed: () => setState(() => _index = 1),
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: Icon(Icons.favorite, size: 30,
                  color: _index == 2 ? const Color(0xFF1565F5) : Colors.grey),
              onPressed: () => setState(() => _index = 2),
            ),
            IconButton(
              icon: Icon(Icons.photo_library, size: 30,
                  color: _index == 3 ? const Color(0xFF1565F5) : Colors.grey),
              onPressed: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );
  }
}