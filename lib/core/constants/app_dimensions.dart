import 'package:flutter/material.dart';

class AppDimensions {
  // Padding and Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingML = 14.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;
  static const double paddingXXXL = 32.0;

  // Spacing (SizedBox heights/widths)
  static const double spacingXS = 4.0;
  static const double spacingS = 6.0;
  static const double spacingM = 8.0;
  static const double spacingML = 10.0;
  static const double spacingL = 12.0;
  static const double spacingXL = 16.0;
  static const double spacingXXL = 20.0;
  static const double spacingXXXL = 24.0;
  static const double spacingXXXXL = 30.0;
  static const double spacingHuge = 40.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusML = 14.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;
  static const double radiusXXXL = 24.0;
  static const double radiusRound = 28.0;
  static const double radiusCircle = 40.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 18.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconML = 26.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 30.0;
  static const double iconLarge = 40.0;
  static const double iconXLarge = 42.0;
  static const double iconHuge = 64.0;
  static const double iconError = 80.0;

  // Shadow/Blur Radius
  static const double shadowBlurS = 10.0;
  static const double shadowBlurM = 12.0;
  static const double shadowBlurL = 20.0;

  // Border Width
  static const double borderWidthS = 1.0;
  static const double borderWidthM = 2.0;
  static const double borderWidthL = 5.0;

  // Loader/Indicator Sizes
  static const double loaderS = 24.0;
  static const double loaderM = 36.0;

  // Container Sizes
  static const double containerS = 80.0;
  static const double containerM = 100.0;
  static const double maxWidthForm = 400.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationS = 2.0;
  static const double elevationM = 3.0;
  static const double elevationL = 4.0;
  static const double elevationXL = 6.0;
  static const double elevationXXL = 12.0;

  // Button Heights
  static const double buttonHeightS = 40.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // Card Dimensions
  static const double cardHeightS = 75.0;
  static const double cardHeightM = 140.0;
  static const double cardHeightL = 170.0;
  static const double cardHeightXL = 180.0;

  // Avatar/Profile Picture Sizes
  static const double avatarS = 40.0;
  static const double avatarM = 60.0;
  static const double avatarL = 80.0;
  static const double avatarXL = 100.0;

  // Divider
  static const double dividerHeight = 1.0;
  static const double dividerThick = 2.0;

  // Font Sizes (for consistency with AppTheme)
  static const double fontXS = 12.0;
  static const double fontS = 13.0;
  static const double fontM = 14.0;
  static const double fontML = 15.0;
  static const double fontL = 16.0;
  static const double fontXL = 17.0;
  static const double fontXXL = 18.0;
  static const double fontTitle = 24.0;
  static const double fontTitleL = 28.0;
  static const double fontDisplay = 32.0;

  // Common EdgeInsets
  static const EdgeInsets paddingAllS = EdgeInsets.all(paddingS);
  static const EdgeInsets paddingAllM = EdgeInsets.all(paddingM);
  static const EdgeInsets paddingAllL = EdgeInsets.all(paddingL);
  static const EdgeInsets paddingAllXL = EdgeInsets.all(paddingXL);

  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: paddingL);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: paddingXL);

  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: paddingS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: paddingM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: paddingL);

  // Common BorderRadius
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusML => BorderRadius.circular(radiusML);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusXXL => BorderRadius.circular(radiusXXL);
  static BorderRadius get borderRadiusXXXL => BorderRadius.circular(radiusXXXL);
  static BorderRadius get borderRadiusRound => BorderRadius.circular(radiusRound);
  static BorderRadius get borderRadiusCircle => BorderRadius.circular(radiusCircle);

  // Additional EdgeInsets
  static const EdgeInsets paddingHorizontalXXL = EdgeInsets.symmetric(horizontal: paddingXXL);
  static const EdgeInsets paddingSymmetricCard = EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0);
  static const EdgeInsets paddingSymmetricButton = EdgeInsets.symmetric(vertical: 10.0);
  static const EdgeInsets paddingContentInput = EdgeInsets.symmetric(vertical: paddingL, horizontal: paddingL);

  // Shadow Offsets
  static const Offset shadowOffsetS = Offset(0, 4);
  static const Offset shadowOffsetM = Offset(0, 8);
  static const Offset shadowOffsetL = Offset(0, 10);
}
