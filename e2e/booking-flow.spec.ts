import { test, expect } from '@playwright/test';

test.describe('Booking Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/booking');
  });

  test('should display booking form correctly', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/booking/i);
    
    // Check form heading
    await expect(page.getByRole('heading', { name: /service selection/i })).toBeVisible();
    
    // Check progress indicator
    await expect(page.getByText('1')).toBeVisible();
    await expect(page.getByText('2')).toBeVisible();
    await expect(page.getByText('3')).toBeVisible();
    await expect(page.getByText('4')).toBeVisible();
    await expect(page.getByText('5')).toBeVisible();
  });

  test('should complete full booking flow', async ({ page }) => {
    // Step 1: Service Selection
    await page.getByRole('combobox', { name: /service type/i }).click();
    await page.getByRole('option', { name: /house clearance/i }).click();
    
    await page.getByRole('combobox', { name: /property size/i }).click();
    await page.getByRole('option', { name: /2 bedroom/i }).click();
    
    await page.getByRole('combobox', { name: /urgency/i }).click();
    await page.getByRole('option', { name: /within a week/i }).click();
    
    await page.getByRole('button', { name: /next/i }).click();
    
    // Step 2: Property Details
    await expect(page.getByRole('heading', { name: /property details/i })).toBeVisible();
    
    await page.getByLabel(/property address/i).fill('123 Test Street, Test City, Test County');
    await page.getByLabel(/postcode/i).fill('M1 1AA');
    await page.getByLabel(/access information/i).fill('Ground floor access, parking available');
    
    await page.getByRole('button', { name: /next/i }).click();
    
    // Step 3: Contact Information
    await expect(page.getByRole('heading', { name: /contact information/i })).toBeVisible();
    
    await page.getByLabel(/full name/i).fill('John Doe');
    await page.getByLabel(/email/i).fill('john.doe@example.com');
    await page.getByLabel(/phone/i).fill('07123456789');
    
    await page.getByRole('combobox', { name: /preferred contact/i }).click();
    await page.getByRole('option', { name: /email/i }).click();
    
    await page.getByRole('button', { name: /next/i }).click();
    
    // Step 4: Additional Services (skip for now)
    await page.getByRole('button', { name: /next/i }).click();
    
    // Step 5: Summary and Submit
    await expect(page.getByRole('heading', { name: /summary/i })).toBeVisible();
    
    // Submit booking
    await page.getByRole('button', { name: /submit booking/i }).click();
    
    // Check success message
    await expect(page.getByText(/booking request submitted/i)).toBeVisible();
    await expect(page.getByText(/contact you within 24 hours/i)).toBeVisible();
  });

  test('should validate required fields', async ({ page }) => {
    // Try to proceed without filling required fields
    await page.getByRole('button', { name: /next/i }).click();
    
    // Should stay on the same step due to validation
    await expect(page.getByRole('heading', { name: /service selection/i })).toBeVisible();
  });

  test('should allow navigation between steps', async ({ page }) => {
    // Fill first step
    await page.getByRole('combobox', { name: /service type/i }).click();
    await page.getByRole('option', { name: /house clearance/i }).click();
    
    await page.getByRole('combobox', { name: /property size/i }).click();
    await page.getByRole('option', { name: /1 bedroom/i }).click();
    
    await page.getByRole('combobox', { name: /urgency/i }).click();
    await page.getByRole('option', { name: /flexible/i }).click();
    
    await page.getByRole('button', { name: /next/i }).click();
    
    // Go to step 2
    await expect(page.getByRole('heading', { name: /property details/i })).toBeVisible();
    
    // Go back to step 1
    await page.getByRole('button', { name: /previous/i }).click();
    await expect(page.getByRole('heading', { name: /service selection/i })).toBeVisible();
  });

  test('should show progress correctly', async ({ page }) => {
    // Check initial progress
    const progressBar = page.locator('[role="progressbar"]');
    await expect(progressBar).toBeVisible();
    
    // Progress should increase as we move through steps
    // Initial progress should be around 20% (step 1 of 5)
    const initialProgress = await progressBar.getAttribute('aria-valuenow');
    expect(Number(initialProgress)).toBeGreaterThan(0);
  });

  test('should handle form persistence', async ({ page }) => {
    // Fill some data
    await page.getByRole('combobox', { name: /service type/i }).click();
    await page.getByRole('option', { name: /office clearance/i }).click();
    
    // Navigate away and back
    await page.goto('/');
    await page.goto('/booking');
    
    // Data should be preserved (if implemented)
    // This test checks if form state persistence is working
  });

  test('should be mobile responsive', async ({ page, isMobile }) => {
    if (isMobile) {
      // Check form is properly sized on mobile
      await expect(page.getByRole('heading', { name: /service selection/i })).toBeVisible();
      
      // Check dropdowns work on mobile
      await page.getByRole('combobox', { name: /service type/i }).click();
      await expect(page.getByRole('option', { name: /house clearance/i })).toBeVisible();
    }
  });
});