import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import * as aChecker from "accessibility-checker";

test("The home-page renders properly", async ({ page, browserName }) => {
  await page.goto("/");
  await expect(page).toHaveTitle("Home · CareScribe Operations");

  const header = page.locator("main header");
  await expect(header).toContainText("CareScribe Operations");
  await expect(header).toContainText("Helping us manage our business");

  if (browserName === "chromium") {
    const axeResult = await new AxeBuilder({ page }).analyze();
    expect(axeResult.violations).toEqual([]);

    const result = await aChecker.getCompliance(page, "home-page-renders");
    const report = result.report as aChecker.IBaselineReport;
    const code = aChecker.assertCompliance(report);
    expect(code, aChecker.stringifyResults(report)).toBe(aChecker.eAssertResult.PASS);

    await expect(page).toHaveScreenshot();
  }
});
