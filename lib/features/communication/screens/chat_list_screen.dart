import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/services/communication_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/storage_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<ApiResponse<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = CommunicationService.listChats();
  }

  Future<void> _reload() async {
    setState(() {
      _future = CommunicationService.listChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/parent/dashboard');
            }
          },
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<ApiResponse<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final resp = snapshot.data!;
          print(
            '📋 Chat list API response: success=${resp.success}, dataType=${resp.data?.runtimeType}',
          );
          if (!resp.success) {
            print('❌ Chat list error: ${resp.error}');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(resp.error ?? 'Failed to load'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final data = resp.data;
          // Support both list and object with results
          final List chats;
          if (data is List) {
            chats = data;
          } else if (data is Map<String, dynamic>) {
            // Try multiple possible keys for the list
            if (data['results'] is List) {
              chats = data['results'] as List;
            } else if (data['data'] is List) {
              chats = data['data'] as List;
            } else if (data['chats'] is List) {
              chats = data['chats'] as List;
            } else {
              // Fallback: find first List value in map
              final firstList = data.values.firstWhere(
                (v) => v is List,
                orElse: () => const [],
              );
              chats = firstList is List ? firstList : [];
              print(
                '⚠️ Chat list: Using fallback list extraction. Keys: ${data.keys}',
              );
            }
          } else {
            print('⚠️ Chat list: Unexpected data type: ${data.runtimeType}');
            chats = [];
          }
          print('📋 Chat list loaded: ${chats.length} chats');
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No chats yet'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final chat = chats[index] as Map<String, dynamic>;
                final other =
                    chat['other_participant'] as Map<String, dynamic>?;
                final title = other != null
                    ? (other['display_name'] ??
                          other['full_name'] ??
                          other['name'] ??
                          'Chat')
                    : 'Chat';
                final subtitle =
                    (chat['latest_message_preview'] ?? '') as String?;
                // Detect latest image message for thumbnail preview
                bool latestIsImage = false;
                String latestImageUrl = '';
                final dynamic latestMsg = chat['latest_message'];
                final String latestType = (chat['latest_message_type'] ?? '')
                    .toString();
                if (latestMsg is Map<String, dynamic>) {
                  final String msgType =
                      (latestMsg['message_type'] ?? latestType).toString();
                  latestIsImage = msgType == 'image';
                  if (latestIsImage) {
                    // Resolve attachment URL
                    final dynamic rawAttachment = latestMsg['attachment'];
                    String resolved = (latestMsg['attachment_url'] ?? '')
                        .toString();
                    if (resolved.isEmpty) {
                      if (rawAttachment is Map<String, dynamic>) {
                        final String fromUrl = (rawAttachment['url'] ?? '')
                            .toString();
                        final String fromFile = (rawAttachment['file'] ?? '')
                            .toString();
                        final String fromPath = (rawAttachment['path'] ?? '')
                            .toString();
                        resolved = fromUrl.isNotEmpty
                            ? fromUrl
                            : (fromFile.isNotEmpty ? fromFile : fromPath);
                      } else if (rawAttachment != null) {
                        resolved = rawAttachment.toString();
                      }
                    }
                    if (resolved.isNotEmpty &&
                        resolved.startsWith('/') &&
                        !resolved.startsWith('http')) {
                      resolved = ApiEndpoints.baseUrl + resolved;
                    }
                    latestImageUrl = resolved;
                  }
                } else if (latestType == 'image') {
                  latestIsImage = true;
                }
                final unread = (chat['unread_count'] ?? 0) as int;
                final time = (chat['last_message_time'] ?? '') as String?;
                final chatId = chat['id'] as int?;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: chatId == null
                        ? null
                        : () async {
                            if (!mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatDetailScreen(chatId: chatId),
                              ),
                            );
                            if (!mounted) return;
                            _reload();
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE2E8F0),
                                child: Text(
                                  title.isNotEmpty
                                      ? title[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      unread > 99 ? '99+' : unread.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (time != null && time.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (_) {
                                    if (latestIsImage &&
                                        latestImageUrl.isNotEmpty) {
                                      final token =
                                          StorageService.getAuthToken();
                                      final headers = <String, String>{};
                                      if (token != null && token.isNotEmpty) {
                                        headers['Authorization'] =
                                            'Bearer $token';
                                      }
                                      return Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.network(
                                              latestImageUrl,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              headers: headers.isEmpty
                                                  ? null
                                                  : headers,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stack,
                                                  ) => Container(
                                                    width: 36,
                                                    height: 36,
                                                    color: const Color(
                                                      0xFFE2E8F0,
                                                    ),
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 18,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.photo,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Photo',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return Text(
                                      subtitle ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF475569),
                                        height: 1.2,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF3B82F6),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final int chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, dynamic>? _chat;
  List<dynamic> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final details = await CommunicationService.getChatDetails(
      chatId: widget.chatId,
    );
    final msgs = await CommunicationService.getChatMessages(
      chatId: widget.chatId,
    );
    if (!mounted) return;
    if (!details.success) {
      setState(() {
        _loading = false;
        _error = details.error ?? 'Failed to load chat';
      });
      return;
    }
    final List<dynamic> messagesList;
    if (msgs.success) {
      final d = msgs.data;
      if (d is List) {
        messagesList = d;
      } else if (d is Map<String, dynamic>) {
        final resultsDynamic = d['results'];
        messagesList = resultsDynamic is List ? resultsDynamic : const [];
      } else {
        messagesList = const [];
      }
    } else {
      messagesList = const [];
    }
    setState(() {
      final dataMap = details.data;
      if (dataMap is Map<String, dynamic>) {
        _chat = dataMap;
      } else {
        _chat = null;
      }
      _messages = messagesList;
      _loading = false;
    });
    // mark as read best-effort
    CommunicationService.markChatAsRead(chatId: widget.chatId);
    await Future.delayed(const Duration(milliseconds: 150));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final resp = await CommunicationService.sendTextMessage(
      chatId: widget.chatId,
      content: text,
    );
    if (resp.success) {
      await _load();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to send')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;
      // Optimistic local preview message
      final optimisticMsg = <String, dynamic>{
        'message_type': 'image',
        'content': 'Image',
        'attachment': file.path,
        'local': true,
        'sender': (_chat?['current_user'] as Map<String, dynamic>?) ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };
      setState(() {
        _messages = List<dynamic>.from(_messages)..add(optimisticMsg);
      });
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
      final resp = await CommunicationService.sendImageMessage(
        chatId: widget.chatId,
        content: 'Image',
        attachment: file.path,
      );
      if (resp.success) {
        // Try to replace local preview only when a valid remote URL is ready
        final replaced = await _tryReplaceWithRemoteOnce();
        if (!replaced && mounted) {
          // Retry after a brief delay to give backend time to process
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            final replacedAgain = await _tryReplaceWithRemoteOnce();
            if (!replacedAgain) {
              // Keep local preview; optional toast to inform user
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Image is processing. It will appear when ready.',
                    ),
                  ),
                );
              }
            }
          }
        }
      } else if (mounted) {
        // Remove optimistic message if send failed
        setState(() {
          _messages.remove(optimisticMsg);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.error ?? 'Failed to send image')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image error: $e')));
    }
  }

  Future<bool> _tryReplaceWithRemoteOnce() async {
    try {
      final msgs = await CommunicationService.getChatMessages(
        chatId: widget.chatId,
      );
      if (!msgs.success) return false;
      final data = msgs.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        final resultsDynamic = data['results'];
        list = resultsDynamic is List ? resultsDynamic : const [];
      } else {
        return false;
      }

      final currentUserId =
          (_chat?['current_user'] as Map<String, dynamic>?)?['id'];
      Map<String, dynamic>? latestOwnImage;
      for (int i = list.length - 1; i >= 0; i--) {
        final m = list[i];
        if (m is Map<String, dynamic>) {
          final type = (m['message_type'] ?? 'text').toString();
          final senderId = (m['sender'] as Map<String, dynamic>?)?['id'];
          if (type == 'image' && senderId == currentUserId) {
            latestOwnImage = m;
            break;
          }
        }
      }
      if (latestOwnImage == null) return false;

      // Resolve URL similar to renderer
      String attachmentUrl = '';
      final dynamic rawAttachment = latestOwnImage['attachment'];
      final String attachmentUrlField = (latestOwnImage['attachment_url'] ?? '')
          .toString();
      if (attachmentUrlField.isNotEmpty) {
        attachmentUrl = attachmentUrlField;
      } else if (rawAttachment is Map<String, dynamic>) {
        final String fromUrl = (rawAttachment['url'] ?? '').toString();
        final String fromFile = (rawAttachment['file'] ?? '').toString();
        final String fromPath = (rawAttachment['path'] ?? '').toString();
        final String candidate = fromUrl.isNotEmpty
            ? fromUrl
            : (fromFile.isNotEmpty ? fromFile : fromPath);
        if (candidate.isNotEmpty) {
          attachmentUrl = candidate;
        }
      } else {
        final String attachmentStr = (rawAttachment ?? '').toString();
        if (attachmentStr.isNotEmpty) {
          attachmentUrl = attachmentStr;
        }
      }
      if (attachmentUrl.isEmpty) return false;
      if (attachmentUrl.startsWith('/') && !attachmentUrl.startsWith('http')) {
        attachmentUrl = ApiEndpoints.baseUrl + attachmentUrl;
      }

      // HEAD check to ensure the remote image is available
      final token = StorageService.getAuthToken();
      final resp = await http.head(
        Uri.parse(attachmentUrl),
        headers: token != null && token.isNotEmpty
            ? {'Authorization': 'Bearer $token'}
            : null,
      );
      if (resp.statusCode == 200) {
        await _load();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _chat != null
        ? (((_chat!['other_participant']
                  as Map<String, dynamic>?)?['display_name']) ??
              ((_chat!['other_participant']
                  as Map<String, dynamic>?)?['full_name']) ??
              ((_chat!['other_participant']
                  as Map<String, dynamic>?)?['name']) ??
              'Chat')
        : 'Chat';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () async {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          title.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('No messages yet'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg =
                                _messages[index] as Map<String, dynamic>;
                            final content = (msg['content'] ?? '').toString();
                            final messageType = (msg['message_type'] ?? 'text')
                                .toString();
                            // Resolve attachment URL from multiple possible shapes
                            String attachmentUrl = '';
                            final dynamic rawAttachment = msg['attachment'];
                            final String attachmentUrlField =
                                (msg['attachment_url'] ?? '').toString();
                            if (attachmentUrlField.isNotEmpty) {
                              attachmentUrl = attachmentUrlField;
                            } else if (rawAttachment is Map<String, dynamic>) {
                              final String fromUrl =
                                  (rawAttachment['url'] ?? '').toString();
                              final String fromFile =
                                  (rawAttachment['file'] ?? '').toString();
                              final String fromPath =
                                  (rawAttachment['path'] ?? '').toString();
                              final String candidate = fromUrl.isNotEmpty
                                  ? fromUrl
                                  : (fromFile.isNotEmpty ? fromFile : fromPath);
                              if (candidate.isNotEmpty) {
                                attachmentUrl = candidate;
                              }
                            } else {
                              final String attachmentStr = (rawAttachment ?? '')
                                  .toString();
                              if (attachmentStr.isNotEmpty) {
                                attachmentUrl = attachmentStr;
                              }
                            }
                            // Normalize to absolute URL when only a path is returned
                            if (attachmentUrl.isNotEmpty &&
                                attachmentUrl.startsWith('/') &&
                                !attachmentUrl.startsWith('http')) {
                              attachmentUrl =
                                  ApiEndpoints.baseUrl + attachmentUrl;
                            }
                            final isMine =
                                (msg['sender']
                                    as Map<String, dynamic>?)?['id'] ==
                                ((_chat?['current_user']
                                    as Map<String, dynamic>?)?['id']);
                            final bool isLocalImage =
                                messageType == 'image' &&
                                (msg['local'] == true) &&
                                ((msg['attachment']?.toString().isNotEmpty) ??
                                    false);
                            final bool isRemoteImage =
                                messageType == 'image' &&
                                attachmentUrl.isNotEmpty;
                            final bubbleColor = isMine
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFFF1F5F9);
                            final textColor = isMine
                                ? Colors.white
                                : Colors.black87;
                            final sender =
                                (msg['sender'] as Map<String, dynamic>?) ?? {};
                            final senderName =
                                (sender['display_name'] ??
                                        sender['full_name'] ??
                                        ((sender['first_name'] != null ||
                                                sender['last_name'] != null)
                                            ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'
                                                  .trim()
                                            : null) ??
                                        'User')
                                    .toString();
                            final createdAt =
                                (msg['created_at'] ?? msg['updated_at'])
                                    ?.toString();
                            String timeLabel = '';
                            if (createdAt != null) {
                              final parsed = DateTime.tryParse(createdAt);
                              if (parsed != null) {
                                final tod = TimeOfDay.fromDateTime(
                                  parsed.toLocal(),
                                );
                                timeLabel = tod.format(context);
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: isMine
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isMine) ...[
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      child: Text(
                                        senderName.isNotEmpty
                                            ? senderName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMine
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          if (!isMine)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4,
                                                bottom: 2,
                                              ),
                                              child: Text(
                                                senderName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bubbleColor,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(
                                                  16,
                                                ),
                                                topRight: const Radius.circular(
                                                  16,
                                                ),
                                                bottomLeft: Radius.circular(
                                                  isMine ? 16 : 4,
                                                ),
                                                bottomRight: Radius.circular(
                                                  isMine ? 4 : 16,
                                                ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.03),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: isMine
                                                  ? null
                                                  : Border.all(
                                                      color: const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                    ),
                                            ),
                                            child: isLocalImage
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                                maxHeight: 240,
                                                                minHeight: 100,
                                                              ),
                                                          child: Image.file(
                                                            File(
                                                              (msg['attachment'])
                                                                  .toString(),
                                                            ),
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                          ),
                                                        ),
                                                      ),
                                                      if (content.isNotEmpty &&
                                                          content.toLowerCase() !=
                                                              'image')
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                              ),
                                                          child: Text(
                                                            content,
                                                            style: TextStyle(
                                                              color: textColor,
                                                              fontSize: 16,
                                                              height: 1.3,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  )
                                                : isRemoteImage
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                                maxHeight: 240,
                                                                minHeight: 100,
                                                              ),
                                                          child: Builder(
                                                            builder: (_) {
                                                              final token =
                                                                  StorageService.getAuthToken();
                                                              final headers =
                                                                  <
                                                                    String,
                                                                    String
                                                                  >{};
                                                              if (token !=
                                                                      null &&
                                                                  token
                                                                      .isNotEmpty) {
                                                                headers['Authorization'] =
                                                                    'Bearer $token';
                                                              }
                                                              return Image.network(
                                                                attachmentUrl,
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: double
                                                                    .infinity,
                                                                headers:
                                                                    headers
                                                                        .isEmpty
                                                                    ? null
                                                                    : headers,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stack,
                                                                    ) {
                                                                      return Container(
                                                                        color: Colors
                                                                            .black12,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child: Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: const [
                                                                            Icon(
                                                                              Icons.broken_image_outlined,
                                                                              size: 40,
                                                                              color: Colors.grey,
                                                                            ),
                                                                            SizedBox(
                                                                              height: 6,
                                                                            ),
                                                                            Text(
                                                                              'Image unavailable',
                                                                              style: TextStyle(
                                                                                color: Colors.grey,
                                                                                fontSize: 12,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      if (content.isNotEmpty &&
                                                          content.toLowerCase() !=
                                                              'image')
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                              ),
                                                          child: Text(
                                                            content,
                                                            style: TextStyle(
                                                              color: textColor,
                                                              fontSize: 16,
                                                              height: 1.3,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  )
                                                : Text(
                                                    content,
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 16,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                          ),
                                          if (timeLabel.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                                left: 6,
                                                right: 6,
                                              ),
                                              child: Text(
                                                timeLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMine) const SizedBox(width: 6),
                                  if (isMine)
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFDBEAFE),
                                      child: Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Emoji',
                                  icon: const Icon(
                                    Icons.emoji_emotions_outlined,
                                    color: Color(0xFF64748B),
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  tooltip: 'Add image',
                                  icon: const Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF64748B),
                                  ),
                                  onPressed: _pickImage,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    minLines: 1,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      hintText: 'Type a message',
                                      border: InputBorder.none,
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _send(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            radius: 24,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _send,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
