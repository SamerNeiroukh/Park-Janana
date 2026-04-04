import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/widgets/worker_shift_card.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/core/widgets/shimmer_loading.dart';

class ShiftsScreen extends StatefulWidget {
  final DateTime? initialDate;
  final ShiftModel? initialShift;

  const ShiftsScreen({super.key, this.initialDate, this.initialShift});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final ShiftService _shiftService = ShiftService();

  late DateTime _currentWeekStart;
  late DateTime _selectedDay;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    final target = widget.initialShift?.parsedDate ?? widget.initialDate ?? DateTime.now();
    _currentWeekStart = target.subtract(Duration(days: target.weekday % 7));
    _selectedDay = target;

    if (widget.initialShift != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final shift = widget.initialShift!;
        final departmentColor = _departmentColorFor(shift.department);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: ShiftDetailsPopup(
              shift: shift,
              shiftService: _shiftService,
              departmentColor: departmentColor,
            ),
          ),
        );
      });
    }
  }

  Color _departmentColorFor(String department) {
    switch (department) {
      case 'פיינטבול':
        return const Color(0xFFE53935);
      case 'פארק חבלים':
        return const Color(0xFF43A047);
      case 'קרטינג':
        return const Color(0xFFFF9800);
      case 'פארק מים':
        return const Color(0xFF1E88E5);
      case 'גמבורי':
        return const Color(0xFF8E24AA);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            const UserHeader(),
            _buildWeekHeader(),
            _buildDaySelector(),
            Expanded(child: _buildShiftList(currentUser)),
          ],
        ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WEEK HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildWeekHeader() {
    final startDate = DateTimeUtils.formatDate(_currentWeekStart);
    final endDate = DateTimeUtils.formatDate(
      _currentWeekStart.add(const Duration(days: 6)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavButton(
            icon: PhosphorIconsRegular.caretLeft,
            onTap: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.subtract(const Duration(days: 7));
              _selectedDay = _currentWeekStart;
            }),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _l10n.shiftsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$startDate - $endDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildNavButton(
            icon: PhosphorIconsRegular.caretRight,
            onTap: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.add(const Duration(days: 7));
              _selectedDay = _currentWeekStart;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DAY SELECTOR
  // ═══════════════════════════════════════════════════════════

  Widget _buildDaySelector() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          reverse: true, // Shows Sunday on right, Saturday on left
          itemCount: 7,
          itemBuilder: (context, index) {
            final day = _currentWeekStart.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(day, _selectedDay);
          final isToday = DateUtils.isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTimeUtils.getLocalizedWeekdayName(day.weekday, Localizations.localeOf(context).languageCode),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('dd').format(day),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHIFT LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildShiftList(User? currentUser) {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsForWeek(_currentWeekStart),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(cardHeight: 100, cardBorderRadius: 24);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            _l10n.noShiftsAvailableEmpty,
            _l10n.shiftsComingSoonSubtitle,
          );
        }

        final filteredShifts = snapshot.data!.where((shift) {
          return shift.date == DateFormat('dd/MM/yyyy').format(_selectedDay);
        }).toList();

        if (filteredShifts.isEmpty) {
          return _buildEmptyState(
            _l10n.noShiftsForDay,
            _l10n.selectOtherDayHint,
          );
        }

        if (currentUser == null) {
          return _buildEmptyState(
            _l10n.userIdentificationError,
            _l10n.tryReconnectHint,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: filteredShifts.length,
          itemBuilder: (context, index) {
            return WorkerShiftCard(
              shift: filteredShifts[index],
              shiftService: _shiftService,
              currentUser: currentUser,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.calendarX,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
