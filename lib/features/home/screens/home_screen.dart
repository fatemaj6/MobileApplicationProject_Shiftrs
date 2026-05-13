import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, dynamic>?> _getCurrentUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) return null;

    return userDoc.data();
  }

  bool _isFamilyMember(String role) {
    final normalizedRole = role.toLowerCase().replaceAll(' ', '_');

    return normalizedRole == 'family_member' ||
        normalizedRole == 'familymember' ||
        normalizedRole == 'family';
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _medicationsStream({
    required bool isFamily,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Stream.empty();
    }

    final uid = currentUser.uid;
    final userField = isFamily ? 'patientId' : 'caregiverId';

    return FirebaseFirestore.instance
        .collection('medications')
        .where(userField, isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isDeleted'] != true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCurrentUserData(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text('Back to Login'),
              ),
            ),
          );
        }

        final userData = userSnapshot.data!;
        final fullName = userData['fullName'] ?? userData['name'] ?? 'User';
        final email = userData['email'] ?? '';
        final role = userData['role'] ?? '';

        final isFamily = _isFamilyMember(role);

        return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _medicationsStream(isFamily: isFamily),
          builder: (context, medicationSnapshot) {
            if (medicationSnapshot.hasError) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: ${medicationSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                ),
              );
            }

            final medicationDocs = medicationSnapshot.data ?? [];

            final givenCount = medicationDocs
                .where((doc) => doc.data()['status'] == 'given')
                .length;

            final pendingCount = medicationDocs
                .where((doc) => doc.data()['status'] == 'pending')
                .length;

            final missedCount = medicationDocs
                .where((doc) => doc.data()['status'] == 'missed')
                .length;

            final totalCount = medicationDocs.length;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _HeaderSection(
                        fullName: fullName,
                        email: email,
                        isFamily: isFamily,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Transform.translate(
                          offset: const Offset(0, -28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isFamily)
                                _FamilySummaryCard(
                                  totalCount: totalCount,
                                  givenCount: givenCount,
                                  pendingCount: pendingCount,
                                  missedCount: missedCount,
                                )
                              else
                                _CaregiverStatsRow(
                                  givenCount: givenCount,
                                  pendingCount: pendingCount,
                                  missedCount: missedCount,
                                ),

                              const SizedBox(height: 24),

                              if (isFamily)
                                _FamilyMedicationStatus(
                                  givenCount: givenCount,
                                  pendingCount: pendingCount,
                                  missedCount: missedCount,
                                )
                              else
                                _CaregiverQuickActions(
                                  pendingCount: pendingCount,
                                ),

                              const SizedBox(height: 24),

                              _ComingSoonSection(isFamily: isFamily),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _BottomNavigation(isFamily: isFamily),
            );
          },
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String fullName;
  final String email;
  final bool isFamily;

  const _HeaderSection({
    required this.fullName,
    required this.email,
    required this.isFamily,
  });

  String get _initial {
    if (fullName.trim().isEmpty) return 'U';
    return fullName.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = isFamily ? AppColors.purpleLight : AppColors.primaryLight;
    final dark = isFamily ? AppColors.purple : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 58),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isFamily ? 'Family Dashboard' : 'Good morning',
                  style: AppTextStyles.secondarySm.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  child: Text(
                    _initial,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primaryFg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.22),
                child: const Icon(
                  Icons.notifications_none,
                  color: AppColors.primaryFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isFamily ? 'Care Overview' : 'Care Dashboard',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primaryFg,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.95),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor:
                      isFamily ? AppColors.purpleBg : AppColors.cyanBg,
                  child: Text(
                    _initial,
                    style: AppTextStyles.h3.copyWith(
                      color: dark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: AppTextStyles.h4),
                      if (email.toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: AppTextStyles.secondarySm,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _UserTag(
                            label: isFamily ? 'Family Member' : 'Caregiver',
                            color: dark,
                          ),
                          if (isFamily)
                            const _UserTag(
                              label: 'Temporary View',
                              color: AppColors.purple,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTag extends StatelessWidget {
  final String label;
  final Color color;

  const _UserTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CaregiverStatsRow extends StatelessWidget {
  final int givenCount;
  final int pendingCount;
  final int missedCount;

  const _CaregiverStatsRow({
    required this.givenCount,
    required this.pendingCount,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.given,
            iconBg: AppColors.givenBg,
            number: givenCount.toString(),
            label: 'Given',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            iconColor: AppColors.pending,
            iconBg: AppColors.pendingBg,
            number: pendingCount.toString(),
            label: 'Pending',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.error_outline,
            iconColor: AppColors.destructive,
            iconBg: AppColors.missedBg,
            number: missedCount.toString(),
            label: 'Missed',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String number;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconBg,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(
            number,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: AppTextStyles.secondarySm),
        ],
      ),
    );
  }
}

class _CaregiverQuickActions extends StatelessWidget {
  final int pendingCount;

  const _CaregiverQuickActions({
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Give Medication',
                subtitle: '$pendingCount pending',
                icon: Icons.add,
                isPrimary: true,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.medications);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Add Care Note',
                subtitle: 'Next sprint',
                icon: Icons.add,
                isPrimary: false,
                isDisabled: true,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.primary : AppColors.card;
    final textColor = isPrimary ? AppColors.primaryFg : AppColors.foreground;
    final subColor = isPrimary ? Colors.white70 : AppColors.textSecondary;
    final iconBg =
        isPrimary ? Colors.white.withOpacity(0.22) : AppColors.purpleBg;
    final iconColor = isPrimary ? AppColors.primaryFg : AppColors.purple;

    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: isDisabled ? null : onTap,
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isPrimary ? Colors.transparent : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBg,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.bodySm.copyWith(color: subColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilySummaryCard extends StatelessWidget {
  final int totalCount;
  final int givenCount;
  final int pendingCount;
  final int missedCount;

  const _FamilySummaryCard({
    required this.totalCount,
    required this.givenCount,
    required this.pendingCount,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    final adherence =
        totalCount == 0 ? 0 : ((givenCount / totalCount) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Summary", style: AppTextStyles.h3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.given,
                  label: 'Medications',
                  value: '$givenCount/$totalCount',
                  caption: '$adherence% adherence',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.error_outline,
                  iconColor: AppColors.alertAmber,
                  label: 'Pending',
                  value: pendingCount.toString(),
                  caption: 'Need attention',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.secondarySm),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTextStyles.h1.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(caption, style: AppTextStyles.secondarySm),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyMedicationStatus extends StatelessWidget {
  final int givenCount;
  final int pendingCount;
  final int missedCount;

  const _FamilyMedicationStatus({
    required this.givenCount,
    required this.pendingCount,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Medication Status',
      actionText: 'View details',
      child: Column(
        children: [
          _StatusLine(
            label: 'Given',
            count: givenCount,
            color: AppColors.given,
          ),
          _StatusLine(
            label: 'Pending',
            count: pendingCount,
            color: AppColors.pending,
          ),
          _StatusLine(
            label: 'Missed',
            count: missedCount,
            color: AppColors.destructive,
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusLine({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.secondarySm),
          ),
          Text(
            count.toString(),
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonSection extends StatelessWidget {
  final bool isFamily;

  const _ComingSoonSection({
    required this.isFamily,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: isFamily ? 'Recent Activity' : 'Upcoming Appointments',
      actionText: 'View all',
      child: Text(
        'This section will be available in the next sprint.',
        style: AppTextStyles.secondarySm,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String actionText;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.actionText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.h3)),
              Text(
                actionText,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: IgnorePointer(child: child),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final bool isFamily;

  const _BottomNavigation({
    required this.isFamily,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isFamily ? AppColors.purple : AppColors.primary;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: activeColor,
      unselectedItemColor: AppColors.textMuted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        if (index == 1 && !isFamily) {
          Navigator.pushNamed(context, AppRoutes.medications);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is coming in the next sprint.'),
          ),
        );
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.link_outlined),
          activeIcon: Icon(Icons.link),
          label: 'Meds',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Appts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note_alt_outlined),
          activeIcon: Icon(Icons.note_alt),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome),
          label: 'AI',
        ),
      ],
    );
  }
}