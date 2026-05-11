import { test, expect } from '@playwright/test';

test.describe('Login Page', () => {
  test.beforeEach(async ({ page }) => {
    // Ensure this matches your Minikube URL (e.g., http://localhost:3000)
    await page.goto('/login'); 
  });

  test('should login successfully with real backend', async ({ page }) => {
    // 1. Fill out with a REAL user that exists in your Minikube DB
    await page.getByLabel('Username').fill('existing_user');
    await page.getByLabel('Password').fill('Password123!');

    // 2. Submit the form
    await page.getByRole('button', { name: 'Submit' }).click();

    // 3. Verify redirection (Waiting for the real network response)
    await expect(page).toHaveURL(/\/posts/, { timeout: 10000 });

    // 4. Verify the real token was stored
    const token = await page.evaluate(() => localStorage.getItem('authToken'));
    expect(token).not.toBeNull();
    expect(token?.length).toBeGreaterThan(10);
    await page.context().storageState({ path: 'state.json' });
  });

  test('should display real error message from backend', async ({ page }) => {
    // 1. Submit invalid credentials to trigger a real 401/400
    await page.getByLabel('Username').fill('non_existent_user');
    await page.getByLabel('Password').fill('wrong_password');
    await page.getByRole('button', { name: 'Submit' }).click();

    // 2. Check for the alert message returned by your FastAPI/Node backend
    const errorAlert = page.locator('.alert-danger');
    await expect(errorAlert).toBeVisible();
    
    // Check for the specific 'detail' string your real backend sends
    await expect(errorAlert).toContainText("Incorrect username or password"); 
  });
});