import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/github_admin.dart';
import '../core/theme.dart';

Future<String?> askTokenDialog(BuildContext context, AppSettings s) =>
    showDialog<String>(
      context: context,
      builder: (_) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(s.tr('enterToken')),
          content: TextField(
            controller: c,
            obscureText: true,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(hintText: 'ghp_...'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.tr('cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: Text(s.tr('save'))),
          ],
        );
      },
    );

class AdminScreen extends StatefulWidget {
  final String token;
  const AdminScreen({super.key, required this.token});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late String _token = widget.token;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tr('adminPanel')),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: s.tr('changeToken'),
            onPressed: () async {
              final t = await askTokenDialog(context, s);
              if (t != null && t.isNotEmpty) {
                await GitHubAdmin.saveToken(t);
                setState(() => _token = t);
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(s.tr('tokenSaved'))));
                }
              }
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: GitHubAdmin.files.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final f = GitHubAdmin.files[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Theme.of(context).colorScheme.surface,
            leading: const Icon(Icons.description_outlined, color: AppColors.orange),
            title: Text(f,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.edit_rounded, color: AppColors.teal, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminEditor(path: f, token: _token)),
            ),
          );
        },
      ),
    );
  }
}

class AdminEditor extends StatefulWidget {
  final String path;
  final String token;
  const AdminEditor({super.key, required this.path, required this.token});
  @override
  State<AdminEditor> createState() => _AdminEditorState();
}

class _AdminEditorState extends State<AdminEditor> {
  final _c = TextEditingController();
  String? _sha;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await GitHubAdmin.getFile(widget.path, widget.token);
      if (!mounted) return;
      setState(() {
        _c.text = r.content;
        _sha = r.sha;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _save() async {
    if (_sha == null) return;
    setState(() => _saving = true);
    try {
      await GitHubAdmin.putFile(widget.path, _c.text, _sha!, widget.token);
      if (!mounted) return;
      final s = context.read<AppSettings>();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.tr('savedRebuild'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path,
            textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 15)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  tooltip: s.tr('save'),
                  onPressed: _save),
        ],
      ),
      body: _loading
          ? Center(child: Text(s.tr('loading')))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _c,
                  maxLines: null,
                  expands: true,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                      border: InputBorder.none, contentPadding: EdgeInsets.zero),
                ),
              ),
            ),
    );
  }
}
