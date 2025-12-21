// Fichier: lib/features/support/presentation/pages/ticket_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/support_remote_datasource.dart';

class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  SupportRemoteDatasource? _datasource;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal50 = Color(0xFFE0F2F1);
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
    _datasource = SupportRemoteDatasource(
      client: http.Client(),
      sharedPreferences: prefs,
    );
    _loadTicket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    if (_datasource == null) return;

    try {
      final result = await _datasource!.getTicket(widget.ticketId);
      setState(() {
        _ticket = result['ticket'];
        _messages = result['messages'] ?? [];
        _isLoading = false;
      });
      _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_datasource == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final result = await _datasource!.sendMessage(
        ticketId: widget.ticketId,
        message: message,
      );

      setState(() {
        _messages.add(result['message']);
        _isSending = false;
      });
      _scrollToBottom();
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isSending = false);
      _messageController.text = message; // Restore message
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

  Future<void> _closeTicket() async {
    if (_datasource == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Fermer le ticket ?'),
        content: const Text('Cette action est irréversible. Le ticket sera marqué comme résolu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _datasource!.closeTicket(widget.ticketId);
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Ticket fermé'),
              ],
            ),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'ouvert':
        return Colors.blue;
      case 'en_cours':
        return Colors.orange;
      case 'resolu':
        return Colors.green;
      case 'ferme':
        return textSecondary;
      default:
        return textSecondary;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'ouvert':
        return 'Ouvert';
      case 'en_cours':
        return 'En cours';
      case 'resolu':
        return 'Résolu';
      case 'ferme':
        return 'Fermé';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statut = _ticket?['statut'] ?? '';
    final isClosed = statut == 'ferme' || statut == 'resolu';

    return Scaffold(
      backgroundColor: teal50,
      appBar: AppBar(
        backgroundColor: teal50,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: primaryTeal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ticket #${widget.ticketId}',
          style: const TextStyle(
            color: teal700,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isClosed)
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
                child: const Icon(Icons.check_circle_outline, color: primaryTeal, size: 18),
              ),
              onPressed: _closeTicket,
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
          : Column(
              children: [
                // Ticket info header
                if (_ticket != null) _buildTicketHeader(),

                // Messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),

                // Input field
                if (!isClosed) _buildInputField(),
              ],
            ),
    );
  }

  Widget _buildTicketHeader() {
    final sujet = _ticket!['sujet'] ?? '';
    final statut = _ticket!['statut'] ?? '';
    final categorie = _ticket!['categorie'] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sujet,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatutColor(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatutLabel(statut),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatutColor(statut),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                categorie.toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final content = message['message'] ?? '';
    final expediteur = message['expediteur'] ?? 'client';
    final createdAt = message['created_at'] ?? '';
    final isClient = expediteur == 'client';

    return Align(
      alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isClient ? primaryTeal : cardWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isClient ? 16 : 4),
            bottomRight: Radius.circular(isClient ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isClient) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.support_agent, size: 14, color: primaryTeal),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: isClient ? Colors.white : textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isClient ? Colors.white70 : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: teal50,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Votre message...',
                    hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryTeal, lightTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
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

      if (diff.inMinutes < 1) {
        return 'À l\'instant';
      } else if (diff.inMinutes < 60) {
        return 'Il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
