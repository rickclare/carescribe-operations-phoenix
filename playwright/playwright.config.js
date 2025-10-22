/** @type {import('@playwright/test').PlaywrightTestConfig} */
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  // Look for test files in the "tests" directory, relative to this configuration file.
  testDir: "./tests",
  outputDir: "./test-results",
  snapshotDir: "./snapshots",
  snapshotPathTemplate: "{snapshotDir}/{testFileDir}/{testFileName}/{arg}{-projectName}{ext}",

  // Run all tests in parallel.
  fullyParallel: true,

  // Fail the build on CI if you accidentally left test.only in the source code.
  forbidOnly: !!process.env.CI,

  // Retry on CI only.
  retries: process.env.CI ? 2 : 0,

  // Opt out of parallel tests on CI.
  workers: process.env.CI ? 1 : undefined,

  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: process.env.CI ? [["github"], ["html", { outputFolder: "./report" }]] : "dot",

  /* Maximum time one test can run for. */
  timeout: 30 * 1000,

  expect: {
    /**
     * Maximum time expect() should wait for the condition to be met.
     * For example in `await expect(locator).toHaveText();`
     */
    timeout: 3000,
  },
  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    baseURL: "https://127.0.0.1:4444",
    headless: true,
    ignoreHTTPSErrors: true,
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: "on-first-retry",
    video: "on-first-retry",
    screenshot: "only-on-failure",
    // contextOptions: { recordVideo: { dir: "playwright/test-results/videos/" } },

    //// NOTE: When slowMo is enabled, the expect.timeout config setting will need to be increased
    // launchOptions: { slowMo: 1000 }
  },
  // Configure projects for major browsers.
  projects: [
    {
      name: "webkit",
      grepInvert: /Mobile browsers|Chromium only/,
      use: {
        ...devices["Desktop Safari"],
      },
    },
    {
      name: "chromium",
      grepInvert: /Mobile browsers/,
      use: {
        ...devices["Desktop Chrome"],
      },
    },
    {
      name: "firefox",
      grepInvert: /Mobile browsers|Chromium only/,
      use: {
        ...devices["Desktop Firefox"],
      },
    },
    {
      name: "mobile-safari",
      grepInvert: /Desktop browsers|Chromium only/,
      use: {
        ...devices["iPhone 15"],
      },
    },
  ],
  // Run your local dev server before starting the tests.
  webServer: {
    command: "cd .. && mix do playwright.prepare + phx.server",
    port: 4444,
    reuseExistingServer: !process.env.CI,
    ignoreHTTPSErrors: true,
    env: { MIX_ENV: "e2e" },
  },
});
