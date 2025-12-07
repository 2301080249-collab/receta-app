import 'package:flutter/material.dart';

class KpiCardAnimated extends StatefulWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const KpiCardAnimated({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  State<KpiCardAnimated> createState() => _KpiCardAnimatedState();
}

class _KpiCardAnimatedState extends State<KpiCardAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(KpiCardAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;
  final isTablet = screenWidth >= 600 && screenWidth < 900;

  // ✅ Tamaños adaptativos optimizados
  double iconSize;
  double iconPadding;
  double numberSize;
  double titleSize;
  double cardPadding;

  if (isMobile) {
    iconSize = 14;
    iconPadding = 4;
    numberSize = 16;
    titleSize = 8;
    cardPadding = 6;
  } else if (isTablet) {
    iconSize = 20;
    iconPadding = 8;
    numberSize = 26;
    titleSize = 13;
    cardPadding = 14;
  } else {
    iconSize = 24;
    iconPadding = 10;
    numberSize = 30;
    titleSize = 14;
    cardPadding = 20;
  }

  return MouseRegion(
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: _isHovered ? 4 : 1,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isHovered 
                ? widget.color.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            child: FittedBox( // ✅ ESTO SOLUCIONA TODO
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: isMobile ? 150 : 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: Ícono
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: iconSize,
                      ),
                    ),

                    SizedBox(height: isMobile ? 3 : 16),

                    // Número animado
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Text(
                          '${_animation.value}',
                          style: TextStyle(
                            fontSize: numberSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isMobile ? 2 : 6),

                    // Título
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: titleSize,
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Subtítulo (si existe)
                    if (widget.subtitle != null) ...[
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: isMobile ? 8 : (isTablet ? 11 : 12),
                          color: const Color(0xFF999999),
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}