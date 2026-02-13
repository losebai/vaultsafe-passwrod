import 'package:flutter/material.dart';

/// 统一的密码输入框组件（TextField 版本 - 无验证）
/// 确保在所有平台（尤其是 Android）上正确隐藏密码
class PasswordFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final VoidCallback? onGeneratePassword;
  final bool enabled;
  final int? maxLines;
  final bool showVisibilityToggle;

  const PasswordFieldWidget({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixText,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.onGeneratePassword,
    this.enabled = true,
    this.maxLines = 1,
    this.showVisibilityToggle = true,
  });

  @override
  State<PasswordFieldWidget> createState() => _PasswordFieldWidgetState();
}

class _PasswordFieldWidgetState extends State<PasswordFieldWidget> {
  bool _obscureText = true;
  late bool _isMultiline;

  @override
  void initState() {
    super.initState();
    _isMultiline = widget.maxLines != null || widget.maxLines! > 1;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isMultiline ? false : _obscureText,
      obscuringCharacter: '•',
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        border: const OutlineInputBorder(),
        filled: true,
        suffixIcon: _buildSuffixIcon(),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isMultiline) {
      // 多行输入不显示切换图标
      return widget.onGeneratePassword != null
          ? IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onGeneratePassword,
              tooltip: '生成密码',
            )
          : null;
    }

    final List<Widget> icons = [];

    // 密码生成按钮
    if (widget.onGeneratePassword != null) {
      icons.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.onGeneratePassword,
          tooltip: '生成密码',
        ),
      );
    }

    // 可见性切换按钮
    if (widget.showVisibilityToggle) {
      icons.add(
        IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() => _obscureText = !_obscureText);
          },
          tooltip: '显示/隐藏密码',
        ),
      );
    }

    if (icons.isEmpty) return null;
    if (icons.length == 1) return icons.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }
}

/// 统一的密码输入框组件（TextFormField 版本 - 带验证）
/// 确保在所有平台（尤其是 Android）上正确隐藏密码
class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? prefixText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onGeneratePassword;
  final bool enabled;
  final int? maxLines;
  final bool showVisibilityToggle;
  final EdgeInsets? contentPadding;
  final Widget? prefixIcon;

  const PasswordFormField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixText,
    this.prefixIcon,
    this.autofocus = false,
    this.textInputAction,
    this.validator,
    this.onGeneratePassword,
    this.enabled = true,
    this.maxLines = 1,
    this.showVisibilityToggle = true,
    this.contentPadding,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscureText = true;
  late bool _isMultiline;

  @override
  void initState() {
    super.initState();
    _isMultiline = widget.maxLines != null || widget.maxLines! > 1;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isMultiline ? false : _obscureText,
      obscuringCharacter: '•',
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        prefixIcon: widget.prefixIcon,
        border: const OutlineInputBorder(),
        filled: true,
        contentPadding: widget.contentPadding,
        suffixIcon: _buildSuffixIcon(),
      ),
      validator: widget.validator,
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isMultiline) {
      // 多行输入不显示切换图标
      return widget.onGeneratePassword != null
          ? IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onGeneratePassword,
              tooltip: '生成密码',
            )
          : null;
    }

    final List<Widget> icons = [];

    // 密码生成按钮
    if (widget.onGeneratePassword != null) {
      icons.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.onGeneratePassword,
          tooltip: '生成密码',
        ),
      );
    }

    // 可见性切换按钮
    if (widget.showVisibilityToggle) {
      icons.add(
        IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() => _obscureText = !_obscureText);
          },
          tooltip: '显示/隐藏密码',
        ),
      );
    }

    if (icons.isEmpty) return null;
    if (icons.length == 1) return icons.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }
}
