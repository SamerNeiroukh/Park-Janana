import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActionButton {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class ActionButtonGridPager extends StatefulWidget {
  final List<ActionButton> buttons;

  const ActionButtonGridPager({super.key, required this.buttons});

  @override
  State<ActionButtonGridPager> createState() => _ActionButtonGridPagerState();
}

class _ActionButtonGridPagerState extends State<ActionButtonGridPager> {
  int _currentPage = 0;
  final PageController _controller = PageController(viewportFraction: 0.98, initialPage: 0);

  @override
  Widget build(BuildContext context) {
    final List<List<ActionButton>> pages = [];
    for (int i = 0; i < widget.buttons.length; i += 4) {
      pages.add(widget.buttons.sublist(i, (i + 4 > widget.buttons.length) ? widget.buttons.length : i + 4));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox( // ✅ replaces Expanded to avoid crash
          height: 180, // fixed height for button pager
          child: PageView.builder(
            reverse: true,
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, pageIndex) {
              final pageButtons = pages[pageIndex];
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: pageButtons.take(2).toList().reversed.toList().map((btn) => _buildTile(btn)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: pageButtons.skip(2).toList().reversed.toList().map((btn) => _buildTile(btn)).toList(),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (index) => index)
              .reversed
              .map((index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    width: _currentPage == index ? 12 : 6,
                    height: _currentPage == index ? 12 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFFE65100)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTile(ActionButton button) {
    return SizedBox(
      width: 140,
      height: 80,
      child: ElevatedButton(
        onPressed: button.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4FC3F7), // Sky blue color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          padding: const EdgeInsets.all(8),
        ),
        child: Animate(
          effects: [FadeEffect(duration: 300.ms), ScaleEffect(duration: 300.ms)],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(button.icon, color: Colors.white, size: 26),
              const SizedBox(height: 4),
              Text(
                button.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
