class LogoMatch {
  final String brandName;
  final double confidence;
  final String domain;
  final String logoUrl;
  final String stability;
  final String? thumbnailBase64;
  final double marginGap;
  // 🟢 ORB ADDITION: Para sa Forensic Similarity Score
  final double orbSimilarity; 
  final String? forensicBase64;

  LogoMatch({
    required this.brandName,
    required this.confidence,
    required this.domain,
    required this.logoUrl,
    required this.stability,
    this.thumbnailBase64,
    this.marginGap = 0.0,
    this.orbSimilarity = 0.0, // 🟢 Default to 0
    this.forensicBase64,
  });

  factory LogoMatch.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};
    
    // Confidence Fix
    double rawConf = (json['confidence'] as num?)?.toDouble() ?? 0.0;
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

    // Margin Gap extraction
    double gap = 0.0;
    if (metadata is Map && metadata.containsKey('margin_gap')) {
      gap = (metadata['margin_gap'] as num).toDouble();
    }

    // 🟢 ORB EXTRACTION: 
    // Dito natin kukunin yung geometric match score na galing sa forensic engine
    double orb = (json['orb_similarity'] as num?)?.toDouble() ?? 0.0;

    return LogoMatch(
      // Pilitin nating kuhanin ang brand name sa kahit anong key
      brandName: json['brand'] ?? json['Brand'] ?? metadata['brand_name'] ?? 'Unknown',
      confidence: rawConf,
      domain: json['Category'] ?? metadata['industry_domain'] ?? 'General',
      logoUrl: json['File_Path'] ?? json['image_path'] ?? '',
      stability: json['consensus'] ?? json['stability_label'] ?? 'N/A',
      thumbnailBase64: rawBase64,
      marginGap: gap,
      orbSimilarity: orb, // 🟢 I-pasa ang ORB score
      forensicBase64: json['forensic_viz'],
    );
  }
}
