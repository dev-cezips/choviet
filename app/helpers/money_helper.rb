module MoneyHelper
  CURRENCY_SYMBOLS = { 
    "KRW" => "₩", 
    "VND" => "₫", 
    "USD" => "$" 
  }.freeze

  def format_money(amount, currency = "KRW")
    return "" if amount.nil?
    
    symbol = CURRENCY_SYMBOLS[currency.to_s] || currency.to_s
    
    # Use format without space between number and currency symbol
    number_to_currency(
      amount,
      unit: symbol,
      precision: 0,
      delimiter: ".",
      format: "%n%u"  # No space between number and unit
    )
  end

  # Alias for backward compatibility
  def money(amount, currency = "KRW")
    format_money(amount, currency)
  end
end