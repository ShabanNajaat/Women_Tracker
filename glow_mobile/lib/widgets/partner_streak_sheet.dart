import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/partner_service.dart';

/// Link a partner or copy your invite code for daily streak accountability.
Future<void> showPartnerStreakSheet(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final codeCtrl = TextEditingController();
  String? myCode;
  bool loadingCode = true;
  bool joining = false;

  if (ApiService().isAuthenticated) {
    myCode = await PartnerService.instance.fetchInviteCode();
  }
  loadingCode = false;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.paddingOf(ctx).bottom + 24),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Partner streak',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Link someone you trust. Each day you check in, they see your streak — and you see theirs. '
                    'Gentle accountability to open Glow every day.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!ApiService().isAuthenticated)
                    Text(
                      'Sign in to link a partner and sync streaks.',
                      style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
                    )
                  else ...[
                    Text(
                      'Your invite code',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (loadingCode)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              myCode ?? '—',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy code',
                            onPressed: myCode == null
                                ? null
                                : () async {
                                    await Clipboard.setData(ClipboardData(text: myCode!));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invite code copied')),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Partner\'s invite code',
                        hintText: 'ABC123',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: joining
                          ? null
                          : () async {
                              setModalState(() => joining = true);
                              final err = await PartnerService.instance.joinPartner(codeCtrl.text);
                              if (!context.mounted) return;
                              setModalState(() => joining = false);
                              if (err == null) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Partner linked — streaks are shared!')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)),
                                );
                              }
                            },
                      child: joining
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Link partner'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    },
  );
  codeCtrl.dispose();
}
