'use client';

import useSWR from 'swr';
import pb from '@/lib/pocketbase';
import { reviewAutomation, ReviewCampaign } from '@/lib/review-automation';

// Hook for review campaigns
export function useReviewCampaigns() {
  const { data, error, isLoading, mutate } = useSWR('review-campaigns', async () => {
    return await pb.collection('review_campaigns').getFullList({
      sort: '-created',
      expand: 'booking_id'
    });
  });

  return {
    campaigns: (data as unknown as ReviewCampaign[]) || [],
    isLoading,
    error,
    refresh: mutate
  };
}

// Hook for campaign statistics
export function useReviewStats() {
  const { data, error, isLoading } = useSWR('review-stats', async () => {
    const campaigns = await pb.collection('review_campaigns').getFullList();
    
    const stats = {
      totalCampaigns: campaigns.length,
      reviewRequestsSent: campaigns.filter(c => c.review_request_sent).length,
      reviewsReceived: campaigns.filter(c => c.review_received).length,
      averageRating: 0,
      responseRate: 0,
      platformBreakdown: {
        google: 0,
        facebook: 0,
        website: 0,
        trustpilot: 0
      }
    };

    const reviewsWithRating = campaigns.filter(c => c.review_received && c.review_rating);
    if (reviewsWithRating.length > 0) {
      stats.averageRating = reviewsWithRating.reduce((sum, c) => sum + (c.review_rating || 0), 0) / reviewsWithRating.length;
    }

    if (stats.reviewRequestsSent > 0) {
      stats.responseRate = (stats.reviewsReceived / stats.reviewRequestsSent) * 100;
    }

    // Platform breakdown
    campaigns.forEach(c => {
      if (c.review_received && c.review_platform) {
        stats.platformBreakdown[c.review_platform as keyof typeof stats.platformBreakdown]++;
      }
    });

    return stats;
  });

  return {
    stats: data || {
      totalCampaigns: 0,
      reviewRequestsSent: 0,
      reviewsReceived: 0,
      averageRating: 0,
      responseRate: 0,
      platformBreakdown: { google: 0, facebook: 0, website: 0, trustpilot: 0 }
    },
    isLoading,
    error
  };
}

// Hook for creating and managing campaigns
export function useReviewAutomation() {
  const createCampaign = async (bookingData: {
    bookingId: string;
    customerName: string;
    customerEmail: string;
    serviceType: string;
    completionDate: string;
  }) => {
    try {
      const campaign = await reviewAutomation.createReviewCampaign(bookingData);
      return { success: true, campaign };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  const sendReviewRequest = async (campaignId: string) => {
    try {
      const success = await reviewAutomation.sendInitialReviewRequest(campaignId);
      return { success };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  const markReviewReceived = async (campaignId: string, reviewData: {
    platform: 'google' | 'facebook' | 'website' | 'trustpilot';
    rating: number;
    reviewUrl?: string;
  }) => {
    try {
      const success = await reviewAutomation.markReviewReceived(campaignId, reviewData);
      return { success };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  const runAutomation = async () => {
    try {
      const results = await reviewAutomation.runDailyAutomation();
      return { success: true, results };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  };

  return {
    createCampaign,
    sendReviewRequest,
    markReviewReceived,
    runAutomation
  };
}