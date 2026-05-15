import { test, expect } from '@playwright/test';

test.describe('Login Page', () => {
  test.beforeEach(async ({ page }) => {
       // 1. Generate clean W3C distributed tracking context blocks
    const traceId = Array.from({ length: 32 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
    const spanId = Array.from({ length: 16 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
    const traceparent = `00-${traceId}-${spanId}-01`;

    // 2. TARGET ONLY THE API ROUTES FOR INTERCEPTION
    // This allows HTML, JS, and CSS files to bypass the proxy cleanly, avoiding rendering loops
    await page.route('**/api/**', async (route) => {
        const request = route.request();
        const headers = { ...request.headers() };

        // Inject the required domain destination so the Ingress knows where to go
        headers['Host'] = 'frontend.staging.posts.com';

        // Append the OpenTelemetry context tracing metrics
        headers['traceparent'] = traceparent;
        headers['tracestate'] = '';
        headers['X-B3-TraceId'] = traceId;
        headers['X-B3-SpanId'] = spanId;
        headers['X-B3-Sampled'] = '1';

        await route.continue({ headers });
    });
    // 4. LAST STEP: Now navigate to your app. 
    // The initial hit and all subsequent client actions will now carry the tracking data safely.
    await page.goto('/login'); 
  });

  test('should login successfully with real backend', async ({ page }) => {
    // 1. Fill out with a REAL user that exists in your Minikube DB
    await page.getByLabel('Username').fill('front_existing_user');
    await page.getByLabel('Password').fill('Password123!');

    // 2. Submit the form
    await page.getByRole('button', { name: 'Submit' }).click();

    await page.waitForLoadState('networkidle'); 
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

    await page.waitForLoadState('networkidle'); 
    // 2. Check for the alert message returned by your FastAPI/Node backend
    const errorAlert = page.locator('.alert-danger');
    await expect(errorAlert).toBeVisible();
    
    // Check for the specific 'detail' string your real backend sends
    await expect(errorAlert).toContainText("Incorrect username or password"); 
  });
});