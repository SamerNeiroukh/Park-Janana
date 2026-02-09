import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';
import 'package:park_janana/core/services/notification_service.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/core/widgets/message_bubble.dart';
import 'package:park_janana/features/workers/screens/users_screen.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'edit_shift_screen.dart';

class ShiftDetailsScreen extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;
  final WorkerService workerService;

  const ShiftDetailsScreen({
    super.key,
    required this.shift,
    required this.shiftService,
    required this.workerService,
  });

  @override
  State<ShiftDetailsScreen> createState() => _ShiftDetailsScreenState();
}

class _ShiftDetailsScreenState extends State<ShiftDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  int _selectedTab = 0;

  // ═══════════════════════════════════════════════════════════
  // DRAFT MODE STATE - Changes are not saved until user saves
  // ═══════════════════════════════════════════════════════════
  final Set<String> _pendingApprovals = {};
  final Set<String> _pendingRejections = {};
  final Set<String> _pendingRemovals = {};
  final Set<String> _pendingUndos = {};
  final Set<String> _pendingAdditions = {};
  bool _isSaving = false;
  bool _showSaveBar = true;
  final ScrollController _scrollController = ScrollController();

  bool get _hasUnsavedChanges =>
      _pendingApprovals.isNotEmpty ||
      _pendingRejections.isNotEmpty ||
      _pendingRemovals.isNotEmpty ||
      _pendingUndos.isNotEmpty ||
      _pendingAdditions.isNotEmpty;

  int get _pendingChangesCount =>
      _pendingApprovals.length +
      _pendingRejections.length +
      _pendingRemovals.length +
      _pendingUndos.length +
      _pendingAdditions.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  double _lastScrollOffset = 0;

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      // Scrolling down - hide save bar
      if (_showSaveBar) setState(() => _showSaveBar = false);
    } else if (currentOffset < _lastScrollOffset) {
      // Scrolling up - show save bar
      if (!_showSaveBar) setState(() => _showSaveBar = true);
    }
    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // DRAFT MODE ACTIONS
  // ═══════════════════════════════════════════════════════════

  void _approveWorker(String workerId) {
    setState(() {
      _pendingApprovals.add(workerId);
      _pendingRejections.remove(workerId);
    });
  }

  void _rejectWorker(String workerId) {
    setState(() {
      _pendingRejections.add(workerId);
      _pendingApprovals.remove(workerId);
    });
  }

  void _removeWorker(String workerId) {
    setState(() {
      _pendingRemovals.add(workerId);
      _pendingUndos.remove(workerId);
    });
  }

  void _undoWorker(String workerId) {
    setState(() {
      _pendingUndos.add(workerId);
      _pendingRemovals.remove(workerId);
    });
  }

  void _cancelPendingAction(String workerId) {
    setState(() {
      _pendingApprovals.remove(workerId);
      _pendingRejections.remove(workerId);
      _pendingRemovals.remove(workerId);
      _pendingUndos.remove(workerId);
      _pendingAdditions.remove(workerId);
    });
  }

  Future<void> _saveAllChanges(ShiftModel currentShift) async {
    if (!_hasUnsavedChanges || _isSaving) return;

    // Show confirmation dialog
    final confirmed = await _showSaveConfirmation(currentShift);
    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final List<String> affectedWorkers = [];
      final List<String> changeDescriptions = [];

      // Process approvals
      for (final workerId in _pendingApprovals) {
        await widget.shiftService.approveWorker(currentShift.id, workerId);
        affectedWorkers.add(workerId);
      }
      if (_pendingApprovals.isNotEmpty) {
        changeDescriptions.add('${_pendingApprovals.length} עובדים אושרו');
      }

      // Process rejections
      for (final workerId in _pendingRejections) {
        await widget.shiftService.rejectWorker(currentShift.id, workerId);
        affectedWorkers.add(workerId);
      }
      if (_pendingRejections.isNotEmpty) {
        changeDescriptions.add('${_pendingRejections.length} בקשות נדחו');
      }

      // Process removals
      for (final workerId in _pendingRemovals) {
        await widget.shiftService.removeWorker(currentShift.id, workerId);
        affectedWorkers.add(workerId);
      }
      if (_pendingRemovals.isNotEmpty) {
        changeDescriptions.add('${_pendingRemovals.length} עובדים הוסרו');
      }

      // Process undos (move back to requested)
      for (final workerId in _pendingUndos) {
        await widget.workerService
            .moveWorkerBackToRequested(currentShift.id, workerId);
        affectedWorkers.add(workerId);
      }
      if (_pendingUndos.isNotEmpty) {
        changeDescriptions
            .add('${_pendingUndos.length} עובדים הוחזרו לרשימת הממתינים');
      }

      // Process additions
      for (final workerId in _pendingAdditions) {
        await widget.workerService
            .assignWorkerToShift(currentShift.id, workerId);
        affectedWorkers.add(workerId);
      }
      if (_pendingAdditions.isNotEmpty) {
        changeDescriptions.add('${_pendingAdditions.length} עובדים נוספו');
      }

      // Send notifications (if notification service is available)
      if (affectedWorkers.isNotEmpty) {
        try {
          await NotificationService().notifyShiftUpdate(
            shiftId: currentShift.id,
            workerIds: affectedWorkers.toSet().toList(),
            shiftDate: currentShift.date,
            department: currentShift.department,
            changes: changeDescriptions,
          );
        } catch (e) {
          debugPrint('Notification error (non-blocking): $e');
        }
      }

      // Clear pending changes
      setState(() {
        _pendingApprovals.clear();
        _pendingRejections.clear();
        _pendingRemovals.clear();
        _pendingUndos.clear();
        _pendingAdditions.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'השינויים נשמרו בהצלחה!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת השינויים: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showSaveConfirmation(ShiftModel currentShift) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.save, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              const Text('שמירת שינויים'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'השינויים הבאים יישמרו:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (_pendingApprovals.isNotEmpty)
                _buildChangeItem('${_pendingApprovals.length} עובדים יאושרו',
                    AppColors.success),
              if (_pendingRejections.isNotEmpty)
                _buildChangeItem(
                    '${_pendingRejections.length} בקשות יידחו', Colors.red),
              if (_pendingRemovals.isNotEmpty)
                _buildChangeItem(
                    '${_pendingRemovals.length} עובדים יוסרו', Colors.red),
              if (_pendingUndos.isNotEmpty)
                _buildChangeItem(
                    '${_pendingUndos.length} עובדים יוחזרו לרשימת הממתינים',
                    AppColors.warningOrange),
              if (_pendingAdditions.isNotEmpty)
                _buildChangeItem('${_pendingAdditions.length} עובדים יתווספו',
                    AppColors.success),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('ביטול', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('שמור', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.arrow_back, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange),
              SizedBox(width: 12),
              Text('שינויים לא שמורים'),
            ],
          ),
          content: Text(
            'יש לך $_pendingChangesCount שינויים שלא נשמרו. האם אתה בטוח שברצונך לצאת?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('המשך לערוך',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('צא ללא שמירה',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  Color _getDepartmentColor(String department) {
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

  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'פיינטבול':
        return Icons.sports_esports;
      case 'פארק חבלים':
        return Icons.park;
      case 'קרטינג':
        return Icons.directions_car;
      case 'פארק מים':
        return Icons.pool;
      case 'גמבורי':
        return Icons.child_care;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: StreamBuilder<ShiftModel>(
            stream: widget.shiftService.getShiftStream(widget.shift.id),
            initialData: widget.shift,
            builder: (context, snapshot) {
              final ShiftModel currentShift = snapshot.data ?? widget.shift;

              final departmentColor =
                  _getDepartmentColor(currentShift.department);
              final departmentIcon = _getDepartmentIcon(currentShift.department);

              return Column(
                children: [
                  const Directionality(
                    textDirection: TextDirection.ltr,
                    child: UserHeader(),
                  ),
                  // Unsaved changes banner
                  if (_hasUnsavedChanges)
                    _buildUnsavedBanner(departmentColor),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildHeroCard(
                              currentShift, departmentColor, departmentIcon),
                          const SizedBox(height: 24),
                          _buildTabBar(currentShift, departmentColor),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.48,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildRequestsTab(currentShift, departmentColor),
                                _buildAssignedTab(currentShift, departmentColor),
                                _buildMessagesTab(currentShift, departmentColor),
                                _buildInfoTab(currentShift, departmentColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Save button pinned at bottom - animated hide/show on scroll
                  if (_hasUnsavedChanges)
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 250),
                      offset: _showSaveBar ? Offset.zero : const Offset(0, 1),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showSaveBar ? 1.0 : 0.0,
                        child: _buildSaveBar(currentShift),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUnsavedBanner(Color departmentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningOrange.withOpacity(0.1),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.edit_note, size: 20, color: AppColors.warningOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_pendingChangesCount שינויים ממתינים לשמירה',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.warningOrange,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pendingApprovals.clear();
                _pendingRejections.clear();
                _pendingRemovals.clear();
                _pendingUndos.clear();
                _pendingAdditions.clear();
              });
            },
            child: const Text(
              'בטל הכל',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(ShiftModel currentShift) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        elevation: 4,
        shadowColor: AppColors.success.withOpacity(0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isSaving ? null : () => _saveAllChanges(currentShift),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.save, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'שמור שינויים ($_pendingChangesCount)',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroCard(
      ShiftModel shift, Color departmentColor, IconData departmentIcon) {
    final assigned = shift.assignedWorkers.length;
    final max = shift.maxWorkers;
    final progress = max == 0 ? 0.0 : assigned / max;
    final requests = shift.requestedWorkers.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: departmentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(departmentIcon, size: 16, color: departmentColor),
                    const SizedBox(width: 6),
                    Text(
                      shift.department,
                      style: TextStyle(
                        color: departmentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (requests > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.pending_actions,
                          size: 14, color: AppColors.warningOrange),
                      const SizedBox(width: 4),
                      Text(
                        '$requests בקשות',
                        style: const TextStyle(
                          color: AppColors.warningOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              // Edit button
              Material(
                color: departmentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditShiftScreen(
                          shift: shift,
                          shiftService: widget.shiftService,
                        ),
                      ),
                    );
                    // Refresh handled by StreamBuilder
                    if ((result ?? false) && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('המשמרת עודכנה בהצלחה'),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle, color: Colors.white),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: departmentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    shift.formattedDateWithDay,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    '${shift.startTime} - ${shift.endTime}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'עובדים',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: progress >= 1
                                  ? [
                                      AppColors.success,
                                      AppColors.success.withOpacity(0.8)
                                    ]
                                  : [
                                      departmentColor,
                                      departmentColor.withOpacity(0.7)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$assigned / $max',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progress >= 1 ? AppColors.success : departmentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildTabBar(ShiftModel shift, Color departmentColor) {
    final tabs = [
      _TabItem(Icons.pending_actions_outlined, 'בקשות',
          shift.requestedWorkers.length),
      _TabItem(Icons.group_outlined, 'מאושרים', shift.assignedWorkers.length),
      _TabItem(Icons.chat_bubble_outline, 'הודעות', shift.messages.length),
      _TabItem(Icons.info_outline, 'פרטים', 0),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? departmentColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          tabs[i].icon,
                          size: 22,
                          color: isSelected
                              ? departmentColor
                              : Colors.grey.shade500,
                        ),
                        if (tabs[i].badge > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: i == 2
                                    ? departmentColor
                                    : AppColors.warningOrange,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${tabs[i].badge}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabs[i].label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? departmentColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // REQUESTS TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildRequestsTab(ShiftModel shift, Color departmentColor) {
    return _buildWorkerList(
      workerIds: shift.requestedWorkers,
      emptyIcon: Icons.hourglass_empty_rounded,
      emptyText: 'אין בקשות ממתינות',
      emptySubtext: 'בקשות חדשות יופיעו כאן',
      departmentColor: departmentColor,
      actionBuilder: (user) {
        final isPendingApproval = _pendingApprovals.contains(user.uid);
        final isPendingRejection = _pendingRejections.contains(user.uid);

        if (isPendingApproval) {
          return _buildPendingLabel(
            'יאושר',
            AppColors.success,
            () => _cancelPendingAction(user.uid),
          );
        }
        if (isPendingRejection) {
          return _buildPendingLabel(
            'יידחה',
            Colors.red,
            () => _cancelPendingAction(user.uid),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.close_rounded,
              color: const Color(0xFFE53935),
              onTap: () => _rejectWorker(user.uid),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.check_rounded,
              color: AppColors.success,
              onTap: () => _approveWorker(user.uid),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ASSIGNED TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildAssignedTab(ShiftModel shift, Color departmentColor) {
    final isFull = shift.assignedWorkers.length >= shift.maxWorkers;

    return Column(
      children: [
        // Add Workers Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Material(
            color: isFull
                ? Colors.grey.shade300
                : departmentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isFull
                  ? null
                  : () async {
                      final result = await Navigator.push<List<String>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UsersScreen(
                            shiftId: shift.id,
                            assignedWorkerIds: [
                              ...shift.assignedWorkers,
                              ..._pendingAdditions,
                            ],
                            draftMode: true,
                          ),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _pendingAdditions.addAll(result);
                        });
                      }
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      isFull ? Icons.check_circle : Icons.person_add_rounded,
                      size: 20,
                      color: isFull ? Colors.grey.shade600 : departmentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFull ? 'המשמרת מלאה' : 'הוסף עובדים',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isFull ? Colors.grey.shade600 : departmentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Worker List
        Expanded(
          child: _buildAssignedWorkersList(shift, departmentColor),
        ),
      ],
    );
  }

  Widget _buildAssignedWorkersList(ShiftModel shift, Color departmentColor) {
    final allWorkerIds = [
      ...shift.assignedWorkers,
      ..._pendingAdditions.where((id) => !shift.assignedWorkers.contains(id)),
    ];

    if (allWorkerIds.isEmpty) {
      return _buildEmptyState(
        Icons.group_off_outlined,
        'אין עובדים משובצים',
        'לחץ על "הוסף עובדים" להוספה ידנית',
        departmentColor,
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: widget.shiftService.fetchWorkerDetails(allWorkerIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: departmentColor),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            final isPendingAddition = _pendingAdditions.contains(user.uid);
            final isPendingRemoval = _pendingRemovals.contains(user.uid);
            final isPendingUndo = _pendingUndos.contains(user.uid);

            Widget actions;
            if (isPendingAddition) {
              actions = _buildPendingLabel(
                'יתווסף',
                AppColors.success,
                () => _cancelPendingAction(user.uid),
              );
            } else if (isPendingRemoval) {
              actions = _buildPendingLabel(
                'יוסר',
                Colors.red,
                () => _cancelPendingAction(user.uid),
              );
            } else if (isPendingUndo) {
              actions = _buildPendingLabel(
                'יוחזר',
                AppColors.warningOrange,
                () => _cancelPendingAction(user.uid),
              );
            } else {
              actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.undo_rounded,
                    color: AppColors.warningOrange,
                    onTap: () => _undoWorker(user.uid),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.person_remove_rounded,
                    color: const Color(0xFFE53935),
                    onTap: () => _removeWorker(user.uid),
                  ),
                ],
              );
            }

            return _buildWorkerCard(user, actions, departmentColor);
          },
        );
      },
    );
  }

  Widget _buildWorkerList({
    required List<String> workerIds,
    required IconData emptyIcon,
    required String emptyText,
    required String emptySubtext,
    required Color departmentColor,
    required Widget Function(UserModel) actionBuilder,
  }) {
    if (workerIds.isEmpty) {
      return _buildEmptyState(
          emptyIcon, emptyText, emptySubtext, departmentColor);
    }

    return FutureBuilder<List<UserModel>>(
      future: widget.shiftService.fetchWorkerDetails(workerIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: departmentColor),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return _buildWorkerCard(user, actionBuilder(user), departmentColor);
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(
      UserModel user, Widget actions, Color departmentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          FutureBuilder<ImageProvider>(
            future: ProfileImageProvider.resolve(
              storagePath: user.profilePicturePath,
              fallbackUrl: user.profilePicture,
            ),
            builder: (_, snap) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: departmentColor.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: departmentColor.withOpacity(0.1),
                backgroundImage: snap.data,
                child: snap.data == null
                    ? Icon(Icons.person, color: departmentColor)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          actions,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildPendingLabel(String text, Color color, VoidCallback onCancel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onCancel,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MESSAGES TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildMessagesTab(ShiftModel shift, Color departmentColor) {
    return Column(
      children: [
        Expanded(
          child: shift.messages.isEmpty
              ? _buildEmptyState(
                  Icons.chat_bubble_outline_rounded,
                  'אין הודעות עדיין',
                  'שלח הודעה ראשונה',
                  departmentColor,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: shift.messages.length,
                  itemBuilder: (context, index) {
                    final msg = shift.messages[index];
                    return MessageBubble(
                      message: msg['message'],
                      timestamp: msg['timestamp'],
                      senderId: msg['senderId'],
                      shiftId: shift.id,
                    );
                  },
                ),
        ),
        _buildMessageInput(shift, departmentColor),
      ],
    );
  }

  Widget _buildMessageInput(ShiftModel shift, Color departmentColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: departmentColor,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                final text = _messageController.text.trim();
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (text.isEmpty || uid == null) return;
                widget.shiftService.addMessageToShift(shift.id, text, uid);
                _messageController.clear();
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _messageController,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'כתוב הודעה...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INFO TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildInfoTab(ShiftModel shift, Color departmentColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildInfoCard(
          icon: Icons.flag_rounded,
          label: 'סטטוס',
          value: shift.status == 'active' ? 'פעיל' : shift.status,
          valueColor: shift.status == 'active' ? AppColors.success : null,
          departmentColor: departmentColor,
        ),
        _buildInfoCard(
          icon: Icons.person_outline_rounded,
          label: 'נוצר על ידי',
          value: shift.createdBy,
          isUserId: true,
          departmentColor: departmentColor,
        ),
        _buildInfoCard(
          icon: Icons.calendar_today_rounded,
          label: 'תאריך יצירה',
          value: shift.createdAt == null
              ? '-'
              : DateFormat('dd/MM/yyyy בשעה HH:mm')
                  .format(shift.createdAt!.toDate()),
          departmentColor: departmentColor,
        ),
        _buildInfoCard(
          icon: Icons.edit_outlined,
          label: 'עודכן לאחרונה על ידי',
          value: shift.lastUpdatedBy,
          isUserId: true,
          departmentColor: departmentColor,
        ),
        if (shift.shiftManager.isNotEmpty)
          _buildInfoCard(
            icon: Icons.admin_panel_settings_outlined,
            label: 'אחראי משמרת',
            value: shift.shiftManager,
            isUserId: true,
            departmentColor: departmentColor,
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color departmentColor,
    Color? valueColor,
    bool isUserId = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: departmentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: departmentColor),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          if (isUserId && value.isNotEmpty)
            FutureBuilder<List<UserModel>>(
              future: widget.shiftService.fetchWorkerDetails([value]),
              builder: (_, snap) {
                final name = snap.hasData && snap.data!.isNotEmpty
                    ? snap.data!.first.fullName
                    : value;
                return Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Colors.grey.shade800,
                    ),
                  ),
                );
              },
            )
          else
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.grey.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════

  Widget _buildEmptyState(
      IconData icon, String text, String subtext, Color departmentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: departmentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 48, color: departmentColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final int badge;

  _TabItem(this.icon, this.label, this.badge);
}
