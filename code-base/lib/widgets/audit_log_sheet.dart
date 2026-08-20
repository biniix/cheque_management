import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/audit_log.dart';
import '../providers/audit_logs_provider.dart';

Future<void> showAuditLogDialog(
  BuildContext context, {
  required String entity, // 'account' | 'customer' | 'transaction' | 'transfer' | 'cheque'
  required int entityId,
  required String title,
  required IconData entityIcon,
  Color entityColor = const Color(0xFF2563EB),
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _AuditLogSheet(
          entity: entity,
          entityId: entityId,
          title: title,
          entityIcon: entityIcon,
          entityColor: entityColor,
        ),
      ),
    ),
  );
}

class _AuditLogSheet extends ConsumerStatefulWidget {
  final String entity;
  final int entityId;
  final String title;
  final IconData entityIcon;
  final Color entityColor;

  const _AuditLogSheet({
    required this.entity,
    required this.entityId,
    required this.title,
    required this.entityIcon,
    required this.entityColor,
  });

  @override
  ConsumerState<_AuditLogSheet> createState() => _AuditLogSheetState();
}

class _AuditLogSheetState extends ConsumerState<_AuditLogSheet> {
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final ok = await ref.read(auditLogsProvider.notifier).load(
          entity: widget.entity,
          entityId: widget.entityId,
        );
    if (mounted) {
      setState(() {
        _loading = false;
        _failed = !ok;
      });
    }
  }

  AuditLog? _creator(List<AuditLog> logs) {
    for (final log in logs) {
      if (log.action == 'create') return log;
    }
    return null;
  }

  AuditLog? _lastModifier(List<AuditLog> logs) {
    for (final log in logs) {
      if (log.action == 'update' || log.action == 'status_change') {
        return log;
      }
    }
    return null;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(auditLogsProvider);
    final creator = _creator(logs);
    final lastModifier = _lastModifier(logs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.entityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.entityIcon,
                    size: 20, color: widget.entityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHO DID THIS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D26),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: Color(0xFF2563EB)),
                onPressed: _load,
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: _loading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _failed
                  ? _buildErrorState()
                  : (creator == null && lastModifier == null)
                      ? _buildEmptyState()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (creator != null) _buildPersonCard('Created by', creator),
                            if (lastModifier != null) ...[
                              const SizedBox(height: 10),
                              _buildPersonCard('Last modified by', lastModifier),
                            ],
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(String label, AuditLog log) {
    final name = log.userName.trim();
    final displayName = name.isNotEmpty ? name : 'Unknown user';
    final accent = label == 'Created by'
        ? widget.entityColor
        : const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initials(displayName),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (log.employeeId.isNotEmpty) log.employeeId,
                    DateFormat('MMM d, yyyy · h:mm a')
                        .format(log.createdAt.toLocal()),
                  ].join('  ·  '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.entityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.history_rounded,
                size: 22, color: widget.entityColor),
          ),
          const SizedBox(height: 12),
          Text(
            'No activity record',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This item was created before activity logging began',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 22, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 12),
          Text(
            "Couldn't load activity",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure the API server is running, then tap refresh',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
