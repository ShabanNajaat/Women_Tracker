import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/story_service.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/glow_page_app_bar.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

enum _StoryMode { choose, photo, text }

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  static const _pink = Color(0xFFFF8FC8);
  static const _darkPink = Color(0xFFE0569A);

  final _captionController = TextEditingController();
  final _textController = TextEditingController();
  Uint8List? _imageBytes;
  String? _base64Image;
  bool _isPosting = false;
  _StoryMode _mode = _StoryMode.choose;

  @override
  void dispose() {
    _captionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: source, maxWidth: 1080, maxHeight: 1920, imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          _mode = _StoryMode.photo;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.red[400]),
      );
    }
  }

  Future<void> _post() async {
    setState(() => _isPosting = true);
    String? error;

    if (_mode == _StoryMode.photo && _base64Image != null) {
      error = await StoryService.instance.createStory(
        _base64Image!,
        _captionController.text.trim(),
      );
    } else if (_mode == _StoryMode.text) {
      final text = _textController.text.trim();
      if (text.isEmpty) {
        setState(() => _isPosting = false);
        return;
      }
      // Post text-only story (no image, caption = the text)
      error = await StoryService.instance.createTextStory(text);
    }

    if (!mounted) return;
    setState(() => _isPosting = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story posted! ✨'),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red[400]),
      );
    }
  }

  bool get _canPost {
    if (_mode == _StoryMode.photo) return _base64Image != null;
    if (_mode == _StoryMode.text) return _textController.text.trim().isNotEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlowPageAppBar(
        title: Text(_mode == _StoryMode.text ? 'Text Story' : 'New Story'),
        actions: [
          if (_canPost)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isPosting ? null : _post,
                style: FilledButton.styleFrom(
                  backgroundColor: _pink, foregroundColor: Colors.white,
                ),
                child: _isPosting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Post'),
              ),
            ),
        ],
      ),
      body: AppBackdrop(
        child: _mode == _StoryMode.choose
            ? _buildChooseMode(scheme)
            : _mode == _StoryMode.text
                ? _buildTextMode(scheme)
                : _buildPhotoMode(scheme),
      ),
    );
  }

  // ── CHOOSE MODE ──────────────────────────────────────────────────────────
  Widget _buildChooseMode(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share to your story', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface)),
          const SizedBox(height: 6),
          Text('What would you like to post?', style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          // Photo card
          _StoryTypeCard(
            icon: LucideIcons.camera,
            title: 'Photo Story',
            subtitle: 'Take a photo or pick from your gallery',
            gradient: const [_pink, _darkPink],
            onTap: () => setState(() => _mode = _StoryMode.photo),
          ),
          const SizedBox(height: 16),
          // Text card
          _StoryTypeCard(
            icon: LucideIcons.type,
            title: 'Text Story',
            subtitle: 'Write something and share it with friends',
            gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            onTap: () => setState(() => _mode = _StoryMode.text),
          ),
          const SizedBox(height: 16),
          // Gallery card
          _StoryTypeCard(
            icon: LucideIcons.image,
            title: 'Gallery',
            subtitle: 'Pick an existing photo from your device',
            gradient: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  // ── TEXT MODE ─────────────────────────────────────────────────────────────
  Widget _buildTextMode(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Big text area that looks like a story card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFFE0569A)],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 1.5),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'What\'s on your mind? ✨',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Post button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _canPost && !_isPosting ? _post : null,
              style: FilledButton.styleFrom(
                backgroundColor: _pink, foregroundColor: Colors.white,
                disabledBackgroundColor: _pink.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isPosting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.send),
              label: const Text('Post to Story', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── PHOTO MODE ────────────────────────────────────────────────────────────
  Widget _buildPhotoMode(ColorScheme scheme) {
    return Column(
      children: [
        // Source picker
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(child: _SourceButton(icon: LucideIcons.camera, label: 'Camera 📸', onTap: () => _pickImage(ImageSource.camera))),
              const SizedBox(width: 12),
              Expanded(child: _SourceButton(icon: LucideIcons.image, label: 'Gallery 🖼️', onTap: () => _pickImage(ImageSource.gallery))),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_imageBytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 10, right: 10,
                          child: IconButton(
                            onPressed: () => setState(() { _imageBytes = null; _base64Image = null; }),
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: Border.all(color: _pink.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.imagePlus, size: 56, color: _pink.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('Choose a photo', style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        // Caption
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _captionController,
            maxLines: 2, minLines: 1,
            style: TextStyle(color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(LucideIcons.type, color: _pink.withValues(alpha: 0.6), size: 20),
            ),
          ),
        ),
        if (_base64Image != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isPosting ? null : _post,
                style: FilledButton.styleFrom(
                  backgroundColor: _pink, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isPosting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.send),
                label: const Text('Share to Story', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }
}

// ── Story Type Card ───────────────────────────────────────────────────────
class _StoryTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _StoryTypeCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: gradient.map((c) => c.withValues(alpha: 0.12)).toList()),
            border: Border.all(color: gradient.first.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: gradient.first.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Source Button ──────────────────────────────────────────────────────────
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  static const _pink = Color(0xFFFF8FC8);
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [_pink.withValues(alpha: 0.15), _pink.withValues(alpha: 0.05)]),
            border: Border.all(color: _pink.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _pink, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
