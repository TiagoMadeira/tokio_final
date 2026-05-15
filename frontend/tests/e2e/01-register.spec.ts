import { test, expect } from '@playwright/test';







test.describe('Register Page', () => {
  test.beforeEach(async ({ page }) => {
     // 1. Generate the valid W3C distributed tracing context strings
    const traceId = Array.from({ length: 32 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
    const spanId = Array.from({ length: 16 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
    const traceparent = `00-${traceId}-${spanId}-01`;

    // 2. Setup the network interception wrapper FIRST.
    // This catches every single backend request the browser triggers automatically.
    await page.route('**/*', async (route) => {
        const request = route.request();
        const headers = { ...request.headers() };

        // Only inject headers if the request is destined for the API
        if (request.url().includes('/api/')) {
            headers['traceparent'] = traceparent;
            headers['tracestate'] = '';
            headers['X-B3-TraceId'] = traceId;
            headers['X-B3-SpanId'] = spanId;
            headers['X-B3-Sampled'] = '1';
        }

        // Continue the request payload downstream with the new tracking headers
        await route.continue({ headers });
    });

    // 3. Set the global page headers for the initial navigation hit
    await page.setExtraHTTPHeaders({
        'traceparent': traceparent,
        'tracestate': ''
    });
    await page.goto('/register'); // Adjust to your actual registration route
    
   
  });


  test('should register a new user successfully and redirect to login', async ({ page }) => {
    // Generate a unique username/email to avoid "User already exists" errors in the real DB
    const testUser = {
      username: `front_existing_user`,
      fullName: 'Front Existing Use',
      email: `frontexisting@example.com`,
      password: 'Password123!',
    };

    // Fill out the form
    await page.getByLabel('Username').fill(testUser.username);
    await page.getByLabel('Full Name').fill(testUser.fullName);
    await page.getByLabel('Email').fill(testUser.email);
    await page.getByLabel('Password', { exact: true }).fill(testUser.password);
    await page.getByLabel('Confirm Password').fill(testUser.password);

    // Listen for the browser alert dialog
    page.once('dialog', dialog => {
      expect(dialog.message()).toContain('Registration successful');
      dialog.dismiss().catch(() => {});
    });

    // Submit
    await page.getByRole('button', { name: 'Register' }).click();
  
    await page.waitForLoadState('networkidle'); 
    // Verify redirection to login after the 2-second timeout in your code
    await expect(page).toHaveURL(/\/login/, { timeout: 5000 });
  });

  test('should show error message from backend for duplicate registration', async ({ page }) => {
    // Use an existing user you know is already in your Minikube DB
    await page.getByLabel('Username').fill('front_existing_user');
    await page.getByLabel('Full Name').fill('Front Existing Use');
    await page.getByLabel('Email').fill('frontexisting@example.com');
    await page.getByLabel('Password', { exact: true }).fill('Password123!');
    await page.getByLabel('Confirm Password').fill('Password123!');

    await page.getByRole('button', { name: 'Register' }).click();

    await page.waitForLoadState('networkidle'); 
    // Check for the error alert displayed in your UI
    const errorAlert = page.locator('.alert-danger');
    await expect(errorAlert).toBeVisible();
    
    // This matches whatever 'detail' your backend sends (e.g., "Username already taken")
    await expect(errorAlert).not.toBeEmpty();
  });

  test('should validate required fields', async ({ page }) => {
    // Attempt to submit empty form
    await page.getByRole('button', { name: 'Register' }).click();

    await page.waitForLoadState('networkidle'); 
    // Check HTML5 validation - the browser should prevent submission
    const isUsernameInvalid = await page.$eval('#username', (el: HTMLInputElement) => !el.checkValidity());
    expect(isUsernameInvalid).toBe(true);
    
    // Ensure we didn't leave the page
    await expect(page).toHaveURL(/\/register/);
  });
});