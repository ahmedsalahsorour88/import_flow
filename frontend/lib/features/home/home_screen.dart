import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../external_service_providers/screens/partners_screen.dart';
import '../import_companies/screens/import_companies_screen.dart';
import '../suppliers/screens/suppliers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardTab(),
    ImportCompaniesScreen(),
    SuppliersScreen(),
    PartnersScreen(),
    Center(child: Text('Customs & Cost - Coming Soon', style: TextStyle(fontSize: 18, color: Colors.grey))),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppTheme.charcoal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'ImportFlow ERP',
                    style: TextStyle(
                      color: AppTheme.cloudWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: AppTheme.cloudWhite, height: 1),
                _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
                _buildMenuItem(Icons.domain, 'Import Companies', 1),
                _buildMenuItem(Icons.business, 'Suppliers', 2),
                _buildMenuItem(Icons.account_balance, 'Partners & Banks', 3),
                _buildMenuItem(Icons.calculate, 'Customs & Cost', 4),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      color: isSelected ? AppTheme.cobalt.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cloudWhite,
      child: Column(
        children: [
          // App Bar Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: AppTheme.charcoal),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    const CircleAvatar(
                      backgroundColor: AppTheme.cobalt,
                      child: Text('AF', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to ImportFlow ERP',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard('Active Imports', '12', AppTheme.cobalt),
                      const SizedBox(width: 24),
                      _buildStatCard('Pending Clearance', '4', AppTheme.orange),
                      const SizedBox(width: 24),
                      _buildStatCard('Completed', '89', AppTheme.emerald),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
