import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/core/widgets/message_bubble.dart';
import 'package:park_janana/features/workers/screens/users_screen.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeroCard(),
                    const SizedBox(height: 24),
                    _buildTabBar(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.48,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsTab(),
                          _buildAssignedTab(),
                          _buildMessagesTab(),
                          _buildInfoTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroCard() {
    final assigned = widget.shift.assignedWorkers.length;
    final max = widget.shift.maxWorkers;
    final progress = max == 0 ? 0.0 : assigned / max;
    final requests = widget.shift.requestedWorkers.length;

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
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _departmentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_departmentIcon, size: 16, color: _departmentColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.shift.department,
                      style: TextStyle(
                        color: _departmentColor,
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
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.shift.formattedDateWithDay,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: Colors.grey.shade500),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${widget.shift.startTime} - ${widget.shift.endTime}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded,
                          size: 18, color: Colors.grey.shade500),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '$assigned / $max',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progress >= 1 ? AppColors.success : _departmentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                                    _departmentColor,
                                    _departmentColor.withOpacity(0.7)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'עובדים',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
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

  Widget _buildTabBar() {
    final tabs = [
      _TabItem(Icons.pending_actions_outlined, 'בקשות',
          widget.shift.requestedWorkers.length),
      _TabItem(
          Icons.group_outlined, 'מאושרים', widget.shift.assignedWorkers.length),
      _TabItem(Icons.chat_bubble_outline, 'הודעות', 0),
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
                      ? _departmentColor.withOpacity(0.1)
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
                              ? _departmentColor
                              : Colors.grey.shade500,
                        ),
                        if (tabs[i].badge > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.warningOrange,
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
                        color: isSelected
                            ? _departmentColor
                            : Colors.grey.shade600,
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

  Widget _buildRequestsTab() {
    return _buildWorkerList(
      workerIds: widget.shift.requestedWorkers,
      emptyIcon: Icons.hourglass_empty_rounded,
      emptyText: 'אין בקשות ממתינות',
      emptySubtext: 'בקשות חדשות יופיעו כאן',
      actionBuilder: (user) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFE53935),
            onTap: () =>
                widget.shiftService.rejectWorker(widget.shift.id, user.uid),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.check_rounded,
            color: AppColors.success,
            onTap: () =>
                widget.shiftService.approveWorker(widget.shift.id, user.uid),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ASSIGNED TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildAssignedTab() {
    final isFull =
        widget.shift.assignedWorkers.length >= widget.shift.maxWorkers;

    return Column(
      children: [
        // Add Workers Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Material(
            color: isFull
                ? Colors.grey.shade300
                : _departmentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isFull
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UsersScreen(
                            shiftId: widget.shift.id,
                            assignedWorkerIds: widget.shift.assignedWorkers,
                          ),
                        ),
                      ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFull ? 'המשמרת מלאה' : 'הוסף עובדים',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isFull ? Colors.grey.shade600 : _departmentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isFull ? Icons.check_circle : Icons.person_add_rounded,
                      size: 20,
                      color: isFull ? Colors.grey.shade600 : _departmentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Worker List
        Expanded(
          child: _buildWorkerListContent(
            workerIds: widget.shift.assignedWorkers,
            emptyIcon: Icons.group_off_outlined,
            emptyText: 'אין עובדים משובצים',
            emptySubtext: 'לחץ על "הוסף עובדים" להוספה ידנית',
            actionBuilder: (user) => _buildActionButton(
              icon: Icons.person_remove_rounded,
              color: const Color(0xFFE53935),
              onTap: () =>
                  widget.shiftService.removeWorker(widget.shift.id, user.uid),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerListContent({
    required List<String> workerIds,
    required IconData emptyIcon,
    required String emptyText,
    required String emptySubtext,
    required Widget Function(UserModel) actionBuilder,
  }) {
    if (workerIds.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyText, emptySubtext);
    }

    return FutureBuilder<List<UserModel>>(
      future: widget.shiftService.fetchWorkerDetails(workerIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: _departmentColor),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return _buildWorkerCard(user, actionBuilder(user));
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
    required Widget Function(UserModel) actionBuilder,
  }) {
    if (workerIds.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyText, emptySubtext);
    }

    return FutureBuilder<List<UserModel>>(
      future: widget.shiftService.fetchWorkerDetails(workerIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: _departmentColor),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return _buildWorkerCard(user, actionBuilder(user));
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(UserModel user, Widget actions) {
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
        children: [
          actions,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
          FutureBuilder<ImageProvider>(
            future: ProfileImageProvider.resolve(
              storagePath: user.profilePicturePath,
              fallbackUrl: user.profilePicture,
            ),
            builder: (_, snap) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _departmentColor.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _departmentColor.withOpacity(0.1),
                backgroundImage: snap.data,
                child: snap.data == null
                    ? Icon(Icons.person, color: _departmentColor)
                    : null,
              ),
            ),
          ),
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

  // ═══════════════════════════════════════════════════════════
  // MESSAGES TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildMessagesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.shiftService.getShiftsStream().map(
                  (shifts) => shifts
                      .firstWhere((s) => s.id == widget.shift.id)
                      .messages,
                ),
            builder: (context, snapshot) {
              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return _buildEmptyState(
                  Icons.chat_bubble_outline_rounded,
                  'אין הודעות עדיין',
                  'שלח הודעה ראשונה',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final msg = snapshot.data![index];
                  return MessageBubble(
                    message: msg['message'],
                    timestamp: msg['timestamp'],
                    senderId: msg['senderId'],
                    shiftId: widget.shift.id,
                  );
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
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
            color: _departmentColor,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                final text = _messageController.text.trim();
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (text.isEmpty || uid == null) return;
                widget.shiftService
                    .addMessageToShift(widget.shift.id, text, uid);
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

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildInfoCard(
          icon: Icons.flag_rounded,
          label: 'סטטוס',
          value: widget.shift.status == 'active' ? 'פעיל' : widget.shift.status,
          valueColor:
              widget.shift.status == 'active' ? AppColors.success : null,
        ),
        _buildInfoCard(
          icon: Icons.person_outline_rounded,
          label: 'נוצר על ידי',
          value: widget.shift.createdBy,
          isUserId: true,
        ),
        _buildInfoCard(
          icon: Icons.calendar_today_rounded,
          label: 'תאריך יצירה',
          value: widget.shift.createdAt == null
              ? '-'
              : DateFormat('dd/MM/yyyy בשעה HH:mm')
                  .format(widget.shift.createdAt!.toDate()),
        ),
        _buildInfoCard(
          icon: Icons.edit_outlined,
          label: 'עודכן לאחרונה על ידי',
          value: widget.shift.lastUpdatedBy,
          isUserId: true,
        ),
        if (widget.shift.shiftManager.isNotEmpty)
          _buildInfoCard(
            icon: Icons.admin_panel_settings_outlined,
            label: 'אחראי משמרת',
            value: widget.shift.shiftManager,
            isUserId: true,
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
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
        children: [
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
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _departmentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _departmentColor),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════

  Widget _buildEmptyState(IconData icon, String text, String subtext) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _departmentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 48, color: _departmentColor.withOpacity(0.6)),
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
