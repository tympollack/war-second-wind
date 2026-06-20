abstract final class CardDimensions {
  static const heightRatio = 1.45;
  static const radiusFactor = 0.1;

  static double height(double width) => width * heightRatio;
  static double radius(double width) => width * radiusFactor;
}
