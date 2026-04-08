import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService.instance;

  List<NotificationResponse> _notifications = const [];
  bool _loading = true;
  bool _markingAllRead = false;
  bool _requiresLogin = false;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _requiresLogin = true;
        _loading = false;
        _notifications = const [];
        _unreadCount = 0;
      });
      return;
    }

    try {
      final items = await _notificationService.getMyNotifications(size: 50);
      if (!mounted) return;
      var unreadCount = items.where((item) => !item.read).length;

      try {
        unreadCount = await _notificationService.getUnreadCount();
      } catch (_) {}
      if (!mounted) return;

      setState(() {
        _requiresLogin = false;
        _notifications = items;
        _unreadCount = unreadCount;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              e.message)
          : e.message;

      setState(() {
        _loading = false;
        _requiresLogin = statusCode == 401 || statusCode == 403;
        _error =
            _requiresLogin ? null : 'Khong tai duoc Thông báo: ${message ?? e}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Khong tai duoc Thông báo: $e';
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markingAllRead || _unreadCount == 0) return;
    setState(() => _markingAllRead = true);
    try {
      await _notificationService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _unreadCount = 0;
        _notifications = _notifications
            .map(
              (item) => NotificationResponse(
                notificationId: item.notificationId,
                title: item.title,
                body: item.body,
                type: item.type,
                read: true,
                createdAt: item.createdAt,
              ),
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da danh dau tat ca la da doc'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              e.message)
          : e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong cap nhat duoc Thông báo: ${message ?? e}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong cap nhat duoc Thông báo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _markingAllRead = false);
      }
    }
  }

  Future<void> _openNotification(NotificationResponse notification) async {
    var current = notification;
    try {
      current = await _notificationService.getById(notification.notificationId);
    } catch (_) {}

    if (!notification.read) {
      try {
        await _notificationService.markAsRead(notification.notificationId);
        if (!mounted) return;
        current = NotificationResponse(
          notificationId: notification.notificationId,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          read: true,
          createdAt: notification.createdAt,
        );
        setState(() {
          _notifications = _notifications
              .map(
                (item) => item.notificationId == notification.notificationId
                    ? current
                    : item,
              )
              .toList();
          _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        });
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _NotificationTypeAvatar(type: current.type, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(current.createdAt),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                current.body.isEmpty
                    ? 'Thông báo khong co noi dung.'
                    : current.body,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Dong'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'Khong ro thoi gian';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('HH:mm • dd/MM/yyyy').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title:
            Text(_unreadCount > 0 ? 'Thông báo ($_unreadCount)' : 'Thông báo'),
        actions: [
          if (!_requiresLogin)
            TextButton.icon(
              onPressed:
                  _unreadCount == 0 || _markingAllRead ? null : _markAllAsRead,
              icon: _markingAllRead
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all, size: 18),
              label: const Text('Doc het'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadNotifications(showLoader: false),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_requiresLogin) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.notifications_off_outlined,
            size: 52,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ban can dang nhap de xem Thông báo tu backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton(
              onPressed: () => context.go(AppRoutes.login),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Dang nhap'),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, size: 52, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Tai lai'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white12),
              ),
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(
            Icons.notifications_none_outlined,
            size: 52,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'Chua co Thông báo moi',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _notifications.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _unreadCount > 0
                        ? 'Ban con $_unreadCount Thông báo chua doc.'
                        : 'Tat ca Thông báo da duoc doc.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final item = _notifications[index - 1];
        return _NotificationCard(
          notification: item,
          onTap: () => _openNotification(item),
          timestamp: _formatDateTime(item.createdAt),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationResponse notification;
  final String timestamp;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : Colors.white10,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationTypeAvatar(type: notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (unread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body.isEmpty
                          ? 'Thông báo khong co noi dung.'
                          : notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          unread ? 'Moi' : 'Da doc',
                          style: TextStyle(
                            color: unread
                                ? AppColors.primaryLight
                                : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTypeAvatar extends StatelessWidget {
  final NotificationType? type;
  final double size;

  const _NotificationTypeAvatar({
    required this.type,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.48),
    );
  }

  static _NotificationTypeStyle _styleFor(NotificationType? type) {
    switch (type) {
      case NotificationType.BOOKING:
        return const _NotificationTypeStyle(
            Icons.confirmation_num_outlined, AppColors.secondary);
      case NotificationType.PAYMENT:
        return const _NotificationTypeStyle(
            Icons.payments_outlined, AppColors.success);
      case NotificationType.REMINDER:
        return const _NotificationTypeStyle(
            Icons.alarm_outlined, AppColors.info);
      case NotificationType.PROMOTION:
        return const _NotificationTypeStyle(
            Icons.local_offer_outlined, AppColors.primaryLight);
      case NotificationType.CANCELLATION:
        return const _NotificationTypeStyle(
            Icons.event_busy_outlined, AppColors.error);
      case NotificationType.REVIEW:
        return const _NotificationTypeStyle(
            Icons.rate_review_outlined, AppColors.secondary);
      case NotificationType.SYSTEM:
      default:
        return const _NotificationTypeStyle(
            Icons.notifications_outlined, Colors.white70);
    }
  }
}

class _NotificationTypeStyle {
  final IconData icon;
  final Color color;

  const _NotificationTypeStyle(this.icon, this.color);
}
