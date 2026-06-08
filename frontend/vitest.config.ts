import {defineConfig, configDefaults } from 'vitest/config'

export default defineConfig ( {
    test: {
        coverage: {
            provider: 'v8', // or 'istanbul'
            reporter: ['text', 'lcov'], // 'lcov' is mandatory for SonarCloud
            reportsDirectory: './coverage' // This maps to frontend/coverage/
        },
        environment: 'jsdom',
        exclude: [...configDefaults.exclude, '**/e2e/**'],
    }
});
