import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading placeholder for list screens.
///
/// [itemCount] controls how many placeholder cards to show.
/// [cardHeight] controls each placeholder card's height.
/// [cardBorderRadius] controls the corner radius of each card.
class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final double cardBorderRadius;
  final EdgeInsetsGeometry padding;

  const ShimmerLoading({
    super.key,
    this.itemCount = 3,
    this.cardHeight = 120,
    this.cardBorderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardBorderRadius),
            ),
          );
        },
      ),
    );
  }
}
