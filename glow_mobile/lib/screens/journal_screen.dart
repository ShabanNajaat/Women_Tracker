import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/api_service.dart';
import '../services/challenge_service.dart';
import '../services/journal_wellness_note.dart';
import '../services/wellness_score_service.dart';
import '../widgets/glass_card.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _moods = ['Happy', 'Calm', 'Tired', 'Sad', 'Anxious'];
  String _selectedMood = 'Happy';
  final _notes = TextEditingController();
  final Set<String> _selectedSymptoms = {};
  bool _saving = false;

  final List<String> _symptoms = ['Cramps', 'Headache', 'Bloating', 'Acne', 'Nausea'];

  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final api = ApiService();
    if (!api.isAuthenticated) return;
    setState(() => _loadingHistory = true);
    try {
      final res = await api.get('/tracking/logs');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final list = <Map<String, dynamic>>[];
          for (final e in data) {
            if (e is Map) {
              list.add(Map<String, dynamic>.from(e));
            }
          }
          list.sort((a, b) {
            final da = '${a['date'] ?? ''}';
            final db = '${b['date'] ?? ''}';
            return db.compareTo(da);
          });
          setState(() => _history = list);
        }
      }
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _save() async {
    final api = ApiService();
    if (!api.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save journal entries to your account.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'moods': [_selectedMood],
        'symptoms': _selectedSymptoms.toList(),
        'notes': _notes.text.trim(),
      };
      final res = await api.post('/tracking/logs', body: body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final savedMood = _selectedMood;
        final savedSymptoms = List<String>.from(_selectedSymptoms);
        await WellnessScoreService.instance.maybeAwardJournalBonus();
        await ChallengeService.instance.recordTodayProgressIfNeeded();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved')),
        );
        _notes.clear();
        setState(() => _selectedSymptoms.clear());
        await _loadHistory();
        if (!mounted) return;
        _showWellnessNoteAfterSave(savedMood, savedSymptoms);
      } else if (res.statusCode == 401) {
        await api.clearAuth();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please sign in again.')),
        );
      } else {
        String? msg;
        try {
          final m = jsonDecode(res.body);
          if (m is Map && m['msg'] != null) msg = m['msg'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? 'Could not save (${res.statusCode})')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline or server unreachable.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showWellnessNoteAfterSave(String mood, List<String> symptoms) {
    final text = JournalWellnessNote.build(mood: mood, symptoms: symptoms);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Something gentle for today'),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(height: 1.4)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _exportHistoryPdf() async {
    if (_history.isEmpty || !mounted) return;
    setState(() => _exportingPdf = true);
    try {
      final doc = pw.Document();
      final dateFmt = DateFormat.yMMMd();
      final rows = <pw.Widget>[];
      for (final row in _history) {
        final dateStr = row['date']?.toString() ?? '';
        DateTime? parsed;
        try {
          if (dateStr.length >= 10) parsed = DateTime.parse(dateStr.substring(0, 10));
        } catch (_) {}
        final header = parsed != null ? dateFmt.format(parsed) : dateStr;
        final moods = row['moods'] is List
            ? List<String>.from((row['moods'] as List).map((e) => '$e'))
            : <String>[];
        final symptoms =
            row['symptoms'] is List ? List<String>.from((row['symptoms'] as List).map((e) => '$e')) : <String>[];
        final notes = row['notes']?.toString() ?? '';
        rows.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey500)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(header, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (moods.isNotEmpty) pw.Text('Mood: ${moods.join(', ')}', style: const pw.TextStyle(fontSize: 10)),
                if (symptoms.isNotEmpty)
                  pw.Text('Symptoms: ${symptoms.join(', ')}', style: const pw.TextStyle(fontSize: 10)),
                if (notes.isNotEmpty) pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text('Glow — journal history', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
              'Exported ${dateFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
            ...rows,
          ],
        ),
      );

      final bytes = await doc.save();
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'glow_journal_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not build PDF. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 24, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                      child: Text(
                        'Journal',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              tabs: const [
                Tab(text: 'New entry'),
                Tab(text: 'History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewEntry(scheme),
                  _buildHistory(scheme),
               ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewEntry(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log mood & symptoms — everything saves to your timeline.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 24),
          Text(
            'Current mood',
            style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMoodPicker(scheme),
          const SizedBox(height: 28),
          Text(
            'Symptoms (tap all that apply)',
            style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSymptomGrid(scheme),
          const SizedBox(height: 28),
          Text(
            'Notes',
            style: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GlassCard(
            useBackdropBlur: false,
            child: TextField(
              controller: _notes,
              maxLines: 4,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Anything else on your mind?',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.85)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (_saving)
            LinearProgressIndicator(
              minHeight: 3,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.save, size: 20, color: scheme.onPrimary),
                const SizedBox(width: 10),
                const Text('Save to journal', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(ColorScheme scheme) {
    if (!ApiService().isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sign in to see past entries with symptoms and notes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
          ),
        ),
      );
    }
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_outlined, size: 48, color: scheme.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'No saved entries yet',
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved logs appear here with date, mood, symptoms, and notes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _loadHistory,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Export your history as a PDF.',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _exportingPdf ? null : _exportHistoryPdf,
                icon: _exportingPdf
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: Text(_exportingPdf ? 'Working…' : 'Download PDF'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            itemCount: _history.length,
            itemBuilder: (context, i) {
        final row = _history[i];
        final dateStr = row['date']?.toString() ?? '';
        DateTime? parsed;
        try {
          if (dateStr.length >= 10) {
            parsed = DateTime.parse(dateStr.substring(0, 10));
          }
        } catch (_) {}
        final moods = row['moods'] is List ? List<String>.from((row['moods'] as List).map((e) => '$e')) : <String>[];
        final symptoms =
            row['symptoms'] is List ? List<String>.from((row['symptoms'] as List).map((e) => '$e')) : <String>[];
        final notes = row['notes']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            useBackdropBlur: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed != null ? DateFormat('EEE, MMM d, y').format(parsed) : dateStr,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (moods.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Mood: ${moods.join(', ')}',
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Symptoms',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptoms
                        .map(
                          (s) => Chip(
                            label: Text(s, style: TextStyle(color: scheme.onPrimary, fontSize: 12)),
                            backgroundColor: scheme.primary.withValues(alpha: 0.35),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    notes,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        );
      },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodPicker(ColorScheme scheme) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final isSelected = _selectedMood == mood;
          return GestureDetector(
            onTap: () => setState(() => _selectedMood = mood),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary.withValues(alpha: 0.28) : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outline.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.smile, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(
                    mood,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSymptomGrid(ColorScheme scheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _symptoms.map((s) => _buildSymptomChip(scheme, s)).toList(),
    );
  }

  Widget _buildSymptomChip(ColorScheme scheme, String label) {
    final on = _selectedSymptoms.contains(label);
    return FilterChip(
      label: Text(label),
      selected: on,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSymptoms.add(label);
          } else {
            _selectedSymptoms.remove(label);
          }
        });
      },
      selectedColor: scheme.primary.withValues(alpha: 0.35),
      checkmarkColor: scheme.onPrimary,
      labelStyle: TextStyle(
        color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
