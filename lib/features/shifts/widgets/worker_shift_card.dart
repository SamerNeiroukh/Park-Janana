import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/shift_model.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/core/widgets/message_bubble.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WorkerShiftCard extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;
  final User currentUser;

  const WorkerShiftCard({
    super.key,
    required this.shift,
    required this.shiftService,
    required this.currentUser,
  });

  @override
  State<WorkerShiftCard> createState() => _WorkerShiftCardState();
}

class _WorkerShiftCardState extends State<WorkerShiftCard>
    with SingleTickerProviderStateMixin {
  StreamSubscription<DocumentSnapshot>? _shiftSubscription;
  bool _hasRequested = false;
  bool _isShiftFull = false;
  bool _isAssigned = false;
  bool _isLoading = false;
  bool _isCancelled = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Color get _departmentColor {
    switch (widget.shift.department) {
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

  IconData get _departmentIcon {
    switch (widget.shift.department) {
      case 'פיינטבול':
        return PhosphorIconsRegular.gameController;
      case 'פארק חבלים':
        return PhosphorIconsRegular.tree;
      case 'קרטינג':
        return PhosphorIconsRegular.car;
      case 'פארק מים':
        return PhosphorIconsRegular.waves;
      case 'גמבורי':
        return PhosphorIconsRegular.baby;
      default:
        return PhosphorIconsRegular.briefcase;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _listenToShiftUpdates();
  }

  @override
  void dispose() {
    _shiftSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _listenToShiftUpdates() {
    _shiftSubscription = FirebaseFirestore.instance
        .collection(AppConstants.shiftsCollection)
        .doc(widget.shift.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final shiftData = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> requestedWorkers =
            shiftData['requestedWorkers'] ?? [];
        final List<dynamic> assignedWorkers =
            shiftData['assignedWorkers'] ?? [];

        setState(() {
          _hasRequested = requestedWorkers.contains(widget.currentUser.uid);
          _isAssigned = assignedWorkers.contains(widget.currentUser.uid);
          _isShiftFull =
              assignedWorkers.length >= (shiftData['maxWorkers'] ?? 0);
          _isCancelled = shiftData['status'] == 'cancelled';
        });
      }
    });
  }

  /// Returns true if [aStart, aEnd] overlaps with [bStart, bEnd] (HH:mm strings).
  bool _timesOverlap(String aStart, String aEnd, String bStart, String bEnd) {
    int? toMinutes(String t) {
      try {
        final parts = t.split(':');
        if (parts.length != 2) return null;
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        if (h < 0 || h > 23 || m < 0 || m > 59) return null;
        return h * 60 + m;
      } catch (_) {
        return null;
      }
    }

    final aS = toMinutes(aStart);
    final aE = toMinutes(aEnd);
    final bS = toMinutes(bStart);
    final bE = toMinutes(bEnd);
    if (aS == null || aE == null || bS == null || bE == null) return false;
    return aS < bE && bS < aE;
  }

  Future<bool> _hasConflict() async {
    final uid = widget.currentUser.uid;
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.shiftsCollection)
        .where('date', isEqualTo: widget.shift.date)
        .where('assignedWorkers', arrayContains: uid)
        .limit(10) // A worker can't have more than a handful of shifts per day.
        .get();

    for (final doc in snap.docs) {
      if (doc.id == widget.shift.id) continue;
      final data = doc.data();
      final existStart = data['startTime'] as String? ?? '';
      final existEnd = data['endTime'] as String? ?? '';
      if (_timesOverlap(widget.shift.startTime, widget.shift.endTime,
          existStart, existEnd)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _toggleShiftRequest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (_hasRequested) {
        await widget.shiftService
            .cancelShiftRequest(widget.shift.id, widget.currentUser.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(PhosphorIconsRegular.xCircle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('הבקשה למשמרת בוטלה',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Check for time conflicts before requesting
        final conflict = await _hasConflict();
        if (conflict && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Row(
                  children: [
                    Icon(PhosphorIconsRegular.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('התנגשות משמרות'),
                  ],
                ),
                content: Text(
                  'כבר משובץ למשמרת בתאריך זה בשעות החופפות '
                  '(${widget.shift.startTime}–${widget.shift.endTime}). '
                  'האם להמשיך בכל זאת?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('ביטול'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('המשך בכל זאת',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
          if (proceed != true) return;
        }
        await widget.shiftService
            .requestShift(widget.shift.id, widget.currentUser.uid);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showShiftDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftDetailsPopup(
        shift: widget.shift,
        shiftService: widget.shiftService,
        departmentColor: _departmentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime shiftDate =
        DateFormat('dd/MM/yyyy').parse(widget.shift.date);
    final bool isOutdated = shiftDate.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final progress = widget.shift.maxWorkers == 0
        ? 0.0
        : widget.shift.assignedWorkers.length / widget.shift.maxWorkers;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: _showShiftDetails,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _isCancelled ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isCancelled
                    ? Colors.grey.withValues(alpha: 0.1)
                    : isOutdated
                        ? Colors.grey.withValues(alpha: 0.15)
                        : _departmentColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: _isCancelled ? 0.65 : isOutdated ? 0.6 : 1.0,
            child: Column(
              children: [
                // Top gradient strip
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isCancelled
                          ? [Colors.red.shade400, Colors.red.shade200]
                          : [
                              _departmentColor,
                              _departmentColor.withValues(alpha: 0.6),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          // Department icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isCancelled
                                  ? Colors.red.shade50
                                  : _departmentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _isCancelled ? PhosphorIconsRegular.xCircle : _departmentIcon,
                              color: _isCancelled ? Colors.red.shade400 : _departmentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Department info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.shift.department,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isCancelled
                                        ? Colors.grey.shade500
                                        : _departmentColor,
                                    decoration: _isCancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: Colors.red.shade300,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.clock,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.shift.startTime} - ${widget.shift.endTime}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Action button
                          _buildActionButton(isOutdated),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status & Progress row
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            PhosphorIconsRegular.users,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.shift.assignedWorkers.length}/${widget.shift.maxWorkers}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isShiftFull
                                  ? AppColors.success
                                  : _departmentColor,
                            ),
                          ),
                          const Spacer(),
                          _buildStatusChip(isOutdated),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _isShiftFull ? AppColors.success : _departmentColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isOutdated) {
    if (_isCancelled) {
      return _buildStatusButton(
        label: 'בוטלה',
        color: Colors.red.shade400,
        icon: PhosphorIconsRegular.xCircle,
      );
    }

    if (isOutdated) {
      return _buildStatusButton(
        label: _isAssigned ? 'עבדת' : 'הסתיים',
        color: Colors.grey,
        icon: _isAssigned ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.clockCounterClockwise,
      );
    }

    if (_isAssigned) {
      return _buildStatusButton(
        label: 'משובץ',
        color: AppColors.success,
        icon: PhosphorIconsFill.checkCircle,
      );
    }

    if (_isShiftFull && !_hasRequested) {
      return _buildStatusButton(
        label: 'מלא',
        color: Colors.red.shade400,
        icon: PhosphorIconsRegular.prohibit,
      );
    }

    return Semantics(
      button: true,
      label: _hasRequested ? 'בטל בקשה למשמרת' : 'הצטרף למשמרת',
      child: Material(
        color: _hasRequested
            ? Colors.red.shade50
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isLoading ? null : _toggleShiftRequest,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _hasRequested ? Colors.red : AppColors.success,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _hasRequested ? 'ביטול' : 'הצטרף',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _hasRequested
                              ? Colors.red.shade600
                              : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _hasRequested ? PhosphorIconsRegular.x : PhosphorIconsRegular.plus,
                        size: 18,
                        color: _hasRequested
                            ? Colors.red.shade600
                            : AppColors.success,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isOutdated) {
    if (_isCancelled) {
      return _buildChip('המשמרת בוטלה', Colors.red.shade400, PhosphorIconsRegular.xCircle);
    }
    if (isOutdated) {
      return _buildChip('עבר התאריך', Colors.grey, PhosphorIconsRegular.clockCounterClockwise);
    }
    if (_isAssigned) {
      return _buildChip('אתה משובץ', AppColors.success, PhosphorIconsRegular.check);
    }
    if (_hasRequested) {
      return _buildChip('ממתין לאישור', AppColors.warningOrange, PhosphorIconsRegular.hourglassMedium);
    }
    if (_isShiftFull) {
      return _buildChip('המשמרת מלאה', Colors.red.shade400, PhosphorIconsRegular.prohibit);
    }
    return _buildChip('פתוח להרשמה', _departmentColor, PhosphorIconsRegular.calendarCheck);
  }

  Widget _buildChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHIFT DETAILS POPUP
// ═══════════════════════════════════════════════════════════

class ShiftDetailsPopup extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;
  final Color departmentColor;

  const ShiftDetailsPopup({
    super.key,
    required this.shift,
    required this.shiftService,
    required this.departmentColor,
  });

  @override
  State<ShiftDetailsPopup> createState() => _ShiftDetailsPopupState();
}

class _ShiftDetailsPopupState extends State<ShiftDetailsPopup> {
  static final Map<String, UserModel> _workerCache = {};

  late List<UserModel> assignedWorkers = [];
  bool isLoadingWorkers = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedWorkers();
  }

  Future<void> _fetchAssignedWorkers() async {
    final List<UserModel> cachedWorkers = [];
    final List<String> uncachedIds = [];

    for (final workerId in widget.shift.assignedWorkers) {
      if (_workerCache.containsKey(workerId)) {
        cachedWorkers.add(_workerCache[workerId]!);
      } else {
        uncachedIds.add(workerId);
      }
    }

    final List<UserModel> fetchedWorkers = [];
    if (uncachedIds.isNotEmpty) {
      final results = await Future.wait(
        uncachedIds.map((id) async {
          try {
            return await widget.shiftService.fetchWorkerDetails([id]);
          } catch (e) {
            debugPrint('Failed to fetch worker $id: $e');
            return <UserModel>[];
          }
        }),
      );
      // Evict oldest entries if cache would exceed 200 slots.
      const kCacheLimit = 200;
      final overflow = (_workerCache.length + uncachedIds.length) - kCacheLimit;
      if (overflow > 0) {
        final toRemove = _workerCache.keys.take(overflow).toList();
        for (final k in toRemove) {
          _workerCache.remove(k);
        }
      }
      for (int i = 0; i < uncachedIds.length; i++) {
        final fetched = results[i];
        if (fetched.isNotEmpty) {
          _workerCache[uncachedIds[i]] = fetched.first;
          fetchedWorkers.add(fetched.first);
        }
      }
    }

    if (mounted) {
      setState(() {
        assignedWorkers = [...cachedWorkers, ...fetchedWorkers];
        isLoadingWorkers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            color: Color(0xFFF8F9FB),
          ),
          child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.departmentColor,
                    widget.departmentColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsRegular.info,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shift.department,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.shift.date} | ${widget.shift.startTime} - ${widget.shift.endTime}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Workers section
                  _buildSectionTitle('עובדים משובצים', PhosphorIconsRegular.users),
                  const SizedBox(height: 12),
                  isLoadingWorkers
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: widget.departmentColor,
                            ),
                          ),
                        )
                      : assignedWorkers.isEmpty
                          ? _buildEmptyCard('אין עובדים משובצים עדיין')
                          : _buildWorkersGrid(),
                  const SizedBox(height: 24),
                  // Messages section
                  _buildSectionTitle('הודעות', PhosphorIconsRegular.chatCircle),
                  const SizedBox(height: 12),
                  _buildMessagesSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.departmentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: widget.departmentColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkersGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: assignedWorkers.map((worker) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.departmentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ProfileAvatar(
                  imageUrl: worker.profilePicture,
                  radius: 28,
                  backgroundColor: widget.departmentColor.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                worker.fullName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessagesSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.shiftsCollection)
          .doc(widget.shift.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyCard('טוען הודעות...');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final messages =
            List<Map<String, dynamic>>.from(data['messages'] ?? []);

        if (messages.isEmpty) {
          return _buildEmptyCard('אין הודעות עדיין');
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: messages.map((msg) {
              return MessageBubble(
                message: msg['message'],
                timestamp: msg['timestamp'],
                senderId: msg['senderId'],
                shiftId: widget.shift.id,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
