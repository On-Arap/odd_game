import 'package:flutter/material.dart';
import 'package:odd/app_string.dart';
import 'package:odd/data/auth_store.dart';
import 'package:odd/domain/display_name.dart';
import 'package:odd/game/palette.dart';
import 'package:odd/ui/game_dialog_card.dart';

Future<bool> showNicknameDialog(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => const _NicknameDialog(),
  );
  return saved == true;
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog();

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = DisplayNameRules.normalize(_controller.text);
    final invalid = DisplayNameRules.validate(name);
    if (invalid != null) {
      setState(() => _error = _label(invalid));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await const AuthStore().claimName(name);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on NicknameTakenException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppString.nicknameTaken;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppString.nicknameTaken;
        });
      }
    }
  }

  static String _label(DisplayNameError error) {
    return switch (error) {
      DisplayNameError.tooShort => AppString.nicknameTooShort,
      DisplayNameError.tooLong => AppString.nicknameTooLong,
      DisplayNameError.badChars => AppString.nicknameBadChars,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: GameDialogCard(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameDialogTitle(AppString.nicknameTitle),
              const SizedBox(height: 8),
              Text(
                AppString.nicknameHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Palette.hudMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: false,
                maxLength: DisplayNameRules.maxLength,
                enabled: !_saving,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 20,
                  color: Palette.hud,
                ),
                cursorColor: Palette.menuAccent,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF161821),
                  hintText: '___',
                  hintStyle: TextStyle(
                    color: Palette.hudMuted.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                  errorText: _error,
                  errorStyle: const TextStyle(
                    color: Color(0xFF8B1E1E),
                    fontWeight: FontWeight.w700,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Palette.menuAccent,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B1E1E)),
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              GameDialogButton(
                label: AppString.nicknameSave,
                onTap: _save,
                enabled: !_saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
