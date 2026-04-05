import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:khata/config/app_theme.dart';
import 'package:khata/providers/auth_provider.dart';
import 'package:khata/providers/profile_provider.dart';
import 'package:khata/providers/dashboard_provider.dart';
import 'package:khata/providers/bill_provider.dart';
import 'package:khata/providers/customer_provider.dart';
import 'package:khata/providers/product_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(profile),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildTabBar(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStatsTab(),
                          _buildProfileTab(profile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────── SLIVER APP BAR ─────────────────────────────

  Widget _buildSliverAppBar(ProfileProvider profile) {
    final auth = context.watch<AuthProvider>();
    final shopName = profile.shopName ?? auth.shopName ?? 'My Shop';
    final fullName = profile.fullName ?? auth.ownerName ?? 'Owner';
    final initials = _initials(fullName);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHeader(shopName, fullName, initials),
      ),
      actions: [
        IconButton(
          tooltip: 'Edit Profile',
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () => _showEditProfileSheet(context, profile),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (val) => _handleMenu(val, context),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'change_password',
              child: Row(children: [
                Icon(Icons.lock_outline, size: 18),
                SizedBox(width: 8),
                Text('Change Password'),
              ]),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
      String shopName, String ownerName, String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                shopName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ownerName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── TAB BAR ─────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Stats & Activity'),
          Tab(text: 'Profile Details'),
        ],
      ),
    );
  }

  // ─────────────────────────────── STATS TAB ────────────────────────────────

  Widget _buildStatsTab() {
    return Consumer3<DashboardProvider, BillProvider, CustomerProvider>(
      builder: (context, dashboard, bills, customers, _) {
        final products = context.watch<ProductProvider>();
        final currencyFormat = NumberFormat.currency(
          symbol: '₹',
          decimalDigits: 0,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Business Summary ──
            _sectionTitle('Business Summary'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _statCard(
                  label: "Today's Sales",
                  value: currencyFormat.format(dashboard.todaySales),
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.successColor,
                  sub: '${dashboard.todayBillCount} bills',
                ),
                _statCard(
                  label: 'Monthly Sales',
                  value: currencyFormat.format(dashboard.monthlySales),
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.primaryColor,
                  sub: '${dashboard.monthlyBillCount} bills',
                ),
                _statCard(
                  label: 'Pending Dues',
                  value: currencyFormat.format(dashboard.totalPending),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.errorColor,
                  sub: 'Outstanding',
                ),
                _statCard(
                  label: 'Customers',
                  value: '${dashboard.customerCount}',
                  icon: Icons.people_rounded,
                  color: AppTheme.accentColor,
                  sub: 'Total registered',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Inventory Overview ──
            _sectionTitle('Inventory Overview'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: 'Products',
                    value: '${dashboard.productCount}',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.secondaryColor,
                    sub: 'In catalogue',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Low Stock',
                    value: '${dashboard.lowStockCount}',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    sub: 'Need reorder',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Quick Numbers ──
            _sectionTitle('Quick Numbers'),
            const SizedBox(height: 12),
            _infoTile(
              icon: Icons.receipt_long_outlined,
              color: AppTheme.primaryColor,
              title: 'Total Bills This Month',
              trailing: '${dashboard.monthlyBillCount}',
            ),
            _infoTile(
              icon: Icons.groups_outlined,
              color: AppTheme.accentColor,
              title: 'Total Customers',
              trailing: '${customers.customers.length}',
            ),
            _infoTile(
              icon: Icons.shopping_bag_outlined,
              color: AppTheme.secondaryColor,
              title: 'Total Products',
              trailing: '${products.products.length}',
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  // ─────────────────────────── PROFILE DETAILS TAB ─────────────────────────

  Widget _buildProfileTab(ProfileProvider profile) {
    final auth = context.watch<AuthProvider>();

    final shopName = profile.shopName ?? auth.shopName ?? '—';
    final fullName = profile.fullName ?? auth.ownerName ?? '—';
    final phone = profile.phone ?? auth.phone ?? '—';
    final email = profile.email ?? '—';
    final address = profile.address ?? '—';
    final gstNumber = profile.gstNumber ?? '—';

    return profile.isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Shop Information ──
              _sectionTitle('Shop Information'),
              const SizedBox(height: 12),
              _profileCard(children: [
                _profileField(
                    icon: Icons.store_outlined, label: 'Shop Name', value: shopName),
                _divider(),
                _profileField(
                    icon: Icons.person_outline, label: 'Owner Name', value: fullName),
                _divider(),
                _profileField(
                    icon: Icons.phone_outlined, label: 'Phone', value: phone),
                _divider(),
                _profileField(
                    icon: Icons.email_outlined, label: 'Email', value: email),
              ]),
              const SizedBox(height: 20),

              // ── Additional Info ──
              _sectionTitle('Additional Information'),
              const SizedBox(height: 12),
              _profileCard(children: [
                _profileField(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: address),
                _divider(),
                _profileField(
                    icon: Icons.receipt_outlined,
                    label: 'GST Number',
                    value: gstNumber),
              ]),
              const SizedBox(height: 20),

              // ── Account Actions ──
              _sectionTitle('Account'),
              const SizedBox(height: 12),
              _actionTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                color: AppTheme.primaryColor,
                onTap: () => _showChangePasswordSheet(context),
              ),
              const SizedBox(height: 8),
              _actionTile(
                icon: Icons.help_outline,
                label: 'Help & Support',
                color: AppTheme.accentColor,
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _actionTile(
                icon: Icons.info_outline,
                label: 'About App',
                color: AppTheme.textSecondary,
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 8),
              _actionTile(
                icon: Icons.logout,
                label: 'Logout',
                color: AppTheme.errorColor,
                onTap: () => _confirmLogout(context),
                isDestructive: true,
              ),
              const SizedBox(height: 80),
            ],
          );
  }

  // ─────────────────────── EDIT PROFILE BOTTOM SHEET ────────────────────────

  void _showEditProfileSheet(BuildContext context, ProfileProvider profile) {
    final auth = context.read<AuthProvider>();

    final shopCtrl =
        TextEditingController(text: profile.shopName ?? auth.shopName ?? '');
    final ownerCtrl =
        TextEditingController(text: profile.fullName ?? auth.ownerName ?? '');
    final phoneCtrl =
        TextEditingController(text: profile.phone ?? auth.phone ?? '');
    final emailCtrl = TextEditingController(text: profile.email ?? '');
    final addressCtrl = TextEditingController(text: profile.address ?? '');
    final gstCtrl = TextEditingController(text: profile.gstNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        shopCtrl: shopCtrl,
        ownerCtrl: ownerCtrl,
        phoneCtrl: phoneCtrl,
        emailCtrl: emailCtrl,
        addressCtrl: addressCtrl,
        gstCtrl: gstCtrl,
        onSave: () async {
          final success = await profile.updateProfile(
            shopName: shopCtrl.text.trim(),
            fullName: ownerCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
            address:
                addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
            gstNumber:
                gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
          );

          // Also update AuthProvider so the dashboard header is in sync
          if (success && context.mounted) {
            context.read<AuthProvider>().updateShopInfo(
                  shopName: shopCtrl.text.trim(),
                  ownerName: ownerCtrl.text.trim(),
                );
          }

          return success;
        },
      ),
    );
  }

  // ──────────────────── CHANGE PASSWORD BOTTOM SHEET ────────────────────────

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        onSave: (current, newPass) =>
            context.read<ProfileProvider>().changePassword(
                  currentPassword: current,
                  newPassword: newPass,
                ),
      ),
    );
  }

  // ──────────────────────── MENU HANDLER ───────────────────────────────────

  void _handleMenu(String val, BuildContext ctx) {
    if (val == 'logout') _confirmLogout(ctx);
    if (val == 'change_password') _showChangePasswordSheet(ctx);
  }

  // ─────────────────────────── LOGOUT DIALOG ───────────────────────────────

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<AuthProvider>().logout();
              if (ctx.mounted) {
                Navigator.of(ctx).pushReplacementNamed('/');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── ABOUT DIALOG ──────────────────────────────────

  void _showAboutDialog(BuildContext ctx) {
    showAboutDialog(
      context: ctx,
      applicationName: 'Khata – Smart Shopkeeper',
      applicationVersion: '1.0.0',
      applicationIcon:
          const Icon(Icons.store_rounded, size: 40, color: AppTheme.primaryColor),
      children: const [
        Text('A smart billing and ledger app for small businesses.'),
      ],
    );
  }

  // ──────────────────────────── HELPERS ────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.6,
        ),
      );

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500),
          ),
          if (sub != null)
            Text(sub,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color color,
    required String title,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
        trailing: Text(
          trailing,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      ),
    );
  }

  Widget _profileCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _profileField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 1, indent: 48, endIndent: 16, color: AppTheme.borderColor);

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: AppTheme.textSecondary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════ EDIT PROFILE BOTTOM SHEET ═════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final TextEditingController shopCtrl;
  final TextEditingController ownerCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController gstCtrl;
  final Future<bool> Function() onSave;

  const _EditProfileSheet({
    required this.shopCtrl,
    required this.ownerCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
    required this.gstCtrl,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                _inputField(
                    ctrl: widget.shopCtrl,
                    label: 'Shop Name',
                    icon: Icons.store_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _inputField(
                    ctrl: widget.ownerCtrl,
                    label: 'Owner Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _inputField(
                    ctrl: widget.phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _inputField(
                    ctrl: widget.emailCtrl,
                    label: 'Email (optional)',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _inputField(
                    ctrl: widget.addressCtrl,
                    label: 'Address (optional)',
                    icon: Icons.location_on_outlined,
                    maxLines: 2),
                const SizedBox(height: 12),
                _inputField(
                    ctrl: widget.gstCtrl,
                    label: 'GST Number (optional)',
                    icon: Icons.receipt_outlined),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await widget.onSave();
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Profile updated!' : '❌ Failed to update. Saved locally.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }
}

// ══════════════════════ CHANGE PASSWORD BOTTOM SHEET ═════════════════════════

class _ChangePasswordSheet extends StatefulWidget {
  final Future<bool> Function(String current, String newPass) onSave;

  const _ChangePasswordSheet({required this.onSave});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Change Password',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),

              _passwordField(
                  ctrl: _currentCtrl,
                  label: 'Current Password',
                  obscure: _obscureCurrent,
                  toggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _passwordField(
                  ctrl: _newCtrl,
                  label: 'New Password',
                  obscure: _obscureNew,
                  toggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  }),
              const SizedBox(height: 12),
              _passwordField(
                  ctrl: _confirmCtrl,
                  label: 'Confirm New Password',
                  obscure: _obscureConfirm,
                  toggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) =>
                      v != _newCtrl.text ? 'Passwords do not match' : null),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await widget.onSave(_currentCtrl.text, _newCtrl.text);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Password updated!' : '❌ Incorrect current password.'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 20, color: AppTheme.textSecondary),
          onPressed: toggle,
        ),
      ),
    );
  }
}
