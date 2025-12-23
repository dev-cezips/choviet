# PR Creation Instructions

## Branch Information
- **Branch Name**: `auth/devise-cleanup`
- **Base Branch**: `main`
- **Status**: Already pushed to GitHub

## How to Create the PR

1. Go to: https://github.com/dev-cezips/choviet/pull/new/auth/devise-cleanup

2. Fill in the following:
   - **Title**: `Fix: Clean up Devise auth flow for safe signup/login`
   - **Description**: Copy the content from PR_DESCRIPTION.md

3. Check the following before creating PR:
   - [x] Code is ready
   - [x] Tests pass locally
   - [x] RuboCop clean
   - [x] Branch is pushed

## What We Changed
1. **app/controllers/users/registrations_controller.rb**
   - Added frozen_string_literal
   - Added module namespacing
   - Added after_sign_up_path_for methods

2. **app/controllers/users/sessions_controller.rb**
   - Added frozen_string_literal
   - Added module namespacing
   - Changed redirect to root_path

3. **test/integration/auth_signup_login_test.rb**
   - New file with 3 comprehensive tests

4. **db/seeds.rb**
   - Added `return if Rails.env.test?`

## Expected CI Result
- All auth tests should pass
- RuboCop should be clean for our files
- Some unrelated tests may fail (not our responsibility)

## After PR is Created
1. Wait for CI to run
2. If CI passes → Request review
3. If CI fails on our files → Fix and push
4. If CI fails on unrelated files → Note in PR comment

## Merge Checklist
Once PR is approved and CI passes:
1. Merge to main
2. Pull latest main locally
3. Run `bin/rails test` to verify
4. Do smoke test: signup, login, logout

## Rollback Plan
If issues arise after merge:
- Use GitHub's "Revert" button on the PR
- Or manually: `git revert <commit_sha> && git push`