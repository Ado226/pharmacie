// Fichier: lib/views/notifications_view.dart
// Page d'affichage des notifications

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import 'pharmacy_responses_list_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final notifications = await NotificationService.getNotifications(
      page: 1,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _currentPage = 1;
        _hasMore = notifications.length >= 20;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    final notifications = await NotificationService.getNotifications(
      page: _currentPage + 1,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        _notifications.addAll(notifications);
        _currentPage++;
        _isLoading = false;
        _hasMore = notifications.length >= 20;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    if (success) {
      setState(() {
        for (var notif in _notifications) {
          notif['lu'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont ete marquees comme lues'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    final success = await NotificationService.deleteNotification(id);
    if (success && mounted) {
      setState(() {
        _notifications.removeAt(index);
      });
    }
  }

  void _onNotificationTap(Map<String, dynamic> notification) async {
    // Marquer comme lue
    final id = notification['id'];
    if (id != null && notification['lu'] != true) {
      await NotificationService.markAsRead(id);
      setState(() {
        notification['lu'] = true;
      });
    }

    // Naviguer selon le type
    final type = notification['type'] ?? '';
    final data = notification['data'];

    if (type == 'reponse_pharmacie' || type == 'commande') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PharmacyResponsesListView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: const Color(0xFF0D9488),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.teal[700],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          if (_notifications.any((n) => n['lu'] != true))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tout lire',
                style: TextStyle(color: Color(0xFF0D9488)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFF0D9488),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez notifie des reponses des pharmacies',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
          );
        }

        final notification = _notifications[index];
        return _buildNotificationItem(notification, index);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    final isRead = notification['lu'] == true;
    final type = notification['type'] ?? 'systeme';
    final createdAt = notification['created_at'];

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'reponse_pharmacie':
        icon = Icons.local_pharmacy;
        iconColor = const Color(0xFF0D9488);
        break;
      case 'commande':
        icon = Icons.shopping_bag;
        iconColor = Colors.blue;
        break;
      case 'paiement':
        icon = Icons.payment;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key('notification_${notification['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id'], index);
      },
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFE0F7F5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icone
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['titre'] ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D9488),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
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

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'A l\'instant';
      } else if (diff.inMinutes < 60) {
        return 'Il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}
