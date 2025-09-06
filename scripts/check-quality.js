#!/usr/bin/env node

/**
 * Code Quality Check Script
 * Runs all quality checks in sequence
 */

const { execSync } = require('child_process');
const chalk = require('chalk');

const checks = [
  {
    name: 'TypeScript Type Checking',
    command: 'npm run typecheck',
    description: 'Checking for type errors...'
  },
  {
    name: 'ESLint (Strict)',
    command: 'npm run lint:strict',
    description: 'Running strict linting...'
  },
  {
    name: 'Prettier Format Check',
    command: 'npm run format:check',
    description: 'Checking code formatting...'
  }
];

console.log(chalk.blue.bold('🔍 Running Code Quality Checks\n'));

let allPassed = true;

for (const check of checks) {
  console.log(chalk.yellow(`⏳ ${check.description}`));
  
  try {
    execSync(check.command, { stdio: 'pipe' });
    console.log(chalk.green(`✅ ${check.name} - PASSED\n`));
  } catch (error) {
    console.log(chalk.red(`❌ ${check.name} - FAILED`));
    console.log(chalk.red(error.stdout?.toString() || error.message));
    console.log('');
    allPassed = false;
  }
}

if (allPassed) {
  console.log(chalk.green.bold('🎉 All quality checks passed!'));
  console.log(chalk.green('Your code is ready for production.'));
} else {
  console.log(chalk.red.bold('❌ Some quality checks failed.'));
  console.log(chalk.yellow('Please fix the issues above before committing.'));
  process.exit(1);
}