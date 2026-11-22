import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../services/api/school_service.dart';
import 'school_ui.dart';

/// Picks (or takes) a photo and uploads it. Returns {url, name, type} or null.
Future<Map<String, dynamic>?> pickAndUploadPhoto(BuildContext context, SchoolService svc) async {
  ImageSource source = ImageSource.gallery;
  final canCamera = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  if (canCamera) {
    final s = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const T('Take a photo'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const T('Choose from gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      ),
    );
    if (s == null) return null;
    source = s;
  }
  try {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 80);
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final name = x.name.isNotEmpty ? x.name : 'photo.jpg';
    final lower = name.toLowerCase();
    final mime = lower.endsWith('.png') ? 'image/png' : lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
    return await svc.uploadImage(bytes, name, mime: mime);
  } catch (e) {
    if (context.mounted) showSnack(context, 'Could not upload the photo: $e', error: true);
    return null;
  }
}

/// Thumbnails of attached photos; tap opens full size; optional remove.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({super.key, required this.items, this.onRemove, this.size = 84});
  final List<Map<String, dynamic>> items;
  final void Function(int index)? onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (var i = 0; i < items.length; i++)
        Stack(children: [
          InkWell(
            onTap: () => showDialog(context: context, builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: InteractiveViewer(child: Image.network('${items[i]['url']}', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(40), child: Icon(Icons.broken_image_outlined, size: 48))))),
                OverflowBar(children: [
                  TextButton.icon(onPressed: () => launchUrl(Uri.parse('${items[i]['url']}'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: const T('Open')),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Close')),
                ]),
              ]),
            )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: size,
                height: size,
                color: AppTheme.getBorderColor(context).withValues(alpha: 0.3),
                child: (items[i]['type'] ?? 'image').toString().startsWith('image')
                    ? Image.network('${items[i]['url']}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined))
                    : const Icon(Icons.insert_drive_file_outlined),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              right: 2,
              top: 2,
              child: InkWell(
                onTap: () => onRemove!(i),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ]),
    ]);
  }
}
