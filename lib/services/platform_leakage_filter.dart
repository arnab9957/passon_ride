/// Platform Leakage Moderation Filter
/// Protects P2P Marketplace integrity by detecting and masking off-platform contact sharing
/// (phone numbers, spelled-out digits, emails, UPI handles, external payment links).
class ModerationResult {
  final bool isFlagged;
  final String originalText;
  final String sanitizedText;
  final List<String> flaggedReasons;
  final double riskScore; // 0.0 (safe) to 1.0 (high risk)

  const ModerationResult({
    required this.isFlagged,
    required this.originalText,
    required this.sanitizedText,
    required this.flaggedReasons,
    required this.riskScore,
  });
}

class PlatformLeakageFilter {
  // Regex Patterns for Platform Leakage Detection
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{10}\b|\b\d{5}[-.\s]?\d{5}\b',
    caseSensitive: false,
  );

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp _upiPaymentRegex = RegExp(
    r'\b[a-zA-Z0-9.\-_]{2,256}@(upi|paytm|okaxis|okhdfcbank|oksbi|icici|ybl|gpay|phonepe)\b',
    caseSensitive: false,
  );

  static final RegExp _externalLinkRegex = RegExp(
    r'https?:\/\/[^\s]+|wa\.me\/[^\s]+|t\.me\/[^\s]+|paypal\.me\/[^\s]+|venmo\.com\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _creditCardFormRegex = RegExp(
    r'\b(?:\d[ -]*?){13,16}\b',
    caseSensitive: false,
  );

  static final RegExp _offPlatformKeywordsRegex = RegExp(
    r'\b(whatsapp|telegram|call me|text me|pay direct|gpay|phonepe|cash payment|pay offline|cash directly|credit card|pay outside|bypass fee|discount outside|bank transfer outside|wire transfer)\b',
    caseSensitive: false,
  );

  // Map of spelled-out digits to numbers
  static final Map<String, String> _wordDigitsMap = {
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9'
  };

  /// Scan input text for anti-leakage violations and return a sanitized payload
  static ModerationResult scanAndSanitize(String text) {
    if (text.trim().isEmpty) {
      return ModerationResult(
        isFlagged: false,
        originalText: text,
        sanitizedText: text,
        flaggedReasons: [],
        riskScore: 0.0,
      );
    }

    final List<String> reasons = [];
    String sanitized = text;
    double riskScore = 0.0;

    // 1. Check for Credit Card / Debit Card digits (13 to 16 digits) BEFORE 10-digit phone numbers
    if (_creditCardFormRegex.hasMatch(sanitized)) {
      reasons.add('Raw Card Number / Financial Data');
      riskScore += 0.70;
      sanitized = sanitized.replaceAll(_creditCardFormRegex, '[RESTRICTED: Card Number Masked]');
    }

    // 2. Check for standard Phone Numbers
    if (_phoneRegex.hasMatch(sanitized)) {
      reasons.add('Phone Number Sharing Attempt');
      riskScore += 0.45;
      sanitized = sanitized.replaceAll(_phoneRegex, '[RESTRICTED: Contact info removed]');
    }

    // 3. Check for Spelled-Out Digits (e.g. "nine eight seven six...")
    final String normalizedWordText = _normalizeSpelledOutDigits(text);
    if (_phoneRegex.hasMatch(normalizedWordText) && !_phoneRegex.hasMatch(text)) {
      reasons.add('Obfuscated Spelled-out Phone Number');
      riskScore += 0.50;
      sanitized = '[RESTRICTED: Obfuscated contact info detected]';
    }

    // 4. Check for Email Addresses
    if (_emailRegex.hasMatch(sanitized)) {
      reasons.add('Direct Email Address Sharing');
      riskScore += 0.35;
      sanitized = sanitized.replaceAll(_emailRegex, '[RESTRICTED: Email address removed]');
    }

    // 5. Check for UPI / Off-platform Payment IDs
    if (_upiPaymentRegex.hasMatch(sanitized)) {
      reasons.add('Direct UPI/Off-platform Payment Handle');
      riskScore += 0.60;
      sanitized = sanitized.replaceAll(_upiPaymentRegex, '[RESTRICTED: Off-platform payment handle removed]');
    }

    // 6. Check for External Links & Messaging Services
    if (_externalLinkRegex.hasMatch(sanitized)) {
      reasons.add('External Social / Communication Link');
      riskScore += 0.40;
      sanitized = sanitized.replaceAll(_externalLinkRegex, '[RESTRICTED: External link removed]');
    }

    // 7. Check for Off-Platform Bypassing Intent Keywords
    if (_offPlatformKeywordsRegex.hasMatch(sanitized)) {
      reasons.add('Off-Platform Transaction Language');
      riskScore += 0.30;
    }

    final bool isFlagged = reasons.isNotEmpty;
    final double finalRiskScore = riskScore.clamp(0.0, 1.0);

    return ModerationResult(
      isFlagged: isFlagged,
      originalText: text,
      sanitizedText: sanitized,
      flaggedReasons: reasons,
      riskScore: finalRiskScore,
    );
  }

  /// Converts spelled-out digit words to numeric string for pattern scanning
  static String _normalizeSpelledOutDigits(String input) {
    String lower = input.toLowerCase();
    _wordDigitsMap.forEach((word, digit) {
      lower = lower.replaceAll(word, digit);
    });
    // Remove non-digit characters to check if 10 consecutive digits were spelled out
    return lower.replaceAll(RegExp(r'\D'), '');
  }
}
