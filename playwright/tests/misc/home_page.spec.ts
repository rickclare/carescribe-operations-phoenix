import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test("The home-page renders properly", async ({ page, browserName }) => {
  await page.goto("/");
  await expect(page).toHaveTitle("Home · CareScribe Operations");

  const header = page.locator("main header");
  await expect(header).toContainText("CareScribe Operations");
  await expect(header).toContainText("Helping us manage our business");

  if (browserName === "chromium") {
    const result = await new AxeBuilder({ page }).analyze();
    expect(result.violations).toEqual([]);

    await expect(page).toHaveScreenshot();
  }
});
