import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'plaid_service.dart';

Future<void> main() async {

  await dotenv.load(fileName: ".env");

  runApp(const FinDashboardApp());
}

class FinDashboardApp extends StatelessWidget {
  const FinDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pennywise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff156b5d),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff6f7f2),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  bool _isConnected = false;
  bool _isConnecting = false;
  final PlaidService _plaidService = PlaidService(
    baseUrl: dotenv.env['PLAID_API_BASE_URL'], 
    // clientId: dotenv.env['Client_ID_plaid'], 
    // secret: dotenv.env['Secret_plaid']  
    );

  Future<void> _connectBank() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);

    try {
      final linkToken = await _plaidService.createLinkToken(userId: 'user-id');
      if (!mounted) return;
      setState(() => _isConnected = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Link token created (${linkToken.substring(0, 12)}...). Open Plaid Link here.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect bank: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('Error creating link token: $error');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              _SideNav(
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _TopBar(
                      isConnected: _isConnected,
                      onConnect: _connectBank,
                      isConnecting: _isConnecting,
                      isWide: isWide,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 42 : 20,
                      16,
                      isWide ? 42 : 20,
                      40,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _DashboardContent(
                        isConnected: _isConnected,
                        onConnect: _connectBank,
                        isConnecting: _isConnecting,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Bills',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Accounts',
                ),
              ],
            ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 238,
    color: const Color(0xff183d38),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 54),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xfff3bf63), size: 24),
              SizedBox(width: 10),
              Text(
                'pennywise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _NavItem(
          icon: Icons.grid_view_rounded,
          label: 'Overview',
          active: selectedIndex == 0,
          onTap: () => onSelected(0),
        ),
        _NavItem(
          icon: Icons.receipt_long_rounded,
          label: 'Bills & payments',
          active: selectedIndex == 1,
          onTap: () => onSelected(1),
        ),
        _NavItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Accounts',
          active: selectedIndex == 2,
          onTap: () => onSelected(2),
        ),
        const Spacer(),
        const Text(
          'YOUR PLAN',
          style: TextStyle(
            color: Color(0xff8eaca4),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Everything in one place.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      selected: active,
      selectedTileColor: const Color(0xff2d6158),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        color: active ? const Color(0xfff3bf63) : const Color(0xff9cb7b0),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xffb7cbc5),
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isConnected,
    required this.onConnect,
    required this.isConnecting,
    required this.isWide,
  });
  final bool isConnected;
  final VoidCallback onConnect;
  final bool isConnecting;
  final bool isWide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(isWide ? 42 : 20, 26, isWide ? 42 : 20, 0),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tuesday, August 25',
                style: TextStyle(color: Color(0xff75827d), fontSize: 13),
              ),
              SizedBox(height: 5),
              Text(
                'Good morning, Alex',
                style: TextStyle(
                  color: Color(0xff173c37),
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xff4f5f5a),
          ),
        ),
        const CircleAvatar(
          backgroundColor: Color(0xfff0c978),
          child: Text(
            'A',
            style: TextStyle(
              color: Color(0xff624b1f),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isWide) ...[
          const SizedBox(width: 18),
          FilledButton.icon(
            onPressed: isConnecting ? null : onConnect,
            icon: isConnecting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isConnected ? Icons.check_rounded : Icons.add_rounded),
            label: Text(
              isConnecting
                  ? 'Connecting...'
                  : isConnected
                  ? 'Bank connected'
                  : 'Connect a bank',
            ),
          ),
        ],
      ],
    ),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.isConnected,
    required this.onConnect,
    required this.isConnecting,
  });
  final bool isConnected;
  final VoidCallback onConnect;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isWide)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isConnecting ? null : onConnect,
              icon: isConnecting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isConnected ? Icons.check_rounded : Icons.add_rounded),
              label: Text(
                isConnecting
                    ? 'Connecting...'
                    : isConnected
                    ? 'Bank connected'
                    : 'Connect a bank',
              ),
            ),
          ),
        if (!isWide) const SizedBox(height: 20),
        _BalanceCard(isConnected: isConnected),
        const SizedBox(height: 28),
        const Text(
          'Your money at a glance',
          style: TextStyle(
            color: Color(0xff173c37),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 3 : 1,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: isWide ? 1.65 : 2.7,
          children: const [
            _StatCard(
              icon: Icons.trending_up_rounded,
              label: 'Income this month',
              value: '\$4,820.00',
              note: '+12.4% vs last month',
              color: Color(0xffd7eee4),
            ),
            _StatCard(
              icon: Icons.trending_down_rounded,
              label: 'Spent this month',
              value: '\$2,146.32',
              note: '42% of your income',
              color: Color(0xffffe7c5),
            ),
            _StatCard(
              icon: Icons.savings_outlined,
              label: 'Set aside',
              value: '\$1,240.00',
              note: 'On track for your goal',
              color: Color(0xffe6e2f3),
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _UpcomingCard()),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: _PaydayCard()),
            ],
          )
        else ...[
          _UpcomingCard(),
          const SizedBox(height: 18),
          _PaydayCard(),
        ],
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.isConnected});
  final bool isConnected;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xff246257),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TOTAL BALANCE',
              style: TextStyle(
                color: Color(0xffa9d1c3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
            const Spacer(),
            Icon(
              isConnected ? Icons.verified_rounded : Icons.visibility_outlined,
              color: const Color(0xfff3bf63),
              size: 19,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '\$18,642.80',
          style: TextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isConnected
              ? 'Updated just now across 2 accounts'
              : 'Demo data • Connect your bank to sync',
          style: const TextStyle(color: Color(0xffb9d6cc), fontSize: 13),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final String note;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffe6ebe5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xff24574e)),
            ),
            const Spacer(),
            const Icon(Icons.more_horiz_rounded, color: Color(0xffa1aca7)),
          ],
        ),
        const Spacer(),
        Text(
          label,
          style: const TextStyle(color: Color(0xff75827d), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xff173c37),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          note,
          style: const TextStyle(
            color: Color(0xff4a9173),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _UpcomingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Upcoming bills',
    action: 'See all',
    child: Column(
      children: const [
        _BillRow(
          icon: Icons.home_work_outlined,
          name: 'Rent',
          date: 'Due in 3 days',
          amount: '\$1,450.00',
          color: Color(0xffdce9f5),
        ),
        _BillRow(
          icon: Icons.wifi_rounded,
          name: 'Wi-Fi',
          date: 'Due in 8 days',
          amount: '\$64.99',
          color: Color(0xffffe4ca),
        ),
        _BillRow(
          icon: Icons.play_circle_outline_rounded,
          name: 'Streamly',
          date: 'Due in 12 days',
          amount: '\$15.99',
          color: Color(0xffe9e1f3),
        ),
      ],
    ),
  );
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.icon,
    required this.name,
    required this.date,
    required this.amount,
    required this.color,
  });
  final IconData icon;
  final String name;
  final String date;
  final String amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xff3d5c64), size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xff173c37),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(color: Color(0xff89938e), fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: Color(0xff173c37),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PaydayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Next payday',
    action: 'Calendar',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Friday, August 29',
          style: TextStyle(
            color: Color(0xff173c37),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'in 4 days',
          style: TextStyle(color: Color(0xff75827d), fontSize: 13),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const LinearProgressIndicator(
            value: .72,
            minHeight: 8,
            backgroundColor: Color(0xffe3eee9),
            color: Color(0xffe5ac4c),
          ),
        ),
        const SizedBox(height: 9),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pay period',
              style: TextStyle(color: Color(0xff89938e), fontSize: 11),
            ),
            Text(
              '\$2,410 expected',
              style: TextStyle(
                color: Color(0xff4a9173),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.action,
    required this.child,
  });
  final String title;
  final String action;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffe6ebe5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xff173c37),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              action,
              style: const TextStyle(
                color: Color(0xff43856f),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
