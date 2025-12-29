# Check if cache store supports atomic unless_exist operation
# This is critical for spam prevention to work correctly

Rails.application.config.after_initialize do
  # Only check in production-like environments
  if Rails.env.production? || ENV["CHECK_CACHE_ATOMIC"].present?
    # When explicitly requested, also print to STDOUT/STDERR so rails runner/CI can see it
    print_to_stdout = lambda do |level, msg|
      next unless ENV["CHECK_CACHE_ATOMIC"].present?

      io = (level == :error ? $stderr : $stdout)
      io.puts(msg)
      io.flush
    end

    begin
      # Test atomic unless_exist behavior
      test_key = "atomic_check:#{SecureRandom.hex(4)}"

      # First write should succeed
      first_write = Rails.cache.write(test_key, 1, expires_in: 10.seconds, unless_exist: true)

      # Second write should fail (key already exists)
      second_write = Rails.cache.write(test_key, 2, expires_in: 10.seconds, unless_exist: true)

      # Read to verify value
      value = Rails.cache.read(test_key)

      # Clean up
      Rails.cache.delete(test_key)

      if first_write && !second_write && value == 1
        msg = "[Cache Check] ✅ Cache store supports unless_exist semantics (#{Rails.cache.class}) - single-process verified"
        Rails.logger.info(msg)
        print_to_stdout.call(:info, msg)
      else
        msg1 = "[Cache Check] ⚠️ Cache store does NOT support unless_exist semantics!"
        msg2 = "[Cache Check] Results: first_write=#{first_write}, second_write=#{second_write}, value=#{value}"
        msg3 = "[Cache Check] This may cause race conditions in spam prevention!"

        Rails.logger.error(msg1)
        Rails.logger.error(msg2)
        Rails.logger.error(msg3)

        print_to_stdout.call(:error, msg1)
        print_to_stdout.call(:error, msg2)
        print_to_stdout.call(:error, msg3)

        if Rails.env.production?
          msg4 = "[Cache Check] CRITICAL: Spam prevention may not work correctly without proper unless_exist support!"
          Rails.logger.error(msg4)
          print_to_stdout.call(:error, msg4)
        end
      end
    rescue => e
      msg = "[Cache Check] Failed to verify cache unless_exist behavior: #{e.class}: #{e.message}"
      Rails.logger.error(msg)
      print_to_stdout.call(:error, msg)
    end
  end
end