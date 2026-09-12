import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';

class ImageAdminScreen extends StatefulWidget {
  const ImageAdminScreen({super.key});
  @override
  State<ImageAdminScreen> createState() => _ImageAdminScreenState();
}

class _ImageAdminScreenState extends State<ImageAdminScreen> {
  bool _busy = false;
  String _msg = '';

  void _snack(String m) {
    setState(() => _msg = m);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickAndUploadHome(int slot) async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => _busy = true);
    try {
      final path = 'assets/images/home$slot.png';
      await ImagesService.putBytes(path, bytes, kUploadToken, 'home image $slot');
      await ImagesService.setMapping('home', '$slot', path, kUploadToken);
      _snack('✅ تم رفع صورة الرئيسية $slot');
    } catch (e) {
      _snack('فشل الرفع: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadProduct(String pid, String pname) async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1000);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => _busy = true);
    try {
      final path = 'assets/images/prod_$pid.png';
      await ImagesService.putBytes(path, bytes, kUploadToken, 'product $pid');
      await ImagesService.setMapping('products', pid, path, kUploadToken);
      _snack('✅ تم رفع صورة المنتج: $pname');
    } catch (e) {
      _snack('فشل الرفع: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الصور'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              s.exitImageAdmin();
              Navigator.pop(context);
            }),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_msg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_msg, style: const TextStyle(fontSize: 13)),
                  ),
                const Text('🏠 صور الصفحة الرئيسية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (int i = 1; i <= 4; i++)
                    ActionChip(
                        label: Text('بانر $i'),
                        onPressed: () => _pickAndUploadHome(i)),
                ]),
                const SizedBox(height: 24),
                const Text('📦 صور المنتجات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...sampleProducts.map((p) => ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: Theme.of(context).colorScheme.surface,
                      title: Text(p.name),
                      subtitle: const Text('اضغط لرفع صورة'),
                      trailing: const Icon(Icons.image_outlined,
                          color: AppColors.orange),
                      onTap: () => _pickAndUploadProduct(p.id, p.name),
                    )),
              ],
            ),
    );
  }
}
