import 'package:flutter/material.dart';
import 'package:budget_tracker/screens/budget_screen.dart';
import 'package:budget_tracker/screens/goals_screen.dart';
import 'package:budget_tracker/screens/expenses_screen.dart';
import 'package:budget_tracker/screens/income_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:window_size/window_size.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../models/AccountManager.dart';
import '../services/account_data_provider.dart';
import '../services/mock_account_data_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AccountManager accountManager;
  late AccountDataProvider accountDataProvider;
  Map<String, List<Map<String, dynamic>>> calendar = {};
  bool isLoading = true;
  bool _isSidebarPinned = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _openTabs = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeWindow();
    accountDataProvider = MockAccountDataProvider();
    _openTabs = [
      {
        'label': 'Dashboard',
        'builder': _buildDashboardTab,
      },
    ];
    _tabController = TabController(length: _openTabs.length + 1, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index < _openTabs.length) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void initializeWindow() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setWindowMaxSize(Size.infinite);
        setWindowMinSize(const Size(800, 600));
        getCurrentScreen().then((screen) {
          if (screen != null) {
            final frame = screen.visibleFrame;
            // Fallback to explicit Rect construction
            setWindowFrame(Rect.fromLTWH(
              frame.left,
              frame.top,
              frame.width,
              frame.height,
            ));
          }
        });
      });
    }
  }

  Future<void> loadData() async {
    final accounts = await accountDataProvider.fetchAccounts();
    accountManager = AccountManager();
    accountManager.accounts.addAll(accounts);
    setState(() {
      isLoading = false;
    });
  }

  void _addNewTab() {
    setState(() {
      if (_openTabs.isEmpty) {
        _openTabs.add({
          'label': 'Dashboard',
          'builder': _buildDashboardTab,
        });
        _selectedTabIndex = 0;
      } else {
        final safeIndex = _selectedTabIndex.clamp(0, _openTabs.length - 1);
        final currentTab = _openTabs[safeIndex];
        _openTabs.add(Map<String, dynamic>.from(currentTab));
      }
      _tabController.dispose();
      _tabController = TabController(length: _openTabs.length + 1, vsync: this);
      _tabController.addListener(() {
        if (_tabController.index < _openTabs.length) {
          setState(() {
            _selectedTabIndex = _tabController.index;
          });
        }
      });
      _tabController.animateTo(_openTabs.length - 1);
    });
  }

  void _openOrSwitchToTab(String label) {
    Widget Function() builder;
    switch (label) {
      case 'Dashboard':
        builder = _buildDashboardTab;
        break;
      case 'Budgets':
        builder = () => const BudgetScreen();
        break;
      case 'Goals':
        builder = _buildGoalsTab;
        break;
      case 'Expenses':
        builder = _buildExpensesTab;
        break;
      case 'Income':
        builder = _buildIncomeTab;
        break;
      default:
        return;
    }

    setState(() {
      if (_openTabs.isEmpty) {
        _openTabs.add({'label': label, 'builder': builder});
        _selectedTabIndex = 0;
      } else {
        _openTabs[_selectedTabIndex] = {'label': label, 'builder': builder};
      }

      _tabController.dispose();
      _tabController = TabController(length: _openTabs.length + 1, vsync: this);
      _tabController.addListener(() {
        if (_tabController.index < _openTabs.length) {
          setState(() {
            _selectedTabIndex = _tabController.index;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: AppBar(
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 48),
            child: Container(
              height: kToolbarHeight + 48,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isSidebarPinned ? Icons.push_pin : Icons.push_pin_outlined),
                    tooltip: 'Pin Sidebar',
                    onPressed: () {
                      setState(() => _isSidebarPinned = !_isSidebarPinned);
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: _isSidebarPinned ? 180 : 0),
                      child: TabBar(
                        isScrollable: true,
                        controller: _tabController,
                        tabs: [
                          ..._openTabs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tab = entry.value;
                            return Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(tab['label']),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _openTabs.removeAt(index);
                                        _tabController.dispose();
                                        _tabController = TabController(length: _openTabs.length + 1, vsync: this);
                                        _tabController.addListener(() {
                                          setState(() {
                                            _selectedTabIndex = _tabController.index;
                                          });
                                        });
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Tab(icon: Icon(Icons.add)),
                        ],
                        onTap: (index) {
                          if (index == _openTabs.length) {
                            _addNewTab();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [],
        ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              _Sidebar(isPinned: _isSidebarPinned),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ..._openTabs.map<Widget>((tab) => tab['builder']() as Widget),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    double totalBalance = accountManager.totalBalance();
    double monthlyIncome = accountManager.totalMonthlyIncome(DateTime.now().year, DateTime.now().month);
    double yearlyIncome = accountManager.totalYearlyIncome(DateTime.now().year);
    double monthlyExpenses = accountManager.totalMonthlyExpenses(DateTime.now().year, DateTime.now().month);
    double yearlyExpenses = accountManager.totalYearlyExpenses(DateTime.now().year);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Accounts", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                double maxCardWidth = 180;
                int crossAxisCount = (constraints.maxWidth / (maxCardWidth + 14)).floor();
                crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
                return GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    ...accountManager.accounts.map((acc) {
                      return GestureDetector(
                        onLongPress: () => _showDeleteAccountDialog(acc),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Card(
                            elevation: 2,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(acc.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text("\$${acc.balance.toStringAsFixed(2)}",
                                      style: Theme.of(context).textTheme.headlineSmall),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _showAddAccountDialog,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Card(
                          elevation: 2,
                          color: Colors.teal.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 40, color: Colors.teal),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text("Summary", style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                title: const Text("Total Balance"),
                trailing: Text("\$${totalBalance.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Monthly Income"),
                trailing: Text("\$${monthlyIncome.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Yearly Income"),
                trailing: Text("\$${yearlyIncome.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Monthly Expenses"),
                trailing: Text("\$${monthlyExpenses.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Yearly Expenses"),
                trailing: Text("\$${yearlyExpenses.toStringAsFixed(2)}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab builder methods for Goals, Expenses, Income
  Widget _buildGoalsTab() => const GoalsScreen();
  Widget _buildExpensesTab() => const ExpensesScreen();
  Widget _buildIncomeTab() => const IncomeScreen();

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Account Name"),
            ),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Initial Balance"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
              if (name.isNotEmpty) {
                setState(() {
                  accountManager.accounts.add(Account(name: name, balance: balance));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${account.name}?"),
        content: const Text("Are you sure you want to delete this account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                accountManager.accounts.remove(account);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final bool isPinned;
  const _Sidebar({required this.isPinned});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final shouldShow = widget.isPinned || _isHovering;
    // Access the parent state to call _openOrSwitchToTab
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    return Row(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          child: Container(width: 4, color: Colors.transparent),
        ),
        if (shouldShow)
          MouseRegion(
            onExit: (_) => setState(() {
              if (!widget.isPinned) _isHovering = false;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 180,
              color: Colors.grey.shade200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _SidebarButton(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () {
                      homeScreenState?._openOrSwitchToTab('Dashboard');
                    },
                  ),
                  _SidebarButton(
                    icon: Icons.pie_chart,
                    label: 'Budgets',
                    onTap: () {
                      homeScreenState?._openOrSwitchToTab('Budgets');
                    },
                  ),
                  _SidebarButton(
                    icon: Icons.sports_score,
                    label: 'Goals',
                    onTap: () {
                      homeScreenState?._openOrSwitchToTab('Goals');
                    },
                  ),
                  _SidebarButton(
                    icon: Icons.money_off,
                    label: 'Expenses',
                    onTap: () {
                      homeScreenState?._openOrSwitchToTab('Expenses');
                    },
                  ),
                  _SidebarButton(
                    icon: Icons.attach_money,
                    label: 'Income',
                    onTap: () {
                      homeScreenState?._openOrSwitchToTab('Income');
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
