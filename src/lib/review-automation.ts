'use client';

import pb from '@/lib/pocketbase';
import { sendEmail, EmailTemplate } from '@/lib/email-service';

export interface ReviewCampaign {
  id: string;
  booking_id: string;
  customer_email: string;
  customer_name: string;
  service_type: string;
  completion_date: string;
  review_request_sent: boolean;
  review_request_date?: string;
  follow_up_sent: boolean;
  follow_up_date?: string;
  review_received: boolean;
  review_platform?: 'google' | 'facebook' | 'website' | 'trustpilot';
  review_rating?: number;
  review_url?: string;
  status: 'pending' | 'sent' | 'responded' | 'completed' | 'opted_out';
}

export interface ReviewRequestData {
  customerName: string;
  customerEmail: string;
  serviceType: string;
  completionDate: string;
  bookingId: string;
}

// Email templates for review automation
export const reviewEmailTemplates = {
  initialReviewRequest: (data: ReviewRequestData): EmailTemplate => ({
    to: data.customerEmail,
    subject: `How was your ${data.serviceType} service with ClarityClear?`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #001F3F; color: white; padding: 20px; text-align: center;">
          <h1>ClarityClear</h1>
          <h2>We'd Love Your Feedback!</h2>
        </div>
        
        <div style="padding: 30px; background: #f9f9f9;">
          <h3>Hello ${data.customerName},</h3>
          <p>Thank you for choosing ClarityClear for your ${data.serviceType} service. We hope you're delighted with the results!</p>
          
          <p>Your feedback helps us improve our services and helps other customers make informed decisions. Would you mind taking a moment to share your experience?</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <h4>Leave a Review On:</h4>
            <div style="display: flex; justify-content: center; gap: 15px; flex-wrap: wrap;">
              <a href="https://www.google.com/search?q=ClarityClear+reviews" style="background: #4285f4; color: white; padding: 12px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 5px;">
                ⭐ Google Reviews
              </a>
              <a href="https://www.facebook.com/clarityclear/reviews" style="background: #1877f2; color: white; padding: 12px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 5px;">
                👍 Facebook
              </a>
              <a href="/testimonials" style="background: #39CCCC; color: white; padding: 12px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 5px;">
                💬 Our Website
              </a>
            </div>
          </div>
          
          <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
            <h4>Quick Rating:</h4>
            <p>How would you rate our service?</p>
            <div style="text-align: center; font-size: 24px;">
              <a href="/review?rating=5&booking=${data.bookingId}" style="text-decoration: none; margin: 0 5px;">⭐⭐⭐⭐⭐</a>
              <a href="/review?rating=4&booking=${data.bookingId}" style="text-decoration: none; margin: 0 5px;">⭐⭐⭐⭐</a>
              <a href="/review?rating=3&booking=${data.bookingId}" style="text-decoration: none; margin: 0 5px;">⭐⭐⭐</a>
            </div>
          </div>
          
          <p>If you have any concerns or suggestions, please don't hesitate to contact us directly. We're always here to help!</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://wa.me/1234567890" style="background: #25d366; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px;">
              💬 WhatsApp Us
            </a>
          </div>
          
          <p>Best regards,<br>The ClarityClear Team</p>
          
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
          <p style="font-size: 12px; color: #666;">
            Service completed on: ${new Date(data.completionDate).toLocaleDateString()}<br>
            Booking reference: ${data.bookingId}<br>
            <a href="/unsubscribe?email=${data.customerEmail}" style="color: #666;">Unsubscribe from review requests</a>
          </p>
        </div>
      </div>
    `,
    text: `
      Hello ${data.customerName},
      
      Thank you for choosing ClarityClear for your ${data.serviceType} service!
      
      We'd love your feedback. Please consider leaving us a review:
      - Google Reviews: https://www.google.com/search?q=ClarityClear+reviews
      - Facebook: https://www.facebook.com/clarityclear/reviews
      - Our Website: /testimonials
      
      Your feedback helps us improve and helps other customers.
      
      Best regards,
      The ClarityClear Team
      
      Service completed: ${new Date(data.completionDate).toLocaleDateString()}
      Booking reference: ${data.bookingId}
    `
  }),

  followUpRequest: (data: ReviewRequestData): EmailTemplate => ({
    to: data.customerEmail,
    subject: `Quick reminder: Share your ClarityClear experience`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #001F3F; color: white; padding: 20px; text-align: center;">
          <h1>ClarityClear</h1>
          <h2>Just a Friendly Reminder</h2>
        </div>
        
        <div style="padding: 30px; background: #f9f9f9;">
          <h3>Hello ${data.customerName},</h3>
          <p>We hope you're still enjoying the results of your ${data.serviceType} service!</p>
          
          <p>We sent you a message last week asking for feedback, but we haven't heard back yet. No pressure at all - we just wanted to make sure you didn't miss it.</p>
          
          <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center;">
            <h4>2-Minute Review = Big Impact</h4>
            <p>Your review helps local families find reliable clearance services</p>
            <a href="https://www.google.com/search?q=ClarityClear+reviews" style="background: #39CCCC; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px;">
              ⭐ Leave Google Review
            </a>
          </div>
          
          <p>If you've already left a review, thank you so much! If you have any concerns about our service, please let us know directly so we can make it right.</p>
          
          <p>Best regards,<br>The ClarityClear Team</p>
          
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
          <p style="font-size: 12px; color: #666;">
            <a href="/unsubscribe?email=${data.customerEmail}" style="color: #666;">Unsubscribe from review requests</a>
          </p>
        </div>
      </div>
    `
  }),

  thankYouForReview: (data: ReviewRequestData & { rating: number; platform: string }): EmailTemplate => ({
    to: data.customerEmail,
    subject: `Thank you for your ${data.rating}-star review!`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #001F3F; color: white; padding: 20px; text-align: center;">
          <h1>ClarityClear</h1>
          <h2>Thank You! 🌟</h2>
        </div>
        
        <div style="padding: 30px; background: #f9f9f9;">
          <h3>Hello ${data.customerName},</h3>
          <p>Thank you so much for taking the time to leave us a ${data.rating}-star review on ${data.platform}!</p>
          
          ${data.rating >= 4 ? `
            <div style="background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <p style="margin: 0; color: #155724;">
                <strong>We're thrilled you had a great experience!</strong> Reviews like yours help other families in our community find reliable clearance services.
              </p>
            </div>
          ` : `
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <p style="margin: 0; color: #856404;">
                <strong>We appreciate your honest feedback.</strong> We'd love to discuss how we can improve. Please don't hesitate to contact us directly.
              </p>
            </div>
          `}
          
          <p>As a token of our appreciation, here's a special offer for your next service:</p>
          
          <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; border: 2px dashed #39CCCC;">
            <h4 style="color: #39CCCC; margin: 0 0 10px 0;">10% OFF Your Next Service</h4>
            <p style="margin: 0; font-size: 18px; font-weight: bold;">Use code: THANKYOU10</p>
            <p style="margin: 10px 0 0 0; font-size: 12px; color: #666;">Valid for 6 months</p>
          </div>
          
          <p>We look forward to serving you again in the future!</p>
          
          <p>Best regards,<br>The ClarityClear Team</p>
        </div>
      </div>
    `
  })
};

class ReviewAutomationService {
  // Create a new review campaign
  async createReviewCampaign(bookingData: {
    bookingId: string;
    customerName: string;
    customerEmail: string;
    serviceType: string;
    completionDate: string;
  }): Promise<ReviewCampaign> {
    const campaign = await pb.collection('review_campaigns').create({
      booking_id: bookingData.bookingId,
      customer_email: bookingData.customerEmail,
      customer_name: bookingData.customerName,
      service_type: bookingData.serviceType,
      completion_date: bookingData.completionDate,
      review_request_sent: false,
      follow_up_sent: false,
      review_received: false,
      status: 'pending'
    });

    return campaign as unknown as ReviewCampaign;
  }

  // Send initial review request
  async sendInitialReviewRequest(campaignId: string): Promise<boolean> {
    try {
      const campaign = await pb.collection('review_campaigns').getOne(campaignId) as ReviewCampaign;
      
      if (campaign.review_request_sent) {

        return false;
      }

      const emailTemplate = reviewEmailTemplates.initialReviewRequest({
        customerName: campaign.customer_name,
        customerEmail: campaign.customer_email,
        serviceType: campaign.service_type,
        completionDate: campaign.completion_date,
        bookingId: campaign.booking_id
      });

      const emailResult = await sendEmail(emailTemplate);
      
      if (emailResult.success) {
        await pb.collection('review_campaigns').update(campaignId, {
          review_request_sent: true,
          review_request_date: new Date().toISOString(),
          status: 'sent'
        });
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Failed to send review request:', error);
      return false;
    }
  }

  // Send follow-up request
  async sendFollowUpRequest(campaignId: string): Promise<boolean> {
    try {
      const campaign = await pb.collection('review_campaigns').getOne(campaignId) as ReviewCampaign;
      
      if (campaign.follow_up_sent || campaign.review_received) {
        return false;
      }

      const emailTemplate = reviewEmailTemplates.followUpRequest({
        customerName: campaign.customer_name,
        customerEmail: campaign.customer_email,
        serviceType: campaign.service_type,
        completionDate: campaign.completion_date,
        bookingId: campaign.booking_id
      });

      const emailResult = await sendEmail(emailTemplate);
      
      if (emailResult.success) {
        await pb.collection('review_campaigns').update(campaignId, {
          follow_up_sent: true,
          follow_up_date: new Date().toISOString()
        });
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Failed to send follow-up request:', error);
      return false;
    }
  }

  // Mark review as received
  async markReviewReceived(campaignId: string, reviewData: {
    platform: 'google' | 'facebook' | 'website' | 'trustpilot';
    rating: number;
    reviewUrl?: string;
  }): Promise<boolean> {
    try {
      const campaign = await pb.collection('review_campaigns').getOne(campaignId) as ReviewCampaign;
      
      await pb.collection('review_campaigns').update(campaignId, {
        review_received: true,
        review_platform: reviewData.platform,
        review_rating: reviewData.rating,
        review_url: reviewData.reviewUrl,
        status: 'completed'
      });

      // Send thank you email
      const thankYouTemplate = reviewEmailTemplates.thankYouForReview({
        customerName: campaign.customer_name,
        customerEmail: campaign.customer_email,
        serviceType: campaign.service_type,
        completionDate: campaign.completion_date,
        bookingId: campaign.booking_id,
        rating: reviewData.rating,
        platform: reviewData.platform
      });

      await sendEmail(thankYouTemplate);
      
      return true;
    } catch (error) {
      console.error('Failed to mark review as received:', error);
      return false;
    }
  }

  // Get campaigns that need follow-up (7 days after initial request)
  async getCampaignsNeedingFollowUp(): Promise<ReviewCampaign[]> {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const campaigns = await pb.collection('review_campaigns').getFullList({
      filter: `review_request_sent = true && follow_up_sent = false && review_received = false && review_request_date <= "${sevenDaysAgo.toISOString()}"`
    });

    return campaigns as unknown as ReviewCampaign[];
  }

  // Get pending campaigns (completed jobs without review requests)
  async getPendingCampaigns(): Promise<ReviewCampaign[]> {
    const campaigns = await pb.collection('review_campaigns').getFullList({
      filter: 'status = "pending"'
    });

    return campaigns as unknown as ReviewCampaign[];
  }

  // Automation runner (call this daily via cron job)
  async runDailyAutomation(): Promise<{
    reviewRequestsSent: number;
    followUpsSent: number;
    errors: string[];
  }> {
    const results = {
      reviewRequestsSent: 0,
      followUpsSent: 0,
      errors: [] as string[]
    };

    try {
      // Send initial review requests for pending campaigns
      const pendingCampaigns = await this.getPendingCampaigns();
      for (const campaign of pendingCampaigns) {
        const success = await this.sendInitialReviewRequest(campaign.id);
        if (success) {
          results.reviewRequestsSent++;
        } else {
          results.errors.push(`Failed to send review request for campaign ${campaign.id}`);
        }
      }

      // Send follow-up requests
      const followUpCampaigns = await this.getCampaignsNeedingFollowUp();
      for (const campaign of followUpCampaigns) {
        const success = await this.sendFollowUpRequest(campaign.id);
        if (success) {
          results.followUpsSent++;
        } else {
          results.errors.push(`Failed to send follow-up for campaign ${campaign.id}`);
        }
      }
    } catch (error: any) {
      results.errors.push(`Automation error: ${error.message}`);
    }

    return results;
  }
}

export const reviewAutomation = new ReviewAutomationService();