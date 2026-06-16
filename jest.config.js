const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config.js');

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
  setupFiles: ['<rootDir>/jest.setup.js'],
};
