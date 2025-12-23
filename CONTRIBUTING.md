# Contributing to Chợ Việt

## Development Workflow

### 1. Before Starting Work

```bash
git pull origin main
bundle install
yarn install
rails db:migrate
```

### 2. CI Simulation

Always run CI simulation before pushing:
```bash
./bin/ci
```

### 3. Git Hooks (Optional but Recommended)

Enable automatic pre-commit checks:
```bash
git config core.hooksPath .githooks
```

This will automatically run RuboCop before each commit.

To disable:
```bash
git config --unset core.hooksPath
```

### 4. Manual Pre-commit Checklist

If not using git hooks, always run:
```bash
bundle exec rubocop -a
bundle exec rubocop  # Verify "no offenses detected"
bundle exec rails test
CI=true bundle exec rails test  # CI environment test
```

## Testing Guidelines

### Regression Prevention

When fixing bugs, especially CI-related ones:
1. Fix the immediate issue
2. Add a regression test to prevent recurrence
3. Document in `CI_TROUBLESHOOTING.md` if CI-related

Example:
```ruby
# test/models/product_validation_regression_test.rb
test "non-marketplace post does not validate product fields" do
  # This prevents the CI issue from recurring
end
```

### Flaky Tests

If a test is flaky (especially system tests with JS):
1. First try to fix the timing issue
2. If not fixable, mark with skip in CI:
   ```ruby
   skip "JavaScript timing issues in CI" if ENV["CI"]
   ```
3. Document in test file header WHY it's skipped
4. Add to future improvements list

## Code Style

- Follow Rails conventions
- Use RuboCop for Ruby style
- Keep controllers thin, models thick
- Write descriptive test names in English
- UI text should be in Vietnamese (vi locale)

## Pull Request Process

1. Create feature branch from main
2. Make changes
3. Run `./bin/ci` to verify
4. Push and create PR
5. Ensure CI passes
6. Request review

## Documentation

Update relevant documentation when:
- Adding new features
- Changing deployment process
- Encountering and solving CI issues
- Making architectural decisions