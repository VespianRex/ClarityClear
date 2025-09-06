import { test, expect } from '@playwright/test';

test.describe('Gallery Page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/gallery');
  });

  test('should display gallery page correctly', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/gallery/i);
    
    // Check main heading
    await expect(page.getByRole('heading', { name: /our work gallery/i })).toBeVisible();
    
    // Check description
    await expect(page.getByText(/see the incredible transformations/i)).toBeVisible();
  });

  test('should show service filter tabs', async ({ page }) => {
    // Check filter tabs
    await expect(page.getByRole('tab', { name: /all projects/i })).toBeVisible();
    await expect(page.getByRole('tab', { name: /house clearance/i })).toBeVisible();
    await expect(page.getByRole('tab', { name: /office clearance/i })).toBeVisible();
    await expect(page.getByRole('tab', { name: /garden clearance/i })).toBeVisible();
  });

  test('should filter gallery items by service type', async ({ page }) => {
    // Click on house clearance filter
    await page.getByRole('tab', { name: /house clearance/i }).click();
    
    // Check that the tab is active
    await expect(page.getByRole('tab', { name: /house clearance/i })).toHaveAttribute('data-state', 'active');
    
    // Switch to office clearance
    await page.getByRole('tab', { name: /office clearance/i }).click();
    await expect(page.getByRole('tab', { name: /office clearance/i })).toHaveAttribute('data-state', 'active');
  });

  test('should display gallery items with before/after images', async ({ page }) => {
    // Check for before/after labels
    await expect(page.getByText('Before')).toBeVisible();
    await expect(page.getByText('After')).toBeVisible();
    
    // Check for gallery item cards
    const galleryCards = page.locator('[data-testid="gallery-card"]');
    if (await galleryCards.count() > 0) {
      await expect(galleryCards.first()).toBeVisible();
    }
  });

  test('should open modal when clicking view details', async ({ page }) => {
    // Look for view details button
    const viewDetailsButton = page.getByRole('button', { name: /view details/i }).first();
    
    if (await viewDetailsButton.isVisible()) {
      await viewDetailsButton.click();
      
      // Check modal opens
      await expect(page.getByRole('dialog')).toBeVisible();
      
      // Check modal content
      await expect(page.getByText(/project details/i)).toBeVisible();
    }
  });

  test('should have interactive before/after slider in modal', async ({ page }) => {
    const viewDetailsButton = page.getByRole('button', { name: /view details/i }).first();
    
    if (await viewDetailsButton.isVisible()) {
      await viewDetailsButton.click();
      
      // Check for slider in modal
      const slider = page.getByRole('slider');
      if (await slider.isVisible()) {
        // Test slider interaction
        await slider.fill('75');
        
        // Verify slider value changed
        await expect(slider).toHaveValue('75');
      }
    }
  });

  test('should show empty state when no gallery items', async ({ page }) => {
    // If no gallery items are loaded, should show empty state
    const emptyState = page.getByText(/gallery items will appear here/i);
    const galleryItems = page.locator('[data-testid="gallery-card"]');
    
    if (await galleryItems.count() === 0) {
      await expect(emptyState).toBeVisible();
    }
  });

  test('should have working back to home button', async ({ page }) => {
    // Check back button
    const backButton = page.getByRole('link', { name: /back to home/i });
    await expect(backButton).toBeVisible();
    
    // Click and verify navigation
    await backButton.click();
    await expect(page).toHaveURL('/');
  });

  test('should display call to action section', async ({ page }) => {
    // Scroll to CTA section
    await page.getByRole('heading', { name: /ready for your own transformation/i }).scrollIntoViewIfNeeded();
    
    // Check CTA heading
    await expect(page.getByRole('heading', { name: /ready for your own transformation/i })).toBeVisible();
    
    // Check CTA buttons
    await expect(page.getByRole('link', { name: /get free quote/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /contact us/i })).toBeVisible();
  });

  test('should be responsive on mobile', async ({ page, isMobile }) => {
    if (isMobile) {
      // Check mobile layout
      await expect(page.getByRole('heading', { name: /our work gallery/i })).toBeVisible();
      
      // Check tabs are accessible on mobile
      await expect(page.getByRole('tab', { name: /all projects/i })).toBeVisible();
      
      // Check gallery grid adapts to mobile
      const galleryContainer = page.locator('[data-testid="gallery-grid"]');
      if (await galleryContainer.isVisible()) {
        // Gallery should be single column on mobile
        const boundingBox = await galleryContainer.boundingBox();
        expect(boundingBox?.width).toBeLessThan(768); // Mobile breakpoint
      }
    }
  });
});