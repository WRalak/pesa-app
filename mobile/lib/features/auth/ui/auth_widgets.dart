import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';

/// Kenyan mobile input (+254). The dial code comes from country config so other
/// markets only need a different prefix and validator.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.dialCode = '+254',
    this.label = 'Phone number',
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String dialCode;
  final String label;
  final bool autofocus;

  static String? validate(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    final local = d.startsWith('254')
        ? d.substring(3)
        : d.startsWith('0')
        ? d.substring(1)
        : d;
    if (!RegExp(r'^[17]\d{8}$').hasMatch(local)) {
      return 'Enter a valid Kenyan mobile number';
    }
    return null;
  }

  /// Converts user input to E.164 for display; the server re-validates.
  static String toE164(String v, [String dial = '+254']) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    final local = d.startsWith('254')
        ? d.substring(3)
        : d.startsWith('0')
        ? d.substring(1)
        : d;
    return '$dial$local';
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.phone,
    autofillHints: const [AutofillHints.telephoneNumber],
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
      LengthLimitingTextInputFormatter(13),
    ],
    decoration: InputDecoration(
      labelText: label,
      hintText: '712 345 678',
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Text('🇰🇪 $dialCode', style: context.text.titleMedium),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    ),
    validator: validate,
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.newPassword = false,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool newPassword;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _obscure,
    enableSuggestions: false,
    autocorrect: false,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        tooltip: _obscure ? 'Show password' : 'Hide password',
      ),
    ),
    validator:
        widget.validator ??
        (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
  );
}

String? validateNewPassword(String? v) {
  if (v == null || v.length < 8) return 'Use at least 8 characters';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'Use letters and numbers';
  }
  return null;
}

/// 6-box OTP entry backed by a single hidden field (supports SMS autofill/paste).
class OtpField extends StatefulWidget {
  const OtpField({super.key, required this.onCompleted, this.length = 6});
  final ValueChanged<String> onCompleted;
  final int length;
  @override
  State<OtpField> createState() => OtpFieldState();
}

class OtpFieldState extends State<OtpField> {
  final _c = TextEditingController();
  final _focus = FocusNode();
  void clear() => _c.clear();

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The real input is a transparent field layered over the boxes, so it stays
    // in the accessibility tree (screen readers, SMS autofill) — unlike Opacity(0).
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < widget.length; i++)
                  Container(
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(Radii.sm + 2),
                      border: Border.all(
                        color: i == _c.text.length
                            ? PesaColors.emerald500
                            : context.palette.border,
                        width: i == _c.text.length ? 1.8 : 1,
                      ),
                    ),
                    child: Text(
                      i < _c.text.length ? _c.text[i] : '',
                      style: context.text.headlineSmall,
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: Semantics(
              label: 'Verification code',
              child: TextField(
                controller: _c,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                style: const TextStyle(color: Colors.transparent, height: 0.01),
                decoration: const InputDecoration.collapsed(hintText: '')
                    .copyWith(counterText: '', filled: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  setState(() {});
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: Space.sm),
          Text(
            subtitle!,
            style: context.text.bodyLarge?.copyWith(
              color: context.palette.text2,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Brand mark used on splash/onboarding.
class PesaLogo extends StatelessWidget {
  const PesaLogo({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: PesaColors.navy900,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = PesaColors.emerald500
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .094
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final u = s.width / 32;
    final path = Path()
      ..moveTo(10 * u, 23 * u)
      ..lineTo(10 * u, 9 * u)
      ..lineTo(17 * u, 9 * u)
      ..arcToPoint(Offset(17 * u, 19 * u), radius: Radius.circular(5 * u))
      ..lineTo(13.5 * u, 19 * u);
    c.drawPath(path, p);
    c.drawCircle(
      Offset(22.5 * u, 22.5 * u),
      2.5 * u,
      Paint()..color = PesaColors.gold500,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
