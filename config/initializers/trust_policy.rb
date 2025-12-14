# Trust and Safety Policy Configuration
# These thresholds are used to determine risky users and enforce safety measures

TRUST_POLICY = {
  # Users with reputation below this are considered low reputation
  low_reputation_threshold: 2.5,
  
  # Minimum reviews required before allowing new trades
  min_reviews_for_trade: 1,
  
  # Number of reports that triggers automatic warning messages
  auto_warning_reports: 3
}.freeze