ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# In production, remove tapioca and sorbet from load path (development tools that shouldn't run)
if ENV["RAILS_ENV"] == "production"
  $LOAD_PATH.reject! { |path| path.include?("tapioca") || path.include?("sorbet") }
end

require "bootsnap/setup" # Speed up boot time by caching expensive operations.
