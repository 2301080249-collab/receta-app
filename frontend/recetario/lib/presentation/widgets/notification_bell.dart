import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/services/notification_service.dart';
import '../screens/shared/detalle_receta_screen.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({Key? key}) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _notificaciones = [];
  int _noLeidas = 0;
  bool _isLoading = false;
  Timer? _pollTimer;

  // 🎨 Color del tema
  static const Color primaryColor = Color(0xFF455A64);

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarNotificaciones() async {
    try {
      final notificaciones = await _notificationService.obtenerNotificaciones();
      if (!mounted) return;
      setState(() {
        _notificaciones = notificaciones;
        _noLeidas = notificaciones.where((n) => n['leida'] == false).length;
      });
    } catch (e) {
      print('Error cargando notificaciones: $e');
    }
  }

  Future<void> _marcarComoLeida(String notificacionId) async {
    try {
      await _notificationService.marcarComoLeida(notificacionId);
      await _cargarNotificaciones();
    } catch (e) {
      print('Error marcando como leída: $e');
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    try {
      setState(() => _isLoading = true);
      await _notificationService.marcarTodasComoLeidas();
      await _cargarNotificaciones();
    } catch (e) {
      print('Error marcando todas como leídas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarNotificaciones() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 24 : 40,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenWidth : 500,
            maxHeight: screenHeight * (isMobile ? 0.85 : 0.7),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.white, size: isMobile ? 20 : 24),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Notificaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_noLeidas > 0)
                      TextButton(
                        onPressed: _isLoading ? null : _marcarTodasComoLeidas,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 4 : 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isMobile ? 'Marcar' : 'Marcar todas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: isMobile ? 20 : 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Lista de notificaciones
              Expanded(
                child: _notificaciones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: isMobile ? 48 : 64, color: Colors.grey[400]),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'No hay notificaciones',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(isMobile ? 4 : 8),
                        itemCount: _notificaciones.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          final notif = _notificaciones[index];
                          return _buildNotificationItem(notif, isMobile);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif, bool isMobile) {
    final isLeida = notif['leida'] == true;
    final tipo = notif['tipo'] ?? '';
    final titulo = notif['titulo'] ?? 'Notificación';
    final mensaje = notif['mensaje'] ?? '';
    final createdAt = notif['created_at'] ?? '';
    final recetaId = notif['receta_id'];
    final notifId = notif['id'];

    // Parsear mensaje personalizado
    String? mensajePersonalizado;
    String mensajeDisplay = mensaje;
    
    if (mensaje.contains('": "') && mensaje.endsWith('"')) {
      final partes = mensaje.split('": "');
      if (partes.length == 2) {
        mensajeDisplay = partes[0];
        mensajePersonalizado = partes[1].substring(0, partes[1].length - 1);
      }
    }

    return InkWell(
      onTap: () async {
        if (!isLeida && notifId != null) {
          await _marcarComoLeida(notifId);
        }
        if (recetaId != null && mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleRecetaScreen(recetaId: recetaId),
            ),
          );
        }
      },
      child: Container(
        color: isLeida ? Colors.transparent : primaryColor.withOpacity(0.05),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: isMobile ? 10 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono según tipo
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: _getIconColor(tipo).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(tipo),
                color: _getIconColor(tipo),
                size: isMobile ? 18 : 24,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: isLeida ? FontWeight.normal : FontWeight.bold,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: isMobile ? 3 : 4),
                  Text(
                    mensajeDisplay,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: isMobile ? 12 : 13,
                    ),
                  ),
                  // Mensaje personalizado
                  if (mensajePersonalizado != null) ...[
                    SizedBox(height: isMobile ? 6 : 8),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.message, size: isMobile ? 14 : 16, color: primaryColor),
                          SizedBox(width: isMobile ? 6 : 8),
                          Expanded(
                            child: Text(
                              mensajePersonalizado,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: isMobile ? 12 : 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 3 : 4),
                  Text(
                    _formatearFecha(createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            // Indicador de no leída
            if (!isLeida)
              Container(
                width: isMobile ? 6 : 8,
                height: isMobile ? 6 : 8,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String tipo) {
    switch (tipo) {
      case 'receta_compartida':
        return Icons.share;
      case 'like':
        return Icons.favorite;
      case 'comentario':
        return Icons.comment;
      case 'evaluacion':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String tipo) {
    switch (tipo) {
      case 'receta_compartida':
        return primaryColor;
      case 'like':
        return Colors.red;
      case 'comentario':
        return Colors.blue;
      case 'evaluacion':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Justo ahora';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _mostrarNotificaciones,
        ),
        if (_noLeidas > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _noLeidas > 99 ? '99+' : _noLeidas.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}