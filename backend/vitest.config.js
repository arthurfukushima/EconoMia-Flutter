import { defineConfig } from 'vitest/config';

// Backend tests only — everything under backend/ is server-side JS, and the Flutter
// half of the repo starts one directory up. `flutter test` collects `*_test.dart`
// from test/ and never descends here; vitest never leaves backend/.
export default defineConfig({
  test: {
    include: ['test/**/*.test.js'],
  },
});
