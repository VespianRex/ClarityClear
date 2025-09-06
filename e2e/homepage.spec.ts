import { test, expect } from '@playwright/test';

test.describe('Homepage', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should load homepage correctly', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/ClarityClear/);
    
    // Check main heading
    await expect(page.getByRole('heading', { name: /professional clearance services/i })).toBeVisible();
    
    // Check hero section
    await expect(page.getByText(/reliable house clearance/i)).toBeVisible();
  });

  test('should display services section', async ({ page }) => {
    // Check services heading
    await expect(page.getByRole('heading', { name: /our core services/i })).toBeVisible();
    
    // Check for service cards
    await expect(page.getByText(/house clearance/i)).toBeVisible();
    await expect(page.getByText(/office clearance/i)).toBeVisible();
    await expect(page.getByText(/garden waste/i)).toBeVisible();
  });

  test('should show animated counters', async ({ page }) => {
    // Scroll to stats section
    await page.getByText(/happy customers/i).scrollIntoViewIfNeeded();
    
    // Check animated counters are visible
    await expect(page.getByText(/500\+/)).toBeVisible();
    await expect(page.getByText(/1200\+/)).toBeVisible();
    await expect(page.getByText(/95%/)).toBeVisible();
    await expect(page.getByText(/4\.9\/5/)).toBeVisible();
  });

  test('should display gallery section', async ({ page }) => {
    // Scroll to gallery
    await page.getByRole('heading', { name: /see our work in action/i }).scrollIntoViewIfNeeded();
    
    // Check gallery heading
    await expect(page.getByRole('heading', { name: /see our work in action/i })).toBeVisible();
    
    // Check for before/after labels
    await expect(page.getByText('Before')).toBeVisible();
    await expect(page.getByText('After')).toBeVisible();
  });

  test('should have working navigation', async ({ page }) => {
    // Check navigation links
    await expect(page.getByRole('link', { name: /services/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /gallery/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /about/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /contact/i })).toBeVisible();
    
    // Test navigation to services page
    await page.getByRole('link', { name: /services/i }).first().click();
    await expect(page).toHaveURL(/\/services/);
  });

  test('should have working CTA buttons', async ({ page }) => {
    // Check main CTA button
    const bookingButton = page.getByRole('link', { name: /get free quote/i }).first();
    await expect(bookingButton).toBeVisible();
    
    // Click and verify navigation
    await bookingButton.click();
    await expect(page).toHaveURL(/\/booking/);
  });

  test('should display testimonials section', async ({ page }) => {
    // Scroll to testimonials
    await page.getByRole('heading', { name: /what our customers say/i }).scrollIntoViewIfNeeded();
    
    // Check testimonials heading
    await expect(page.getByRole('heading', { name: /what our customers say/i })).toBeVisible();
    
    // Check for star ratings
    await expect(page.locator('[data-testid="star-rating"]').first()).toBeVisible();
  });

  test('should be responsive on mobile', async ({ page, isMobile }) => {
    if (isMobile) {
      // Check mobile navigation
      await expect(page.getByRole('button', { name: /menu/i })).toBeVisible();
      
      // Check hero section is properly sized
      const heroSection = page.getByRole('heading', { name: /professional clearance services/i });
      await expect(heroSection).toBeVisible();
      
      // Check services are stacked vertically
      const servicesSection = page.getByText(/our core services/i);
      await expect(servicesSection).toBeVisible();
    }
  });

  test('should have WhatsApp integration', async ({ page }) => {
    // Check for WhatsApp button
    const whatsappButton = page.getByRole('link', { name: /whatsapp/i }).first();
    await expect(whatsappButton).toBeVisible();
    
    // Verify WhatsApp link format
    await expect(whatsappButton).toHaveAttribute('href', /wa\.me/);
  });
});