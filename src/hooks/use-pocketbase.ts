'use client';

import useSWR from 'swr';
import { pocketbaseHelpers } from '@/lib/pocketbase';

// Custom hook for services
export function useServices() {
  const { data, error, isLoading } = useSWR(
    'services',
    pocketbaseHelpers.getServices
  );

  return {
    services: data || [],
    isLoading,
    error,
  };
}

// Custom hook for single service
export function useService(id: string) {
  const { data, error, isLoading } = useSWR(id ? `service-${id}` : null, () =>
    pocketbaseHelpers.getService(id)
  );

  return {
    service: data,
    isLoading,
    error,
  };
}

// Custom hook for testimonials
export function useTestimonials(limit = 10) {
  const { data, error, isLoading } = useSWR(`testimonials-${limit}`, () =>
    pocketbaseHelpers.getTestimonials(limit)
  );

  return {
    testimonials: data || [],
    isLoading,
    error,
  };
}

// Custom hook for featured testimonials
export function useFeaturedTestimonials() {
  const { data, error, isLoading } = useSWR(
    'featured-testimonials',
    pocketbaseHelpers.getFeaturedTestimonials
  );

  return {
    testimonials: data || [],
    isLoading,
    error,
  };
}

// Custom hook for FAQs
export function useFAQs(category?: string) {
  const { data, error, isLoading } = useSWR(
    category ? `faqs-${category}` : 'faqs',
    () => pocketbaseHelpers.getFAQs(category)
  );

  return {
    faqs: data || [],
    isLoading,
    error,
  };
}

// Custom hook for articles
export function useArticles(limit = 10) {
  const { data, error, isLoading } = useSWR(`articles-${limit}`, () =>
    pocketbaseHelpers.getArticles(limit)
  );

  return {
    articles: data || [],
    isLoading,
    error,
  };
}

// Custom hook for single article
export function useArticle(slug: string) {
  const { data, error, isLoading } = useSWR(
    slug ? `article-${slug}` : null,
    () => pocketbaseHelpers.getArticle(slug)
  );

  return {
    article: data,
    isLoading,
    error,
  };
}

// Custom hook for settings
export function useSetting(key: string) {
  const { data, error, isLoading } = useSWR(`setting-${key}`, () =>
    pocketbaseHelpers.getSetting(key)
  );

  return {
    value: data,
    isLoading,
    error,
  };
}

// Custom hook for creating bookings
export function useCreateBooking() {
  const createBooking = async (bookingData: any) => {
    try {
      const booking = await pocketbaseHelpers.createBooking(bookingData);
      return { success: true, booking };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  return { createBooking };
}
