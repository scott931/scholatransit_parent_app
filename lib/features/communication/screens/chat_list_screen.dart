import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allChats = [];
  List<dynamic> _filteredChats = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _future = CommunicationService.listChats();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredChats = _allChats;
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredChats = _allChats.where((chat) {
          final other = (chat['other_participant'] as Map<String, dynamic>?);
          final name =
              (other?['display_name'] ??
                      other?['full_name'] ??
                      other?['name'] ??
                      'Chat')
                  .toString()
                  .toLowerCase();
          final preview = (chat['latest_message_preview'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(query) || preview.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = CommunicationService.listChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Search Bar
            _buildSearchBar(),
            // Chat List
            Expanded(
              child: FutureBuilder<ApiResponse<dynamic>>(
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
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
                  if (!resp.success) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 48,
                            color: Colors.grey,
                          ),
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
                  List chats = [];
                  if (data is List) {
                    chats = data;
                  } else if (data is Map<String, dynamic>) {
                    if (data['results'] is List) {
                      chats = data['results'] as List;
                    } else if (data['data'] is List) {
                      chats = data['data'] as List;
                    } else if (data['chats'] is List) {
                      chats = data['chats'] as List;
                    }
                  }

                  if (_allChats.isEmpty && chats.isNotEmpty) {
                    _allChats = chats;
                    _filteredChats = chats;
                  }

                  if (_isSearching) {
                    return _buildChatList(_filteredChats);
                  }

                  // Separate pinned and unpinned
                  final pinned = _filteredChats
                      .where((c) => (c['is_pinned'] == true))
                      .toList();
                  final unpinned = _filteredChats
                      .where((c) => (c['is_pinned'] != true))
                      .toList();

                  return _buildChatListWithSections(pinned, unpinned);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              context.go('/parent/dashboard');
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Chat',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87),
        decoration: const InputDecoration(
          hintText: 'Search chat...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildChatListWithSections(List pinned, List unpinned) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionHeader('PINNED MESSAGE'),
          ...pinned.map((chat) => _buildChatItem(chat)),
        ],
        if (unpinned.isNotEmpty) ...[
          _buildSectionHeader('ALL MESSAGE'),
          ...unpinned.map((chat) => _buildChatItem(chat)),
        ],
        if (pinned.isEmpty && unpinned.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No chats yet'),
            ),
          ),
      ],
    );
  }

  Widget _buildChatList(List chats) {
    if (chats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No chats found'),
        ),
      );
    }
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) => _buildChatItem(chats[index]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final other = chat['other_participant'] as Map<String, dynamic>?;
    final name =
        (other?['display_name'] ??
                other?['full_name'] ??
                other?['name'] ??
                'Chat')
            .toString();
    final preview = (chat['latest_message_preview'] ?? '').toString();
    final unread = (chat['unread_count'] ?? 0) as int;
    final time = _formatTime(chat['last_message_time'] ?? '');
    final chatId = chat['id'] as int?;

    // Get avatar
    String? avatarUrl;
    if (other != null) {
      avatarUrl = (other['avatar'] ?? other['profile_picture'] ?? '')
          .toString();
      if (avatarUrl.isEmpty) {
        avatarUrl = null;
      } else if (avatarUrl.startsWith('/') && !avatarUrl.startsWith('http')) {
        avatarUrl = ApiEndpoints.baseUrl + avatarUrl;
      }
    }

    return InkWell(
      onTap: chatId == null
          ? null
          : () async {
              if (!mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(chatId: chatId),
                ),
              );
              if (mounted) _reload();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(avatarUrl, name),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview.isNotEmpty ? preview : 'No messages yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: preview.isNotEmpty
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (preview.isNotEmpty)
                        const Icon(
                          Icons.done_all,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    // List of vibrant, popping colors
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
    ];

    // Generate a consistent color based on the name
    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final avatarColor = _getAvatarColor(name);
    return CircleAvatar(
      radius: 28,
      backgroundColor: avatarColor,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt.toLocal());

      if (diff.inDays == 0) {
        // Today - show time
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (e) {
      return '';
    }
  }
}

// Keep the ChatDetailScreen from the original file
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
  final Record _audioRecorder = Record();
  Map<String, dynamic>? _chat;
  List<dynamic> _messages = [];
  bool _loading = true;
  String? _error;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _recordedFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  // Map to store local file paths for recently sent voice messages (key: message timestamp or content hash)
  final Map<String, String> _localVoiceFiles = {};

  @override
  void initState() {
    super.initState();
    _setupAudioPlayerListeners();
    _load();
  }

  void _setupAudioPlayerListeners() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _isPlaying = false;
            _audioPosition = Duration.zero;
            _currentlyPlayingUrl = null;
          }
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Color _getAvatarColor(String name) {
    // List of vibrant, popping colors
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
    ];

    // Generate a consistent color based on the name
    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
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
    // Merge server messages with local file information for recently sent voice messages
    final mergedMessages = await _mergeMessagesWithLocalFiles(messagesList);

    if (!mounted) return;
    setState(() {
      final dataMap = details.data;
      if (dataMap is Map<String, dynamic>) {
        _chat = dataMap;
      } else {
        _chat = null;
      }
      _messages = mergedMessages;
      _loading = false;
    });
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
      // Refresh in background without showing loading
      _loadSilently();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to send')));
    }
  }

  Future<List<dynamic>> _mergeMessagesWithLocalFiles(
    List<dynamic> serverMessages,
  ) async {
    // Try to match server messages with local files
    final merged = <dynamic>[];
    final now = DateTime.now();

    for (final serverMsg in serverMessages) {
      if (serverMsg is! Map<String, dynamic>) {
        merged.add(serverMsg);
        continue;
      }

      final messageType =
          (serverMsg['message_type'] ?? serverMsg['messageType'] ?? 'text')
              .toString()
              .toLowerCase();

      // If it's a voice message from the current user, try to find matching local file
      if (messageType == 'voice') {
        // Get current user ID
        dynamic currentUserId;
        if (_chat?['current_user'] is Map<String, dynamic>) {
          currentUserId =
              (_chat!['current_user'] as Map<String, dynamic>)['id'];
        }
        if (currentUserId == null) {
          final userProfile = StorageService.getUserProfile();
          if (userProfile != null && userProfile['id'] != null) {
            currentUserId = userProfile['id'];
          }
        }

        // Check if message is from current user
        dynamic senderId;
        if (serverMsg['sender'] is Map<String, dynamic>) {
          senderId = (serverMsg['sender'] as Map<String, dynamic>)['id'];
        }

        bool isMine = false;
        if (senderId != null && currentUserId != null) {
          isMine = senderId.toString() == currentUserId.toString();
        }

        if (isMine) {
          // Try to match by timestamp (within 5 minutes for recently sent messages)
          final createdAt = serverMsg['created_at']?.toString();
          if (createdAt != null) {
            try {
              final createdTime = DateTime.parse(createdAt);
              final timeDiff = now.difference(createdTime);
              if (timeDiff.inMinutes < 5) {
                // First try: Find matching local file from stored map
                bool foundLocalFile = false;
                for (final entry in _localVoiceFiles.entries) {
                  final file = File(entry.value);
                  if (file.existsSync()) {
                    // Add local file info to the message
                    final enhancedMsg = Map<String, dynamic>.from(serverMsg);
                    enhancedMsg['local_file_key'] = entry.key;
                    enhancedMsg['local_attachment'] = entry.value;
                    merged.add(enhancedMsg);
                    foundLocalFile = true;
                    print(
                      '✅ Merged local file with server message: ${entry.value}',
                    );
                    break;
                  }
                }

                // Second try: Check if attachment field contains a local file path that still exists
                if (!foundLocalFile) {
                  final dynamic rawAttachment = serverMsg['attachment'];
                  if (rawAttachment != null) {
                    final String attachmentStr = rawAttachment.toString();
                    // Check if it looks like a local file path
                    if (attachmentStr.isNotEmpty &&
                        (attachmentStr.startsWith('/data/') ||
                            attachmentStr.startsWith('/storage/') ||
                            attachmentStr.contains('app_flutter'))) {
                      final file = File(attachmentStr);
                      if (file.existsSync()) {
                        final enhancedMsg = Map<String, dynamic>.from(
                          serverMsg,
                        );
                        enhancedMsg['local_attachment'] = attachmentStr;
                        merged.add(enhancedMsg);
                        foundLocalFile = true;
                        print(
                          '✅ Found existing local file in attachment: $attachmentStr',
                        );
                      }
                    }
                  }

                  // Third try: Check common voice file locations
                  if (!foundLocalFile) {
                    try {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final voiceFiles = directory
                          .listSync()
                          .where(
                            (f) =>
                                f.path.contains('voice_') &&
                                f.path.endsWith('.m4a'),
                          )
                          .where((f) => File(f.path).existsSync())
                          .toList();

                      // Sort by modification time (newest first) and check if created time matches
                      voiceFiles.sort((a, b) {
                        final aStat = File(a.path).statSync();
                        final bStat = File(b.path).statSync();
                        return bStat.modified.compareTo(aStat.modified);
                      });

                      // Check if any file was modified around the message creation time
                      for (final voiceFile in voiceFiles.take(5)) {
                        // Check last 5 voice files
                        final fileStat = File(voiceFile.path).statSync();
                        final fileModTime = fileStat.modified;
                        final timeDiffSeconds =
                            (createdTime.difference(fileModTime).inSeconds)
                                .abs();
                        // If file was modified within 30 seconds of message creation, it's likely the match
                        if (timeDiffSeconds < 30) {
                          final enhancedMsg = Map<String, dynamic>.from(
                            serverMsg,
                          );
                          enhancedMsg['local_attachment'] = voiceFile.path;
                          merged.add(enhancedMsg);
                          foundLocalFile = true;
                          print(
                            '✅ Matched voice file by timestamp: ${voiceFile.path}',
                          );
                          break;
                        }
                      }
                    } catch (e) {
                      // Ignore errors
                    }
                  }
                }

                // If local file found and added, skip adding original message
                if (foundLocalFile) {
                  continue;
                }
              }
            } catch (e) {
              // Ignore parse errors
            }
          }
        }
      }

      // If message wasn't already added (merged), add it as-is
      merged.add(serverMsg);
    }

    return merged;
  }

  Future<void> _loadSilently() async {
    final details = await CommunicationService.getChatDetails(
      chatId: widget.chatId,
    );
    final msgs = await CommunicationService.getChatMessages(
      chatId: widget.chatId,
    );
    if (!mounted) return;
    if (!details.success || !msgs.success) return;

    final List<dynamic> messagesList;
    final d = msgs.data;
    if (d is List) {
      messagesList = d;
    } else if (d is Map<String, dynamic>) {
      final resultsDynamic = d['results'];
      messagesList = resultsDynamic is List ? resultsDynamic : const [];
    } else {
      messagesList = const [];
    }

    if (mounted) {
      // Merge server messages with local file information for recently sent voice messages
      final mergedMessages = await _mergeMessagesWithLocalFiles(messagesList);

      if (!mounted) return;
      setState(() {
        final dataMap = details.data;
        if (dataMap is Map<String, dynamic>) {
          _chat = dataMap;
        }
        _messages = mergedMessages;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients && mounted) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check and request microphone permission
      var permission = await Permission.microphone.status;
      if (permission.isDenied) {
        permission = await Permission.microphone.request();
        if (permission.isDenied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required to record voice messages',
              ),
            ),
          );
          return;
        }
      }

      if (permission.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone permission is permanently denied. Please enable it in settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Also check with record package
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(path: filePath);

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
          _recordedFilePath = filePath;
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration = Duration(seconds: timer.tick);
            });
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
    }
  }

  Future<void> _stopRecording({bool showPreview = true}) async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (path != null && mounted) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });

        // Wait a bit for UI to update before showing dialog
        await Future.delayed(const Duration(milliseconds: 100));

        if (showPreview && _recordedFilePath != null && mounted) {
          await _showRecordingPreview();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
    }
  }

  Future<void> _showRecordingPreview() async {
    if (_recordedFilePath == null || !mounted) {
      print(
        '⚠️ Cannot show preview: _recordedFilePath=${_recordedFilePath}, mounted=$mounted',
      );
      return;
    }

    try {
      print('📱 Showing voice preview dialog for: $_recordedFilePath');
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _VoicePreviewDialog(
          recordedFilePath: _recordedFilePath!,
          recordingDuration: _recordingDuration,
          formatDuration: _formatDuration,
        ),
      );

      if (!mounted) return;

      if (confirmed == true && _recordedFilePath != null) {
        await _sendVoiceMessage();
      } else {
        // Canceled - delete the recording
        try {
          final file = File(_recordedFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting canceled recording: $e');
        }
        setState(() {
          _recordedFilePath = null;
          _recordingDuration = Duration.zero;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error showing preview dialog: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error showing preview: $e')));
      }
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordedFilePath == null) return;

    // Store local file path for this message (use timestamp as key)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _localVoiceFiles[timestamp] = _recordedFilePath!;

    // Add optimistic message
    final optimisticMsg = <String, dynamic>{
      'message_type': 'voice',
      'content': 'Voice message',
      'attachment': _recordedFilePath,
      'local': true,
      'local_file_key': timestamp, // Store key to find local file later
      'sender': (_chat?['current_user'] as Map<String, dynamic>?) ?? {},
      'created_at': DateTime.now().toIso8601String(),
      'duration': _recordingDuration.inSeconds,
    };

    setState(() {
      _messages = List<dynamic>.from(_messages)..add(optimisticMsg);
    });

    await Future.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }

    final resp = await CommunicationService.sendVoiceMessage(
      chatId: widget.chatId,
      content: 'Voice message',
      attachment: _recordedFilePath!,
    );

    if (resp.success) {
      // Refresh in background
      _loadSilently();
    } else if (mounted) {
      setState(() {
        _messages.remove(optimisticMsg);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.error ?? 'Failed to send voice message')),
      );
    }

    setState(() {
      _recordedFilePath = null;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildVoiceMessageBubble(
    Map<String, dynamic> msg,
    bool isMine,
    Color textColor,
    Color bubbleColor,
    bool isLocal,
    bool isRemote,
    String attachmentUrl,
  ) {
    String audioPath = '';
    bool isLocalFile = false;

    // If attachmentUrl is empty, try to extract it from the message
    if (attachmentUrl.isEmpty) {
      final String attachmentUrlField = (msg['attachment_url'] ?? '')
          .toString();
      if (attachmentUrlField.isNotEmpty) {
        attachmentUrl = attachmentUrlField;
      } else {
        final dynamic rawAttachment = msg['attachment'];
        if (rawAttachment is Map<String, dynamic>) {
          final String fromUrl = (rawAttachment['url'] ?? '').toString();
          final String fromFile = (rawAttachment['file'] ?? '').toString();
          final String fromPath = (rawAttachment['path'] ?? '').toString();
          attachmentUrl = fromUrl.isNotEmpty
              ? fromUrl
              : (fromFile.isNotEmpty ? fromFile : fromPath);
        } else if (rawAttachment != null) {
          attachmentUrl = rawAttachment.toString();
        }
      }
      // Normalize URL
      if (attachmentUrl.isNotEmpty &&
          attachmentUrl.startsWith('/') &&
          !attachmentUrl.startsWith('http')) {
        if (!attachmentUrl.startsWith('/data/') &&
            !attachmentUrl.startsWith('/storage/') &&
            !attachmentUrl.contains('app_flutter')) {
          attachmentUrl = ApiEndpoints.baseUrl + attachmentUrl;
        }
      }
    }

    // First, check if there's a stored local file path for this message (for recently sent messages)
    if (isMine) {
      // Check for local_attachment field first (from merged messages)
      final localAttachment = msg['local_attachment']?.toString();
      if (localAttachment != null && localAttachment.isNotEmpty) {
        final file = File(localAttachment);
        if (file.existsSync()) {
          audioPath = localAttachment;
          isLocalFile = true;
          print(
            '✅ Using local_attachment field for voice message: $localAttachment',
          );
        }
      }

      // Also check for local_file_key
      if (audioPath.isEmpty) {
        final localFileKey = msg['local_file_key']?.toString();
        if (localFileKey != null &&
            _localVoiceFiles.containsKey(localFileKey)) {
          final localPath = _localVoiceFiles[localFileKey]!;
          final file = File(localPath);
          if (file.existsSync()) {
            audioPath = localPath;
            isLocalFile = true;
            print('✅ Using stored local file for voice message: $localPath');
          }
        }
      }
    }

    // If no local file found, proceed with normal extraction
    // Try attachmentUrl first (most reliable for remote messages)
    if (audioPath.isEmpty && attachmentUrl.isNotEmpty) {
      audioPath = attachmentUrl;
      isLocalFile = false;
      print('✅ Using attachmentUrl for voice message: $attachmentUrl');
    }

    // Then try flags-based extraction
    if (audioPath.isEmpty) {
      if (isLocal) {
        audioPath = (msg['attachment'] ?? '').toString();
        isLocalFile = true;
      } else if (isRemote) {
        // If isRemote is true, try attachmentUrl first, then fall back to raw attachment
        if (attachmentUrl.isNotEmpty) {
          audioPath = attachmentUrl;
          isLocalFile = false;
        } else {
          // Try to extract from raw attachment
          final dynamic rawAttachment = msg['attachment'];
          if (rawAttachment != null) {
            final String attachmentStr = rawAttachment.toString();
            if (attachmentStr.isNotEmpty) {
              // Check if it's a URL or local path
              if (attachmentStr.startsWith('http') ||
                  attachmentStr.startsWith('/media/')) {
                audioPath =
                    attachmentStr.startsWith('/') &&
                        !attachmentStr.startsWith('http')
                    ? ApiEndpoints.baseUrl + attachmentStr
                    : attachmentStr;
                isLocalFile = false;
              } else if (!attachmentStr.startsWith('/data/') &&
                  !attachmentStr.startsWith('/storage/')) {
                // Not a local path, treat as URL
                audioPath =
                    attachmentStr.startsWith('/') &&
                        !attachmentStr.startsWith('http')
                    ? ApiEndpoints.baseUrl + attachmentStr
                    : attachmentStr;
                isLocalFile = false;
              }
            }
          }
        }
        if (audioPath.isNotEmpty) {
          print('✅ Using remote voice message URL: $audioPath');
        }
      }
    }

    // If still empty, try extraction (even if flags are false or both false)
    // This ensures voice messages always get a source
    if (audioPath.isEmpty) {
      // Try attachmentUrl first (should already be extracted)
      if (attachmentUrl.isNotEmpty) {
        audioPath = attachmentUrl;
        isLocalFile = false;
        print('✅ Using extracted attachment URL (fallback): $attachmentUrl');
      } else {
        // Fallback: try to extract attachment from message even if flags aren't set
        final dynamic rawAttachment = msg['attachment'];
        if (rawAttachment != null) {
          final String attachmentStr = rawAttachment.toString();
          if (attachmentStr.isNotEmpty) {
            // Check if it's a local file path
            bool looksLikeLocalFile =
                attachmentStr.startsWith('/data/') ||
                attachmentStr.startsWith('/storage/') ||
                attachmentStr.contains('app_flutter');

            // If it looks like a local file, verify it exists
            if (looksLikeLocalFile) {
              final file = File(attachmentStr);
              if (file.existsSync()) {
                audioPath = attachmentStr;
                isLocalFile = true;
                print('✅ Found local file path in attachment: $attachmentStr');
              } else {
                // File doesn't exist anymore, might have been uploaded
                // Try as URL
                audioPath =
                    attachmentStr.startsWith('/') &&
                        !attachmentStr.startsWith('http')
                    ? ApiEndpoints.baseUrl + attachmentStr
                    : attachmentStr;
                isLocalFile = false;
              }
            } else if (!attachmentStr.startsWith('http') &&
                !attachmentStr.startsWith('/media/')) {
              // Might be a local file path (not starting with http or /media/)
              // Verify file exists
              final file = File(attachmentStr);
              if (file.existsSync()) {
                audioPath = attachmentStr;
                isLocalFile = true;
                print('✅ Found local file path (verified): $attachmentStr');
              } else {
                // Not a local file, treat as URL
                audioPath =
                    attachmentStr.startsWith('/') &&
                        !attachmentStr.startsWith('http')
                    ? ApiEndpoints.baseUrl + attachmentStr
                    : attachmentStr;
                isLocalFile = false;
              }
            } else {
              // It's a URL
              audioPath =
                  attachmentStr.startsWith('/') &&
                      !attachmentStr.startsWith('http')
                  ? ApiEndpoints.baseUrl + attachmentStr
                  : attachmentStr;
              isLocalFile = false;
            }
          }
        }

        // Also try to match by timestamp if this is a sender's message (for recently sent)
        if (audioPath.isEmpty && isMine) {
          final createdAt = msg['created_at']?.toString();
          if (createdAt != null) {
            try {
              final createdTime = DateTime.parse(createdAt);
              final now = DateTime.now();
              // Check messages sent in last 5 minutes
              if (now.difference(createdTime).inMinutes < 5) {
                // Try to find matching local file by checking recent entries
                for (final entry in _localVoiceFiles.entries) {
                  final file = File(entry.value);
                  if (file.existsSync()) {
                    // Use this file as fallback
                    audioPath = entry.value;
                    isLocalFile = true;
                    print('✅ Matched local file by timestamp: ${entry.value}');
                    break;
                  }
                }
              }
            } catch (e) {
              // Ignore parse errors
            }
          }
        }

        // If still no audio path, try attachment_url field
        if (audioPath.isEmpty) {
          final String attachmentUrlField = (msg['attachment_url'] ?? '')
              .toString();
          if (attachmentUrlField.isNotEmpty) {
            audioPath =
                attachmentUrlField.startsWith('/') &&
                    !attachmentUrlField.startsWith('http')
                ? ApiEndpoints.baseUrl + attachmentUrlField
                : attachmentUrlField;
            isLocalFile = false;
          }
        }

        // If still no audio path found, try one more time with more aggressive extraction
        if (audioPath.isEmpty) {
          // Try checking if attachment is nested in a different structure
          if (msg['attachment'] is Map) {
            final attachmentMap = msg['attachment'] as Map;
            if (attachmentMap['url'] != null) {
              final url = attachmentMap['url'].toString();
              audioPath = url.startsWith('/') && !url.startsWith('http')
                  ? ApiEndpoints.baseUrl + url
                  : url;
              isLocalFile = false;
            } else if (attachmentMap['file'] != null) {
              final file = attachmentMap['file'].toString();
              audioPath = file.startsWith('/') && !file.startsWith('http')
                  ? ApiEndpoints.baseUrl + file
                  : file;
              isLocalFile = false;
            }
          }
        }
      } // Close the else block
    }

    // Last resort: Try to extract any URL from attachment field even if it looks like a path
    if (audioPath.isEmpty) {
      final dynamic rawAttachment = msg['attachment'];
      if (rawAttachment != null) {
        String attachmentStr = '';

        // Try different extraction methods
        if (rawAttachment is Map) {
          // Try all possible keys in the map
          final Map attachmentMap = rawAttachment;
          attachmentStr =
              (attachmentMap['url'] ??
                      attachmentMap['file'] ??
                      attachmentMap['path'] ??
                      attachmentMap['attachment'] ??
                      attachmentMap['source'] ??
                      '')
                  .toString();
        } else {
          attachmentStr = rawAttachment.toString();
        }

        if (attachmentStr.isNotEmpty) {
          // Check if it's a local file path that exists
          if (attachmentStr.startsWith('/data/') ||
              attachmentStr.startsWith('/storage/') ||
              attachmentStr.contains('app_flutter')) {
            final file = File(attachmentStr);
            if (file.existsSync()) {
              audioPath = attachmentStr;
              isLocalFile = true;
              print('✅ Found local file (last resort): $audioPath');
            } else {
              // File doesn't exist, treat as URL
              audioPath =
                  attachmentStr.startsWith('/') &&
                      !attachmentStr.startsWith('http')
                  ? ApiEndpoints.baseUrl + attachmentStr
                  : attachmentStr;
              isLocalFile = false;
              print('✅ Using attachment as URL (last resort): $audioPath');
            }
          } else {
            // Not a local path, treat as URL
            audioPath =
                attachmentStr.startsWith('/') &&
                    !attachmentStr.startsWith('http')
                ? ApiEndpoints.baseUrl + attachmentStr
                : attachmentStr;
            isLocalFile = false;
            print('✅ Using attachment as URL (last resort): $audioPath');
          }
        }
      }
    }

    // If still no audio path found, return a placeholder (don't return empty)
    if (audioPath.isEmpty) {
      print('⚠️ Voice message has no audio path: msg=$msg');
      // Return a placeholder that shows it's a voice message but can't be played
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Voice message (unavailable)',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // Now build the actual voice message player widget
    final duration = msg['duration'] != null
        ? Duration(seconds: (msg['duration'] as num).toInt())
        : Duration.zero;
    final isCurrentlyPlaying = _currentlyPlayingUrl == audioPath && _isPlaying;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Play/Pause button with circular background
        GestureDetector(
          onTap: () => _toggleVoicePlayback(audioPath, isLocalFile),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMine
                  ? textColor.withOpacity(0.2)
                  : bubbleColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCurrentlyPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: textColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Waveform/Progress bar and duration
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform visualization / Progress bar
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isMine
                      ? textColor.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background waveform bars (static visualization)
                    if (!isCurrentlyPlaying ||
                        _audioDuration.inMilliseconds == 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(20, (index) {
                          final height = (index % 3 == 0)
                              ? 8.0
                              : (index % 2 == 0 ? 12.0 : 16.0);
                          return Container(
                            width: 2,
                            height: height,
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }),
                      ),
                    // Progress indicator when playing
                    if (isCurrentlyPlaying && _audioDuration.inMilliseconds > 0)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final progressWidth =
                              constraints.maxWidth *
                              (_audioPosition.inMilliseconds /
                                  _audioDuration.inMilliseconds);
                          return Row(
                            children: [
                              Container(
                                width: progressWidth,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: List.generate(20, (index) {
                                    final height = (index % 3 == 0)
                                        ? 8.0
                                        : (index % 2 == 0 ? 12.0 : 16.0);
                                    return Container(
                                      width: 2,
                                      height: height,
                                      decoration: BoxDecoration(
                                        color: textColor.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    );
                                  }).take((progressWidth / 3).ceil()).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Duration text
              Row(
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(
                      isCurrentlyPlaying ? _audioPosition : duration,
                    ),
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _toggleVoicePlayback(String audioPath, bool isLocal) async {
    try {
      if (_currentlyPlayingUrl == audioPath && _isPlaying) {
        // Pause current playback
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Stop any currently playing audio
        if (_currentlyPlayingUrl != null) {
          await _audioPlayer.stop();
        }

        // Play the selected audio
        if (isLocal) {
          await _audioPlayer.play(DeviceFileSource(audioPath));
        } else {
          // For remote URLs, play directly
          await _audioPlayer.play(UrlSource(audioPath));
        }

        setState(() {
          _currentlyPlayingUrl = audioPath;
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play audio: $e')));
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;
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
        // Refresh in background
        _loadSilently();
        // Try to replace with remote URL after delay
        Future.delayed(const Duration(seconds: 2), () {
          _tryReplaceWithRemoteOnce();
        });
      } else if (mounted) {
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
                            // Check both snake_case and camelCase message type fields
                            final messageType =
                                (msg['message_type'] ??
                                        msg['messageType'] ??
                                        'text')
                                    .toString()
                                    .toLowerCase();
                            String attachmentUrl = '';
                            final dynamic rawAttachment = msg['attachment'];
                            final String attachmentUrlField =
                                (msg['attachment_url'] ?? '').toString();

                            // For voice messages, be more aggressive in finding the URL
                            final bool isVoiceMsg = messageType == 'voice';

                            if (attachmentUrlField.isNotEmpty) {
                              attachmentUrl = attachmentUrlField;
                            } else if (rawAttachment is Map<String, dynamic>) {
                              final String fromUrl =
                                  (rawAttachment['url'] ?? '').toString();
                              final String fromFile =
                                  (rawAttachment['file'] ?? '').toString();
                              final String fromPath =
                                  (rawAttachment['path'] ?? '').toString();
                              // Also check for 'attachment' key inside the map
                              final String fromAttachment =
                                  (rawAttachment['attachment'] ?? '')
                                      .toString();
                              final String candidate = fromUrl.isNotEmpty
                                  ? fromUrl
                                  : (fromFile.isNotEmpty
                                        ? fromFile
                                        : (fromPath.isNotEmpty
                                              ? fromPath
                                              : fromAttachment));
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

                            // For voice messages, ensure we normalize URLs properly
                            if (attachmentUrl.isNotEmpty) {
                              // Don't normalize if it's clearly a local file path
                              if (!attachmentUrl.startsWith('/data/') &&
                                  !attachmentUrl.startsWith('/storage/') &&
                                  !attachmentUrl.contains('app_flutter')) {
                                if (attachmentUrl.startsWith('/') &&
                                    !attachmentUrl.startsWith('http')) {
                                  attachmentUrl =
                                      ApiEndpoints.baseUrl + attachmentUrl;
                                }
                              }
                            }

                            // Debug for voice messages
                            if (isVoiceMsg) {
                              print(
                                '🎤 Voice message attachment extraction: attachmentUrl=$attachmentUrl, rawAttachment=$rawAttachment',
                              );
                            }
                            // Determine if message is from current user
                            // Try multiple ways to get current user ID
                            dynamic currentUserId;

                            // First try: current_user from chat details
                            if (_chat?['current_user']
                                is Map<String, dynamic>) {
                              currentUserId =
                                  (_chat!['current_user']
                                      as Map<String, dynamic>)['id'];
                            }

                            // Second try: user1 from chat
                            if (currentUserId == null &&
                                _chat?['user1'] is Map<String, dynamic>) {
                              final user1 =
                                  _chat!['user1'] as Map<String, dynamic>;
                              currentUserId = user1['id'];
                            }

                            // Third try: user2 from chat (if current user is user2)
                            if (currentUserId == null &&
                                _chat?['user2'] is Map<String, dynamic>) {
                              final user2 =
                                  _chat!['user2'] as Map<String, dynamic>;
                              currentUserId = user2['id'];
                            }

                            // Fourth try: from user profile in storage
                            if (currentUserId == null) {
                              final userProfile =
                                  StorageService.getUserProfile();
                              if (userProfile != null &&
                                  userProfile['id'] != null) {
                                currentUserId = userProfile['id'];
                              }
                            }

                            // Get sender ID
                            dynamic senderId;
                            if (msg['sender'] is Map<String, dynamic>) {
                              senderId =
                                  (msg['sender'] as Map<String, dynamic>)['id'];
                            }

                            // Compare IDs - handle both int and string comparisons
                            bool isMine = false;
                            if (senderId != null && currentUserId != null) {
                              // Convert both to strings for comparison to handle int vs string
                              final senderIdStr = senderId.toString();
                              final currentUserIdStr = currentUserId.toString();
                              isMine = senderIdStr == currentUserIdStr;
                            }

                            // Debug print to help diagnose issues
                            if (!isMine && senderId != null) {
                              print(
                                '📱 Message sender check: senderId=$senderId, currentUserId=$currentUserId, isMine=$isMine',
                              );
                            }
                            final bool isLocalImage =
                                messageType == 'image' &&
                                (msg['local'] == true) &&
                                ((msg['attachment']?.toString().isNotEmpty) ??
                                    false);
                            final bool isRemoteImage =
                                messageType == 'image' &&
                                attachmentUrl.isNotEmpty;
                            // Check if it's a voice message - be more aggressive in detection
                            // Check message_type first, but also check if content is "Voice message" with an attachment
                            bool isVoiceMessage = messageType == 'voice';

                            // Fallback: Check multiple ways to detect voice messages
                            if (!isVoiceMessage) {
                              // Method 1: Content is "Voice message" with attachment
                              bool hasVoiceContent =
                                  content.toLowerCase() == 'voice message' ||
                                  content.toLowerCase().contains('voice');

                              // Method 2: Check if attachment has audio file extension
                              bool hasAudioExtension = false;
                              String attachmentStr = '';
                              if (attachmentUrl.isNotEmpty) {
                                attachmentStr = attachmentUrl;
                              } else if (rawAttachment != null) {
                                attachmentStr = rawAttachment.toString();
                              } else if (msg['attachment_url'] != null) {
                                attachmentStr = msg['attachment_url']
                                    .toString();
                              } else if (msg['attachment'] != null) {
                                attachmentStr = msg['attachment'].toString();
                              }

                              if (attachmentStr.isNotEmpty) {
                                final lowerStr = attachmentStr.toLowerCase();
                                hasAudioExtension =
                                    lowerStr.endsWith('.m4a') ||
                                    lowerStr.endsWith('.mp3') ||
                                    lowerStr.endsWith('.wav') ||
                                    lowerStr.endsWith('.aac') ||
                                    lowerStr.endsWith('.ogg') ||
                                    lowerStr.contains('voice_') ||
                                    lowerStr.contains('/audio/') ||
                                    lowerStr.contains('/voice/');
                              }

                              // Method 3: Has attachment and content suggests voice
                              bool hasAttachment =
                                  attachmentUrl.isNotEmpty ||
                                  rawAttachment != null ||
                                  msg['attachment_url'] != null ||
                                  (msg['attachment'] != null &&
                                      msg['attachment'].toString().isNotEmpty);

                              if ((hasVoiceContent && hasAttachment) ||
                                  hasAudioExtension) {
                                isVoiceMessage = true;
                                print(
                                  '🎤 Voice message detected via fallback: content="$content", hasAttachment=$hasAttachment, hasAudioExtension=$hasAudioExtension, attachment="$attachmentStr"',
                                );
                              }
                            }

                            // Check if it's a local voice message (optimistic or recently sent)
                            final bool isLocalVoice =
                                isVoiceMessage &&
                                (msg['local'] == true ||
                                    msg['local_attachment'] != null ||
                                    msg['local_file_key'] != null) &&
                                ((msg['attachment']?.toString().isNotEmpty) ??
                                    false);

                            // For remote voice: check if attachment URL exists OR if message_type is voice with any attachment
                            // Also check if it's a voice message from sender (might have local file)
                            final bool isRemoteVoice =
                                isVoiceMessage &&
                                (attachmentUrl.isNotEmpty ||
                                    (rawAttachment != null &&
                                        rawAttachment.toString().isNotEmpty) ||
                                    (msg['attachment_url'] != null));

                            // Debug voice messages - ALWAYS log to help diagnose
                            if (isVoiceMessage) {
                              print(
                                '🎤 Voice message detected: messageType=$messageType, isLocalVoice=$isLocalVoice, isRemoteVoice=$isRemoteVoice',
                              );
                              print('   attachmentUrl=$attachmentUrl');
                              print('   rawAttachment=$rawAttachment');
                              print('   msg keys: ${msg.keys.toList()}');
                              print('   msg[attachment]=${msg['attachment']}');
                              print(
                                '   msg[attachment_url]=${msg['attachment_url']}',
                              );
                              print('   msg[local]=${msg['local']}');
                              print(
                                '   msg[local_attachment]=${msg['local_attachment']}',
                              );
                              print('   isMine=$isMine');
                            } else if (content.toLowerCase().contains(
                                  'voice',
                                ) ||
                                (msg['attachment'] != null ||
                                    msg['attachment_url'] != null)) {
                              // Log messages that might be voice but weren't detected
                              print(
                                '⚠️ Potential voice message NOT detected: messageType=$messageType, content="$content"',
                              );
                              print('   attachmentUrl=$attachmentUrl');
                              print('   rawAttachment=$rawAttachment');
                              print('   msg[attachment]=${msg['attachment']}');
                              print(
                                '   msg[attachment_url]=${msg['attachment_url']}',
                              );
                            }

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
                                      backgroundColor: _getAvatarColor(
                                        senderName,
                                      ),
                                      child: Text(
                                        senderName.isNotEmpty
                                            ? senderName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
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
                                                : isVoiceMessage
                                                ? _buildVoiceMessageBubble(
                                                    msg,
                                                    isMine,
                                                    textColor,
                                                    bubbleColor,
                                                    isLocalVoice ||
                                                        (msg['local_attachment'] !=
                                                            null),
                                                    isRemoteVoice ||
                                                        attachmentUrl
                                                            .isNotEmpty ||
                                                        (msg['attachment'] !=
                                                            null),
                                                    attachmentUrl,
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
                                  if (isMine) ...[
                                    Builder(
                                      builder: (context) {
                                        final currentUser =
                                            _chat?['current_user']
                                                as Map<String, dynamic>?;
                                        final currentUserName =
                                            currentUser?['display_name'] ??
                                            currentUser?['full_name'] ??
                                            ((currentUser?['first_name'] !=
                                                        null ||
                                                    currentUser?['last_name'] !=
                                                        null)
                                                ? '${currentUser?['first_name'] ?? ''} ${currentUser?['last_name'] ?? ''}'
                                                      .trim()
                                                : null) ??
                                            'Me';
                                        final avatarColor = _getAvatarColor(
                                          currentUserName,
                                        );
                                        return CircleAvatar(
                                          radius: 14,
                                          backgroundColor: avatarColor,
                                          child: Text(
                                            currentUserName.isNotEmpty
                                                ? currentUserName[0]
                                                      .toUpperCase()
                                                : 'M',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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
                                  tooltip: _isRecording
                                      ? 'Stop recording'
                                      : 'Record voice',
                                  icon: Icon(
                                    _isRecording
                                        ? Icons.stop_circle
                                        : Icons.mic,
                                    color: _isRecording
                                        ? Colors.red
                                        : const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    if (_isRecording) {
                                      _stopRecording();
                                    } else {
                                      _startRecording();
                                    }
                                  },
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
                                  child: _isRecording
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatDuration(
                                                  _recordingDuration,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const Spacer(),
                                              TextButton(
                                                onPressed: () => _stopRecording(
                                                  showPreview: false,
                                                ),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : TextField(
                                          controller: _controller,
                                          minLines: 1,
                                          maxLines: 4,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Type a message',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF94A3B8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
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

class _VoicePreviewDialog extends StatefulWidget {
  final String recordedFilePath;
  final Duration recordingDuration;
  final String Function(Duration) formatDuration;

  const _VoicePreviewDialog({
    required this.recordedFilePath,
    required this.recordingDuration,
    required this.formatDuration,
  });

  @override
  State<_VoicePreviewDialog> createState() => _VoicePreviewDialogState();
}

class _VoicePreviewDialogState extends State<_VoicePreviewDialog> {
  late AudioPlayer _previewPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    try {
      _previewPlayer = AudioPlayer();
      _duration = widget.recordingDuration;

      // Setup listeners
      _previewPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _previewPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _previewPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });
    } catch (e) {
      print('❌ Error initializing preview player: $e');
    }
  }

  @override
  void dispose() {
    _previewPlayer.stop();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _previewPlayer.pause();
    } else {
      await _previewPlayer.play(DeviceFileSource(widget.recordedFilePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressWidth = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return AlertDialog(
      title: const Text('Voice Message Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            // Playback controls
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: Colors.blue,
              ),
              onPressed: _togglePlayback,
            ),
            const SizedBox(height: 8),
            // Progress bar
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  if (_duration.inMilliseconds > 0 && progressWidth > 0)
                    FractionallySizedBox(
                      widthFactor: progressWidth,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${widget.formatDuration(_isPlaying ? _position : _duration)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
