import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/track.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textTertiary,
          indicatorColor: AppTheme.accent,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '유저'),
            Tab(text: '트랙'),
            Tab(text: '댓글'),
            Tab(text: '공지'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _UsersTab(),
          _TracksTab(),
          _CommentsTab(),
          _AnnouncementTab(),
        ],
      ),
    );
  }
}

// ─── Users Tab ───
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _users = await ApiService.getUsers();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_users.isEmpty) return const Center(child: Text('유저가 없습니다', style: TextStyle(color: AppTheme.textTertiary)));

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, i) {
          final u = _users[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.bg3,
              backgroundImage: (u['avatar'] ?? '').isNotEmpty ? NetworkImage(u['avatar']) : null,
              child: (u['avatar'] ?? '').isEmpty ? const Icon(Icons.person, color: AppTheme.textTertiary, size: 20) : null,
            ),
            title: Text(u['name'] ?? '-', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('${u['provider'] ?? '-'} · ${u['email'] ?? '-'}',
                style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(u['plan'] ?? 'free', style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tracks Tab ───
class _TracksTab extends StatefulWidget {
  const _TracksTab();
  @override
  State<_TracksTab> createState() => _TracksTabState();
}

class _TracksTabState extends State<_TracksTab> {
  List<Track> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _tracks = await ApiService.getAllTracks();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_tracks.isEmpty) return const Center(child: Text('트랙이 없습니다', style: TextStyle(color: AppTheme.textTertiary)));

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (ctx, i) {
          final t = _tracks[i];
          return ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.bg3,
                image: t.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(t.imageUrl), fit: BoxFit.cover) : null,
              ),
              child: t.imageUrl.isEmpty ? const Icon(Icons.music_note, color: AppTheme.textTertiary, size: 20) : null,
            ),
            title: Text(t.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${t.ownerName} · ${t.likes}L ${t.dislikes}D ${t.plays}P',
                style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              // 공개/비공개 토글
              IconButton(
                icon: Icon(t.isPublic ? Icons.visibility : Icons.visibility_off,
                    color: t.isPublic ? AppTheme.green : AppTheme.textTertiary, size: 20),
                onPressed: () async {
                  await ApiService.toggleTrackVisibility(t.id, !t.isPublic);
                  _load();
                },
              ),
              // 삭제
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.card,
                      title: const Text('트랙 삭제', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                      content: Text('${t.title}을(를) 삭제합니까?', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: AppTheme.textTertiary))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: AppTheme.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ApiService.deleteTrack(t.id);
                    _load();
                  }
                },
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ─── Comments Tab ───
class _CommentsTab extends StatefulWidget {
  const _CommentsTab();
  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // 전체 댓글 조회 (track_id 없이)
    _comments = await ApiService.getComments('');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_comments.isEmpty) return const Center(child: Text('댓글이 없습니다', style: TextStyle(color: AppTheme.textTertiary)));

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _comments.length,
        itemBuilder: (ctx, i) {
          final c = _comments[i];
          return ListTile(
            leading: const CircleAvatar(backgroundColor: AppTheme.bg3, child: Icon(Icons.comment, color: AppTheme.textTertiary, size: 18)),
            title: Text(c['content'] ?? '-', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${c['author_name'] ?? '-'} · ${c['track_id'] ?? ''}',
                style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
          );
        },
      ),
    );
  }
}

// ─── Announcement Tab ───
class _AnnouncementTab extends StatefulWidget {
  const _AnnouncementTab();
  @override
  State<_AnnouncementTab> createState() => _AnnouncementTabState();
}

class _AnnouncementTabState extends State<_AnnouncementTab> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _sending = false;
  Map<String, dynamic>? _current;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    _current = await ApiService.getAnnouncement();
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final ok = await ApiService.sendAnnouncement(
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
    );
    setState(() => _sending = false);
    if (ok && mounted) {
      _titleCtrl.clear();
      _contentCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지가 발송되었습니다'), backgroundColor: AppTheme.green),
      );
      _loadCurrent();
    }
  }

  Future<void> _delete() async {
    final ok = await ApiService.deleteAnnouncement();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지가 삭제되었습니다'), backgroundColor: AppTheme.accent),
      );
      _loadCurrent();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Current announcement
        if (_current != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.yellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.yellow.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.campaign, color: AppTheme.yellow, size: 18),
                const SizedBox(width: 8),
                const Text('현재 공지', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                GestureDetector(
                  onTap: _delete,
                  child: const Icon(Icons.delete_outline, color: AppTheme.red, size: 18),
                ),
              ]),
              const SizedBox(height: 8),
              Text(_current!['title'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_current!['content'] ?? _current!['message'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 24),
        ],

        const Text('새 공지 발송', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: '공지 제목',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            filled: true, fillColor: AppTheme.bg3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.accent)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contentCtrl,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '공지 내용',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            filled: true, fillColor: AppTheme.bg3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.accent)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, size: 16),
          label: Text(_sending ? '발송 중...' : '공지 발송'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }
}
