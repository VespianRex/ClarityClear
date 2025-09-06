'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Star, Mail, MessageSquare, Send } from 'lucide-react';
import { useSettings } from '@/lib/settings-service';
import pb from '@/lib/pocketbase';

interface ReviewAutomationProps {
  bookingId?: string;
  customerEmail?: string;
  customerName?: string;
  serviceType?: string;
}

interface ReviewFormData {
  rating: number;
  reviewText: string;
  customerName: string;
  location: string;
}

export function ReviewAutomation({
  bookingId,
  customerEmail,
  customerName,
}: ReviewAutomationProps) {
  const [isEnabled, setIsEnabled] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [formData, setFormData] = useState<ReviewFormData>({
    rating: 0,
    reviewText: '',
    customerName: customerName || '',
    location: '',
  });

  const { getSetting } = useSettings();

  useEffect(() => {
    checkIfEnabled();
  }, []);

  const checkIfEnabled = async () => {
    const enabled = await getSetting('features.review_automation', true);
    setIsEnabled(enabled);
  };

  const sendReviewRequest = async () => {
    if (!customerEmail) return;

    // In production, this would send an email with a review link
    // Simulate sending
    await new Promise(resolve => setTimeout(resolve, 1000));
    alert('Review request sent! (Demo mode)');
  };

  const submitReview = async () => {
    if (!formData.rating || !formData.reviewText.trim()) return;

    setIsSubmitting(true);
    try {
      await pb.collection('testimonials').create({
        customer_name: formData.customerName,
        customer_initial: formData.customerName
          .split(' ')
          .map(n => n[0])
          .join('.'),
        rating: formData.rating,
        review_text: formData.reviewText,
        location: formData.location,
        date_of_service: new Date().toISOString().split('T')[0],
        approved: false, // Requires admin approval
        featured: false,
      });

      setSubmitted(true);
    } catch (error) {
      console.error('Failed to submit review:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const StarRating = ({
    rating,
    onRatingChange,
  }: {
    rating: number;
    onRatingChange: (_: number) => void;
  }) => (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map(star => (
        <button
          key={star}
          type="button"
          onClick={() => onRatingChange(star)}
          className={`p-1 ${star <= rating ? 'text-yellow-400' : 'text-gray-300'} hover:text-yellow-400 transition-colors`}
        >
          <Star className="h-6 w-6 fill-current" />
        </button>
      ))}
    </div>
  );

  if (!isEnabled) {
    return null;
  }

  if (submitted) {
    return (
      <Card>
        <CardContent className="text-center py-8">
          <div className="text-green-600 mb-4">
            <MessageSquare className="h-12 w-12 mx-auto" />
          </div>
          <h3 className="text-lg font-semibold mb-2">
            Thank you for your review!
          </h3>
          <p className="text-muted-foreground">
            Your review has been submitted and will be published after approval.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Admin: Send Review Request */}
      {bookingId && customerEmail && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Mail className="h-5 w-5 text-accent" />
              Review Request Automation
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">
                  Send review request to {customerName}
                </p>
                <p className="text-sm text-muted-foreground">{customerEmail}</p>
              </div>
              <Button onClick={sendReviewRequest}>
                <Send className="h-4 w-4 mr-2" />
                Send Request
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Customer: Review Form */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Star className="h-5 w-5 text-accent" />
            Leave a Review
          </CardTitle>
          <p className="text-sm text-muted-foreground">
            Share your experience with ClarityClear
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          {!showForm ? (
            <Button onClick={() => setShowForm(true)} className="w-full">
              Write a Review
            </Button>
          ) : (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Your Rating</Label>
                <StarRating
                  rating={formData.rating}
                  onRatingChange={rating =>
                    setFormData(prev => ({ ...prev, rating }))
                  }
                />
              </div>

              <div className="space-y-2">
                <Label>Your Name</Label>
                <Input
                  value={formData.customerName}
                  onChange={e =>
                    setFormData(prev => ({
                      ...prev,
                      customerName: e.target.value,
                    }))
                  }
                  placeholder="Your name"
                />
              </div>

              <div className="space-y-2">
                <Label>Location (Optional)</Label>
                <Input
                  value={formData.location}
                  onChange={e =>
                    setFormData(prev => ({ ...prev, location: e.target.value }))
                  }
                  placeholder="e.g., London, Manchester"
                />
              </div>

              <div className="space-y-2">
                <Label>Your Review</Label>
                <Textarea
                  value={formData.reviewText}
                  onChange={e =>
                    setFormData(prev => ({
                      ...prev,
                      reviewText: e.target.value,
                    }))
                  }
                  placeholder="Tell us about your experience..."
                  rows={4}
                />
              </div>

              <div className="flex gap-2">
                <Button
                  onClick={submitReview}
                  disabled={
                    isSubmitting ||
                    !formData.rating ||
                    !formData.reviewText.trim()
                  }
                  className="flex-1"
                >
                  {isSubmitting ? 'Submitting...' : 'Submit Review'}
                </Button>
                <Button variant="outline" onClick={() => setShowForm(false)}>
                  Cancel
                </Button>
              </div>

              <p className="text-xs text-muted-foreground">
                Reviews are moderated and will be published after approval.
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
