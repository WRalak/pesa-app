import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../config/env.dart';
import '../network/api_exception.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../utils/money.dart';

/// Renders an AsyncValue with consistent loading, error (with retry) and data states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry, this.loading});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: data,
      loading: () => loading ?? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => ErrorState(message: e is ApiException ? e.message : 'Something went wrong.', onRetry: onRetry),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.palette.text3),
            const SizedBox(height: Space.md),
            Text(message, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
            if (onRetry != null) ...[const SizedBox(height: Space.md), TextButton(onPressed: onRetry, child: const Text('Try again'))],
          ]),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xxxl, horizontal: Space.xxl),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(Radii.lg)),
            child: Icon(icon, color: context.colors.primary, size: 30),
          ),
          const SizedBox(height: Space.lg),
          Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[const SizedBox(height: Space.xs), Text(message!, style: context.text.bodyMedium?.copyWith(color: context.palette.text2), textAlign: TextAlign.center)],
          if (action != null) ...[const SizedBox(height: Space.lg), action!],
        ]),
      );
}

/// Formats money; respects the user's "hide balances" privacy setting.
class MoneyText extends StatelessWidget {
  const MoneyText(this.money, {super.key, this.style, this.hidden = false, this.signed, this.compact = false});
  final Money money;
  final TextStyle? style;
  final bool hidden;
  final String? signed; // 'DEBIT' | 'CREDIT'
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final sign = signed == 'DEBIT' ? '−' : signed == 'CREDIT' ? '+' : '';
    final text = hidden ? '${Money.symbols[money.currency] ?? money.currency} ••••' : '$sign${money.format(compact: compact)}';
    return Text(text, style: (style ?? context.text.titleMedium)?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]), semanticsLabel: hidden ? 'Hidden amount' : text);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'SUCCESSFUL' => (context.colors.primaryContainer, context.palette.success, 'Successful'),
      'FAILED' => (PesaColors.danger.withValues(alpha: .12), PesaColors.danger, 'Failed'),
      'REVERSED' => (PesaColors.sky500.withValues(alpha: .12), PesaColors.sky500, 'Reversed'),
      'PROCESSING' => (PesaColors.gold500.withValues(alpha: .16), context.palette.warning, 'Confirming'),
      _ => (PesaColors.gold500.withValues(alpha: .16), context.palette.warning, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.sm),
        child: Row(children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)], Text(label)]),
      );
}

/// Visible on every screen outside production: sandbox data is never real money.
/// A slim strip in the status-bar area, so it never covers app-bar actions.
class SandboxBanner extends StatelessWidget {
  const SandboxBanner({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!Env.showSandboxBanner) return child;
    final top = MediaQuery.paddingOf(context).top;
    return Column(children: [
      Container(
        width: double.infinity,
        color: PesaColors.gold500,
        padding: EdgeInsets.only(top: top, bottom: 2),
        child: Semantics(
          label: 'Sandbox environment. No real money moves.',
          child: Text('${Env.env.name.toUpperCase()} · SANDBOX — NO REAL MONEY', textAlign: TextAlign.center, style: const TextStyle(color: PesaColors.navy900, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .6)),
        ),
      ),
      Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
    ]);
  }
}

/// Numeric PIN pad — custom so the system keyboard (and its suggestions/
/// clipboard) never sees the PIN.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onCompleted, this.length = 4, this.error, this.busy = false, this.biometricAction});
  final ValueChanged<String> onCompleted;
  final int length;
  final String? error;
  final bool busy;
  final VoidCallback? biometricAction;
  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';
  void clear() => setState(() => _pin = '');

  void _tap(String d) {
    if (widget.busy || _pin.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
    if (_pin.length == widget.length) {
      final p = _pin;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _pin = '');
        widget.onCompleted(p);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, Widget? child, String? semantics}) => Expanded(
          child: Semantics(
            button: true,
            label: semantics ?? label,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: onTap ?? () => _tap(label),
              child: SizedBox(height: 64, child: Center(child: child ?? Text(label, style: context.text.headlineSmall))),
            ),
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
        label: '${_pin.length} of ${widget.length} digits entered',
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 9),
              width: 16, height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? context.colors.primary : Colors.transparent, border: Border.all(color: i < _pin.length ? context.colors.primary : context.palette.text3, width: 2)),
            ),
        ]),
      ),
      SizedBox(height: 28, child: Center(child: widget.busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.error ?? '', style: context.text.bodySmall?.copyWith(color: PesaColors.danger)))),
      for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']]) Row(children: [for (final d in row) key(d)]),
      Row(children: [
        widget.biometricAction != null ? key('', onTap: widget.biometricAction, child: const Icon(Icons.fingerprint_rounded, size: 30), semantics: 'Use biometrics') : const Expanded(child: SizedBox()),
        key('0'),
        key('', onTap: () { if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1)); }, child: const Icon(Icons.backspace_outlined), semantics: 'Delete'),
      ]),
    ]);
  }
}

/// Shows an error from an API call as a snackbar.
void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Something went wrong. Please try again.'), backgroundColor: PesaColors.danger));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Card with the brand's border/radius used across screens.
class PesaCard extends StatelessWidget {
  const PesaCard({super.key, required this.child, this.padding = const EdgeInsets.all(Space.lg), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

/// Labeled progress bar (savings, budgets).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.percent, this.color, this.height = 8});
  final int percent;
  final Color? color;
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
        value: '$percent%',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (percent.clamp(0, 100)) / 100),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: height, backgroundColor: context.palette.surface2, color: color ?? (percent > 100 ? PesaColors.danger : context.colors.primary)),
          ),
        ),
      );
}

/// Convenience to read an auto-dispose future provider with pull-to-refresh.
class RefreshableList extends ConsumerWidget {
  const RefreshableList({super.key, required this.onRefresh, required this.children, this.padding});
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: padding ?? const EdgeInsets.fromLTRB(20, 8, 20, 32), children: children),
      );
}
