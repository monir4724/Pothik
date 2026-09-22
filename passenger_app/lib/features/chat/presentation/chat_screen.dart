import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/banners.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/states.dart';
import '../../rides/presentation/active_ride_controller.dart';
import '../domain/chat_message.dart';

/// In-trip chat. Optimistic send with per-message idempotency (client id),
/// failed → tap to retry, closed state when trip ends (server-enforced;
/// the UI mirrors it).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.tripId, super.key});

  final String tripId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uuid = const Uuid();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  Object? _loadError;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll as the fallback transport; realtime pushes also refresh via the
    // active ride controller's event stream in a real backend.
    _poll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final server = await ref
          .read(chatRepositoryProvider)
          .messages(widget.tripId);
      if (!mounted) return;
      // Keep local pending/failed messages that the server hasn't echoed.
      final pending = _messages.where(
        (m) =>
            m.status != ChatDeliveryStatus.sent &&
            !server.any((s) => s.clientId == m.clientId),
      );
      setState(() {
        _messages = [...server, ...pending];
        _loading = false;
        _loadError = null;
      });
      _scrollToEnd();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_messages.isEmpty) _loadError = e;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send(String text, {String? retryClientId}) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final clientId = retryClientId ?? _uuid.v4();
    final optimistic = ChatMessage(
      id: clientId,
      tripId: widget.tripId,
      sender: ChatSender.passenger,
      text: t,
      sentAt: DateTime.now().toUtc(),
      status: ChatDeliveryStatus.sending,
      clientId: clientId,
    );
    setState(() {
      _messages = [
        ..._messages.where((m) => m.clientId != clientId),
        optimistic,
      ];
    });
    _input.clear();
    _scrollToEnd();
    try {
      final sent = await ref
          .read(chatRepositoryProvider)
          .send(widget.tripId, text: t, clientId: clientId);
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.clientId == clientId) sent else m,
        ];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.clientId == clientId)
              m.copyWith(status: ChatDeliveryStatus.failed)
            else
              m,
        ];
      });
      if (e.hasServerCode(ServerErrorCodes.chatClosed)) context.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ride = ref.watch(activeRideProvider.select((s) => s.ride));
    final closed =
        ride == null || ride.id != widget.tripId || !ride.status.isTracking;
    final driverName = ride?.driver?.name ?? l.driverLabel;
    final locale = Localizations.localeOf(context).toString();

    return AppScaffold(
      title: l.chatTitle(driverName),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          if (closed)
            StatusBanner(
              message: l.chatClosedNotice,
              icon: Icons.lock_outline_rounded,
            ),
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? ErrorState(error: _loadError!, onRetry: _load)
                : _messages.isEmpty
                ? EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: l.chatEmpty,
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return _Bubble(
                        message: m,
                        time: Formatters.time(
                          m.sentAt.toLocal(),
                          locale: locale,
                        ),
                        onRetry: m.status == ChatDeliveryStatus.failed
                            ? () => _send(m.text, retryClientId: m.clientId)
                            : null,
                      );
                    },
                  ),
          ),
          if (!closed) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  for (final q in [l.chatQuick1, l.chatQuick2, l.chatQuick3])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ActionChip(
                        label: Text(q),
                        onPressed: () => _send(q),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: 300,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: l.chatHint,
                          counterText: '',
                          isDense: true,
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.send_rounded,
                      semanticLabel: l.chatSend,
                      color: AppColors.amber700,
                      onPressed: () => _send(_input.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.time, this.onRetry});

  final ChatMessage message;
  final String time;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mine = message.sender == ChatSender.passenger;
    final failed = message.status == ChatDeliveryStatus.failed;
    final sending = message.status == ChatDeliveryStatus.sending;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: GestureDetector(
          onTap: onRetry,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: failed
                  ? AppColors.dangerSurface
                  : mine
                  ? AppColors.amber100
                  : AppColors.neutral100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.lg),
                topRight: const Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(mine ? AppRadius.lg : 4),
                bottomRight: Radius.circular(mine ? 4 : AppRadius.lg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.text, style: AppTypography.body),
                const SizedBox(height: 2),
                Text(
                  failed
                      ? l.chatFailedTap
                      : sending
                      ? '…'
                      : time,
                  style: AppTypography.caption.copyWith(
                    color: failed ? AppColors.danger : AppColors.neutral500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
