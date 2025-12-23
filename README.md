# Chợ Việt - Vietnamese Community Marketplace

A Rails 8.0 application for the Vietnamese community, featuring marketplace listings, community posts, and real-time messaging.

## System Requirements

* Ruby 3.3.0
* Rails 8.0.2
* SQLite3
* Redis (for ActionCable)
* ImageMagick (for image processing)

## Development Setup

### 1. Install dependencies
```bash
bundle install
yarn install
```

### 2. Database setup
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 3. Run the application
```bash
./bin/dev
```

Visit http://localhost:3000

## Testing

### Run all tests
```bash
bundle exec rails test
```

### CI Environment Simulation
To catch "works locally but fails in CI" issues:
```bash
./bin/ci
```

This runs:
- RuboCop linting
- All tests with CI environment variables

### Before committing
```bash
bundle exec rubocop -a
bundle exec rubocop  # Verify "no offenses detected"
bundle exec rails test
```

## CI/CD

- GitHub Actions runs on every push
- See `.github/workflows/ci.yml` for configuration
- Troubleshooting guide: `CI_TROUBLESHOOTING.md`

## Deployment

Using Kamal for deployment:
```bash
kamal deploy
```

## Documentation

- [CI Troubleshooting](CI_TROUBLESHOOTING.md) - CI에러 해결 가이드
- [Week 2 Finalization](WEEK2_FINALIZATION_STATUS.md) - Profile/Location 기능
- [Auth Work Summary](AUTH_WORK_SUMMARY.md) - Authentication 구현

## Known Issues

- System tests with JavaScript timing issues are skipped in CI
- See `CI_TROUBLESHOOTING.md` for details and future improvements