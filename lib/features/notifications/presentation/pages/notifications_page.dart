// Fichier: lib/features/notifications/presentation/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/notification_remote_datasource.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _nonLues = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  NotificationRemoteDatasource? _datasource;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initDatasource();
  }

  Future<void> _initDatasource() async {
    final prefs = await SharedPreferences.getInstance();
    _datasource = NotificationRemoteDatasource(
      client: http.Client(),
      sharedPreferences: prefs,
    );
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_datasource == null) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    try {
      final result = await _datasource!.getNotifications(page: _currentPage);
      setState(() {
        _notifications = result['notifications'] ?? [];
        _nonLues = result['nonLues'] ?? 0;
        _totalPages = result['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _marquerCommeLue(int id, int index) async {
    if (_datasource == null) return;

    try {
      await _datasource!.marquerCommeLue(id);
      setState(() {
        _notifications[index]['lu'] = true;
        _nonLues = (_nonLues > 0) ? _nonLues - 1 : 0;
      });
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _marquerToutesLues() async {
    if (_datasource == null) return;

    try {
      await _datasource!.marquerToutesLues();
      HapticFeedback.lightImpact();
      setState(() {
        for (var notif in _notifications) {
          notif['lu'] = true;
        }
        _nonLues = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Toutes les notifications marquées comme lues'),
              ],
            ),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    if (_datasource == null) return;

    try {
      await _datasource!.deleteNotification(id);
      HapticFeedback.lightImpact();
      setState(() {
        if (!_notifications[index]['lu']) {
          _nonLues = (_nonLues > 0) ? _nonLues - 1 : 0;
        }
        _notifications.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'commande':
        return Icons.shopping_bag_outlined;
      case 'paiement':
        return Icons.payment;
      case 'reponse_pharmacie':
        return Icons.local_pharmacy_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'commande':
        return Colors.blue;
      case 'paiement':
        return Colors.green;
      case 'reponse_pharmacie':
        return primaryTeal;
      case 'promotion':
        return Colors.orange;
      default:
        return textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_nonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_nonLues',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (_nonLues > 0)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.done_all, color: primaryTeal, size: 18),
              ),
              onPressed: _marquerToutesLues,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(refresh: true),
                  color: primaryTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas de notifications pour le moment',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final titre = notification['titre'] ?? '';
    final message = notification['message'] ?? '';
    final type = notification['type'] ?? 'systeme';
    final lu = notification['lu'] ?? false;
    final createdAt = notification['created_at'] ?? '';
    final id = notification['id'];

    return Dismissible(
      key: Key('notif_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) => _deleteNotification(id, index),
      child: GestureDetector(
        onTap: () {
          if (!lu) {
            _marquerCommeLue(id, index);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: lu ? cardWhite : primaryTeal.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: lu ? null : Border.all(color: primaryTeal.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: lu ? FontWeight.w500 : FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (!lu)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: primaryTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary.withOpacity(0.7),
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return 'Il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
