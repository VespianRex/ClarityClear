import { test, expect } from '@playwright/test';

test.describe('Homepage', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should load homepage correctly', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/BestClear/);

    // Check main heading - "Effortless Clearance, Sparkling Clarity"
    await expect(page.getByRole('heading', { name: /effortless clearance/i })).toBeVisible();

    // Check hero text mentions BestClear
    await expect(page.getByText(/BestClear.*professional.*reliable.*house clearance/i)).toBeVisible();
  });

  test('should display services section', async ({ page }) => {
    // Check services heading
    await expect(page.getByRole('heading', { name: /our core services/i })).toBeVisible();

    // Check for service cards (use first() for multiple matches)
    await expect(page.getByText(/house clearance/i).first()).toBeVisible();
    await expect(page.getByText(/office clearance/i).first()).toBeVisible();
  });

  test('should show animated counters', async ({ page }) => {
    // Scroll to stats section
    await page.getByText(/happy customers/i).scrollIntoViewIfNeeded();

    // Check counters section visible (numbers may be 0 initially or animating)
    await expect(page.getByText(/happy customers/i)).toBeVisible();
    await expect(page.getByText(/jobs completed/i)).toBeVisible();
    await expect(page.getByText(/recycled waste/i)).toBeVisible();
    await expect(page.getByText(/average rating/i)).toBeVisible();
  });

  test('should display gallery section', async ({ page }) => {
    // Gallery section should be visible (may show loading spinner initially)
    const gallerySection = page.locator('#gallery');
    await expect(gallerySection).toBeVisible();

    // Either shows gallery items or loading state
    const hasContent = await page.getByText('Before').isVisible().catch(() => false);
    const hasLoading = await page.locator('.animate-spin').isVisible();

    // One of these should be true
    expect(hasContent || hasLoading).toBeTruthy();
  });

  test('should have working navigation', async ({ page }) => {
    // Check navigation links (use first() to handle multiple instances)
    await expect(page.getByRole('link', { name: /services/i }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: /gallery/i }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: /about/i }).first()).toBeVisible();
    await expect(page.getByRole('link', { name: /contact/i }).first()).toBeVisible();

    // Test navigation to services page
    await page.getByRole('link', { name: /services/i }).first().click();
    await expect(page).toHaveURL(/\/services/);
  });

  test('should have working CTA buttons', async ({ page }) => {
    // Check main CTA button - "Book a Collection"
    const bookingButton = page.getByRole('link', { name: /book a collection/i }).first();
    await expect(bookingButton).toBeVisible();

    // Click and verify navigation
    await bookingButton.click();
    await expect(page).toHaveURL(/\/booking/);
  });

  test('should display testimonials section', async ({ page }) => {
    // Check testimonials heading - "Hear From Our Happy Clients"
    await expect(page.getByRole('heading', { name: /hear from our happy clients/i })).toBeVisible();

    // Check for testimonial content
    await expect(page.getByText(/BestClear made our house move/i)).toBeVisible();
  });

  test('should be responsive on mobile', async ({ page, isMobile }) => {
    if (isMobile) {
      // Check mobile menu button
      await expect(page.getByRole('button', { name: /open mobile menu/i })).toBeVisible();

      // Check hero heading visible on mobile
      await expect(page.getByRole('heading', { name: /effortless clearance/i })).toBeVisible();

      // Check services section visible
      await expect(page.getByText(/our core services/i)).toBeVisible();
    }
  });

  test('should have WhatsApp integration', async ({ page }) => {
    // Check for WhatsApp button by aria-label or href
    const whatsappButton = page.locator('a[href*="wa.me"]').first();
    await expect(whatsappButton).toBeVisible();

    // Verify WhatsApp link format
    await expect(whatsappButton).toHaveAttribute('href', /wa\.me/);
  });
});