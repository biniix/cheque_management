import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          if (title != null)
            Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D26),
                letterSpacing: -0.5,
              ),
            ),
          if (actions != null) ...[
            const Spacer(),
            ...actions!,
          ],
        ],
      ),
    );
  }
}
