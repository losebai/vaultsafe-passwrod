import 'package:flutter/material.dart';

class NavigationMenu extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;

  const NavigationMenu({
    Key? key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isCollapsed = false,
  }) : super(key: key);

  // 自定义颜色
  static const Color _accentColor = Color.fromARGB(255, 0, 72, 120);
  static const Color _selectedBg = Color(0xFFE8E8E8); // 淡灰色

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 选中有淡灰色背景，未选中透明
    final bgColor = isSelected ? _selectedBg : Colors.transparent;

    // 选中时使用深蓝色，未选中时使用浅灰色
    final iconColor = isSelected
        ? const Color.fromARGB(255, 0, 72, 120)
        : Colors.grey.shade400;
    final textColor = isSelected
        ? const Color.fromARGB(255, 0, 72, 120)
        : Colors.grey.shade400;
    final fontWeight =
        isSelected ? FontWeight.w600 : FontWeight.normal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _accentColor.withValues(alpha: 0.1),
        highlightColor: _accentColor.withValues(alpha: 0.05),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            // 选中时添加微妙阴影
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            // 选中时添加边框
            border: isSelected
                ? Border.all(
                    color: _accentColor.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                )
              : Row(
                  children: [
                    const SizedBox(width: 16),
                    // 图标容器
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accentColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: fontWeight,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 选中时显示指示器
                    if (isSelected) ...[
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 0, 72, 120),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}