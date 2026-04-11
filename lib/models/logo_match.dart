class LogoMatch {
  final String brandName;
  final double confidence;
  final String domain;
  final String logoUrl;
  final String stability;
  final String? thumbnailBase64;
  final double marginGap; // <--- Siguraduhin na nandito ito

  LogoMatch({
    required this.brandName,
    required this.confidence,
    required this.domain,
    required this.logoUrl,
    required this.stability,
    this.thumbnailBase64,
    this.marginGap = 0.0, // <--- At nandito rin sa constructor
  });

  factory LogoMatch.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};
    
    // Confidence Fix
    double rawConf = (json['confidence'] as num).toDouble();
    if (rawConf > 1.0 && rawConf <= 100.0) {
      rawConf = rawConf / 100.0;
    } else if (rawConf > 100.0) {
      rawConf = rawConf / 10000.0;
    }

    // Base64 Cleaner
    String? rawBase64 = json['thumbnail_base64'];
    if (rawBase64 != null && rawBase64.contains(',')) {
      rawBase64 = rawBase64.split(',').last;
    }

    // PAGKUHA NG MARGIN GAP GALING BACKEND
    // Siguraduhin na 'margin_gap' ang key na gamit sa Python post_processor.py
    double gap = 0.0;
    if (metadata.containsKey('margin_gap')) {
      gap = (metadata['margin_gap'] as num).toDouble();
    }

    return LogoMatch(
      brandName: metadata['brand_name']?.toString() ?? 'Unknown Brand',
      confidence: rawConf,
      domain: metadata['industry_domain']?.toString() ?? 'General',
      logoUrl: json['image_path'] ?? '',
      stability: json['stability_label'] ?? 'N/A',
      thumbnailBase64: rawBase64,
      marginGap: gap, // <--- I-pasa dito
    );
  }
}
