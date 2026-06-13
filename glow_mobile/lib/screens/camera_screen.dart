import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  static const _pink = Color(0xFFFF8FC8);
  static const _darkPink = Color(0xFFE0569A);

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;
  int _selectedCameraIdx = 0;

  Uint8List? _capturedBytes;
  String? _capturedBase64;
  bool _isSending = false;
  final _captionController = TextEditingController();

  List<dynamic> _friends = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFriends();
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final res = await ApiService().get('/friends');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _friends = (data['friends'] as List?) ?? []);
      }
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      // Prefer front camera for selfie streaks
      _selectedCameraIdx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;
      await _setupCameraController();
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _isCameraPermissionDenied = true);
    }
  }

  Future<void> _setupCameraController() async {
    if (_cameras.isEmpty) return;
    final prev = _controller;
    if (prev != null) {
      await prev.dispose();
    }
    final ctrl = CameraController(
      _cameras[_selectedCameraIdx],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera controller error: $e');
      if (mounted) setState(() => _isCameraPermissionDenied = true);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isCameraInitialized = false);
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    await _setupCameraController();
  }

  Future<void> _capturePhoto() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || ctrl.value.isTakingPicture) return;
    try {
      final file = await ctrl.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _capturedBytes = bytes;
          _capturedBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture: $e'), backgroundColor: Colors.red[400]),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _capturedBytes = bytes;
          _capturedBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.red[400]),
      );
    }
  }

  void _retake() {
    setState(() {
      _capturedBytes = null;
      _capturedBase64 = null;
      _captionController.clear();
    });
  }

  void _sendAsStreak() {
    if (_capturedBase64 == null && _captionController.text.trim().isEmpty) return;
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add friends first to send streaks! 💕'), backgroundColor: _pink),
      );
      return;
    }
    _showFriendSelectorSheet(
      imageData: _capturedBase64,
      caption: _captionController.text.trim().isEmpty ? '🔥 Streak!' : _captionController.text.trim(),
    );
  }

  void _showFriendSelectorSheet({String? imageData, required String caption}) {
    final selectedIds = <String>{};
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.grey.shade300)),
                const SizedBox(height: 20),
                const Text('Send to... 🔥', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 6),
                Text('Pick who gets your streak', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _friends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final f = _friends[i];
                      final name = f['username']?.toString() ?? 'Friend';
                      final fId = f['_id']?.toString() ?? '';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                      final selected = selectedIds.contains(fId);
                      return GestureDetector(
                        onTap: () => setSheetState(() => selected ? selectedIds.remove(fId) : selectedIds.add(fId)),
                        child: Column(children: [
                          Stack(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 58, height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: selected ? const LinearGradient(colors: [_pink, _darkPink]) : null,
                                color: selected ? null : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                                border: Border.all(color: selected ? _pink : Colors.transparent, width: 3),
                                boxShadow: selected ? [BoxShadow(color: _pink.withValues(alpha: 0.4), blurRadius: 12)] : [],
                              ),
                              child: Center(child: Text(initial, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: selected ? Colors.white : Theme.of(ctx).colorScheme.onSurface))),
                            ),
                            if (selected)
                              Positioned(right: 0, bottom: 0, child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: _pink),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              )),
                          ]),
                          const SizedBox(height: 6),
                          Text(name.length > 7 ? '${name.substring(0, 7)}..' : name,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? _pink : Theme.of(ctx).colorScheme.onSurfaceVariant)),
                        ]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: selectedIds.isEmpty ? null : () {
                      Navigator.pop(ctx);
                      _doSend(selectedIds.toList(), imageData: imageData, caption: caption);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _pink, foregroundColor: Colors.white,
                      disabledBackgroundColor: _pink.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(LucideIcons.send, size: 20),
                    label: Text('Send Streak 🔥${selectedIds.isNotEmpty ? " (${selectedIds.length})" : ""}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _doSend(List<String> ids, {String? imageData, required String caption}) async {
    setState(() => _isSending = true);
    int sent = 0;
    for (final id in ids) {
      try {
        final body = <String, dynamic>{'friendId': id, 'caption': caption};
        if (imageData != null) body['imageData'] = imageData;
        final res = await ApiService().post('/streaks/send', body: body);
        if (res.statusCode == 200) sent++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (sent > 0) _retake();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent > 0 ? '🔥 Streak sent to $sent friend${sent > 1 ? 's' : ''}!' : 'Could not send streak'),
      backgroundColor: sent > 0 ? _pink : Colors.red[400],
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _capturedBytes != null ? _buildPreviewView() : _buildLiveCameraView(),
    );
  }

  // ── LIVE CAMERA VIEW ─────────────────────────────────────────────────────
  Widget _buildLiveCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview fills the whole screen
        if (_isCameraInitialized && _controller != null)
          ClipRect(child: CameraPreview(_controller!))
        else if (_isCameraPermissionDenied)
          _buildPermissionDeniedView()
        else
          const Center(child: CircularProgressIndicator(color: _pink)),

        // Top controls
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flip camera button
                  if (_cameras.length > 1)
                    _CameraIconButton(
                      icon: LucideIcons.refreshCcw,
                      onTap: _flipCamera,
                    ),
                  const Spacer(),
                  // Gallery button
                  _CameraIconButton(
                    icon: LucideIcons.image,
                    onTap: _pickFromGallery,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom capture button
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shutter
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _pink, width: 5),
                      ),
                      child: Center(
                        child: Container(
                          width: 62, height: 62,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tap to capture', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.cameraOff, color: Colors.white54, size: 56),
          SizedBox(height: 16),
          Text('Camera permission required', style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 8),
          Text('Please allow camera access in your browser', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  // ── PREVIEW + SEND VIEW ──────────────────────────────────────────────────
  Widget _buildPreviewView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo preview full screen
        Image.memory(_capturedBytes!, fit: BoxFit.cover),

        // Dark gradient at bottom for readability
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // Top: retake button
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _CameraIconButton(icon: LucideIcons.x, onTap: _retake),
                ],
              ),
            ),
          ),
        ),

        // Bottom: caption + send
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black54,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 2, minLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Send streak button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _isSending ? null : _sendAsStreak,
                      style: FilledButton.styleFrom(
                        backgroundColor: _pink, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(LucideIcons.send, size: 20),
                      label: const Text('Send as Streak 🔥', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper icon button ────────────────────────────────────────────────────
class _CameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CameraIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black45,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
