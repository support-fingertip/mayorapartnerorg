const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config.js');

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
  setupFiles: ['<rootDir>/jest.setup.js'],
  moduleNameMapper: {
    ...(jestConfig.moduleNameMapper || {}),
    // Shared CSS-only module imported via `@import 'c/dmsTokens'`. Resolves natively
    // on-platform; this mapping lets Jest's resolver find it during unit tests.
    '^c/dmsTokens$':
      '<rootDir>/force-app/main/default/lwc/dmsTokens/dmsTokens.css',
  },
};
