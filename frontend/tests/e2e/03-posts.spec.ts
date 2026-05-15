import { test, expect } from '@playwright/test';

test.describe('Posts Management', () => {
  
    // Load the login state saved from the previous file
    test.use({ storageState: 'state.json' });

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

         // Force the Ingress domain matching criteria
        headers['Host'] = 'frontend.staging.posts.com';
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
        await page.goto('/posts');

   
    });

  test('should create, edit, and delete a post', async ({ page }) => {
    const postTitle = `E2E Test Post - ${Date.now()}`;
    const postContent = `E2E Test Post Content - ${Date.now()}`;
    const updatedTitle = `${postTitle} (Updated)`;
    const updatedContent = `${postContent} (Updated)`;

    // --- CREATE ---
    await page.getByLabel(/title/i).fill(postTitle);
    await page.getByLabel(/content/i).fill(postContent);
    await page.getByRole('button', { name: /post|create/i }).click();

    // Verify it appeared
    await expect(page.getByText(postTitle)).toBeVisible();
    await expect(page.getByText(postContent)).toBeVisible();

    // --- UPDATE ---
   const postCard = page.locator('.card', { hasText: postTitle });
    await postCard.getByRole('button', { name: /edit/i }).click();

    // 1. Wait specifically for the modal to be visible before interacting
    const modal = page.locator('.modal.show'); 
    await expect(modal).toBeVisible();

    // 2. Use specific locators and wait for them to be "editable"
    const titleInput = modal.locator('input#title');
    const contentInput = modal.locator('textarea#content');

    // Ensure the modal has loaded the existing data from React state
    await expect(titleInput).toHaveValue(postTitle);

    await titleInput.clear();
    await titleInput.fill(updatedTitle);
    
    await contentInput.clear();
    await contentInput.fill(updatedContent);

    // 3. Click the Save button
    await modal.getByRole('button', { name: /save|update/i }).click();

    await page.waitForLoadState('networkidle'); 
    // 4. Verify modal is removed
    await expect(modal).not.toBeVisible();
    await expect(page.getByText(updatedTitle)).toBeVisible();
    await expect(page.getByText(updatedContent)).toBeVisible();

    // --- DELETE ---
    // Re-locate the card using the updated title
    const updatedCard = page.locator('.card', { hasText: updatedTitle });
    
    // Handle native confirm dialog if your onDelete triggers one
    // page.once('dialog', dialog => dialog.accept());

    await updatedCard.getByRole('button', { name: /delete/i }).click();

    // Verify the card is removed from the DOM
    await expect(page.getByText(updatedTitle)).not.toBeVisible();
  });
});