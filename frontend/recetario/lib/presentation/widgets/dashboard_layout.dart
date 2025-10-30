import 'package:flutter/material.dart';

/// Layout reutilizable para pantallas de tipo dashboard
class DashboardLayout extends StatelessWidget {
  final Widget header;
  final Widget stats;
  final Widget actions;
  final Widget recentActivity;

  const DashboardLayout({
    Key? key,
    required this.header,
    required this.stats,
    required this.actions,
    required this.recentActivity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 32),
            // Stats section
            stats,
            const SizedBox(height: 32),
            // Actions and recent activity side-by-side on wide screens
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: actions),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: recentActivity),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      actions,
                      const SizedBox(height: 24),
                      recentActivity,
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
