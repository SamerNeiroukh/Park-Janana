import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  Map<String, bool> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _notificationService.getNotificationPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת העדפות: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference(String category, bool enabled) async {
    try {
      await _notificationService.updateNotificationPreference(
        category: category,
        enabled: enabled,
      );
      
      setState(() {
        _preferences[category] = enabled;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'הפעלת התראות עבור $category' : 'כיבית התראות עבור $category'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בעדכון העדפות: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'הגדרות התראות',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
          : _buildSettingsList(),
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'אודות התראות',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'ניתן לבחור איזה סוגי התראות תרצה לקבל. ההתראות יעזרו לך להישאר מעודכן לגבי משמרות, משימות והודעות חדשות.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'סוגי התראות',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildNotificationTile(
                title: 'משמרות',
                subtitle: 'התראות על אישור/הסרה ממשמרות',
                icon: Icons.schedule,
                category: NotificationService.categoryShifts,
              ),
              const Divider(height: 1),
              _buildNotificationTile(
                title: 'משימות',
                subtitle: 'התראות על הקצאת משימות ועדכונים',
                icon: Icons.task,
                category: NotificationService.categoryTasks,
              ),
              const Divider(height: 1),
              _buildNotificationTile(
                title: 'הודעות והכרזות',
                subtitle: 'התראות על הודעות חדשות מההנהלה',
                icon: Icons.announcement,
                category: NotificationService.categoryAnnouncements,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.orange.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'טיפ חשוב',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'מומלץ להשאיר את כל ההתראות פעילות כדי לא לפספס עדכונים חשובים לגבי העבודה שלך.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String category,
  }) {
    final isEnabled = _preferences[category] ?? true;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isEnabled ? Colors.teal.shade100 : Colors.grey.shade200,
        child: Icon(
          icon,
          color: isEnabled ? Colors.teal : Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: Switch.adaptive(
        value: isEnabled,
        onChanged: (value) => _updatePreference(category, value),
        activeColor: Colors.teal,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}