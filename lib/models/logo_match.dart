class LogoMatch {
  final String brand;
  final double confidence;
  final String domain;
  final String logoUrl;

  LogoMatch({
    required this.brand,
    required this.confidence,
    required this.domain,
    required this.logoUrl,
  });

  // Factory constructor to safely convert raw map/JSON into our Dart object
  factory LogoMatch.fromJson(Map<String, dynamic> json) {
    return LogoMatch(
      brand: json['brand'] ?? 'Unknown',
      // Safely parse confidence to a double
      confidence: (json['confidence'] ?? 0).toDouble(),
      domain: json['domain'] ?? 'Unknown',
      logoUrl: json['logo_url'] ?? 'https://via.placeholder.com/150',
    );
  }
}
