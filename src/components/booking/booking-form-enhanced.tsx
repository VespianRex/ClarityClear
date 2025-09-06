'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Progress } from '@/components/ui/progress';
import { useCreateBooking } from '@/hooks/use-pocketbase';
import { CheckCircle, ArrowLeft, ArrowRight } from 'lucide-react';

// Booking form schema
const bookingSchema = z.object({
  // Step 1: Service Selection
  service_type: z.string().min(1, 'Please select a service'),
  property_size: z.string().min(1, 'Please select property size'),
  urgency: z.enum(['asap', 'week', 'flexible']),

  // Step 2: Property Details
  property_address: z.string().min(10, 'Please provide full address'),
  postcode: z.string().min(5, 'Please provide valid postcode'),
  access_info: z.string().optional(),
  special_requirements: z.string().optional(),

  // Step 3: Contact Information
  customer_name: z.string().min(2, 'Name must be at least 2 characters'),
  customer_email: z.string().email('Please provide valid email'),
  customer_phone: z.string().min(10, 'Please provide valid phone number'),
  preferred_contact: z.enum(['phone', 'email', 'whatsapp']),
  best_time_call: z.string().optional(),

  // Step 4: Additional Services
  additional_services: z.array(z.string()).optional(),
});

type BookingFormData = z.infer<typeof bookingSchema>;

const steps = [
  { title: 'Service Selection', description: 'Choose your service type' },
  { title: 'Property Details', description: 'Tell us about your property' },
  { title: 'Contact Information', description: 'How can we reach you?' },
  { title: 'Additional Services', description: 'Any extras needed?' },
  { title: 'Summary', description: 'Review and submit' },
];

export function BookingFormEnhanced() {
  const [currentStep, setCurrentStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const { createBooking } = useCreateBooking();

  const form = useForm<BookingFormData>({
    resolver: zodResolver(bookingSchema),
    defaultValues: {
      urgency: 'flexible',
      preferred_contact: 'phone',
      additional_services: [],
    },
  });

  const nextStep = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const onSubmit = async (data: BookingFormData) => {
    setIsSubmitting(true);
    try {
      const result = await createBooking({
        ...data,
        status: 'new',
        additional_services: data.additional_services || [],
      });

      if (result.success) {
        setIsSubmitted(true);
      } else {
        console.error('Booking failed:', result.error);
      }
    } catch (error) {
      console.error('Booking error:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isSubmitted) {
    return (
      <Card className="max-w-2xl mx-auto">
        <CardContent className="pt-6 text-center">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-primary mb-2">
            Booking Request Submitted!
          </h2>
          <p className="text-muted-foreground mb-4">
            Thank you for your booking request. We'll contact you within 24
            hours with a detailed quote.
          </p>
          <Button onClick={() => window.location.reload()}>
            Submit Another Request
          </Button>
        </CardContent>
      </Card>
    );
  }

  const progress = ((currentStep + 1) / steps.length) * 100;

  return (
    <div className="max-w-4xl mx-auto">
      {/* Progress Bar */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm font-medium text-primary">
            Step {currentStep + 1} of {steps.length}
          </span>
          <span className="text-sm text-muted-foreground">
            {steps[currentStep].title}
          </span>
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-2xl font-bold text-primary">
            {steps[currentStep].title}
          </CardTitle>
          <p className="text-muted-foreground">
            {steps[currentStep].description}
          </p>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Step 1: Service Selection */}
            {currentStep === 0 && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="service_type">Service Type *</Label>
                  <Select
                    onValueChange={value =>
                      form.setValue('service_type', value)
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select a service" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="house">House Clearance</SelectItem>
                      <SelectItem value="office">Office Clearance</SelectItem>
                      <SelectItem value="garden">Garden Clearance</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="property_size">Property Size *</Label>
                  <Select
                    onValueChange={value =>
                      form.setValue('property_size', value)
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select property size" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="1-bed">1 Bedroom</SelectItem>
                      <SelectItem value="2-bed">2 Bedrooms</SelectItem>
                      <SelectItem value="3-bed">3 Bedrooms</SelectItem>
                      <SelectItem value="4-bed">4+ Bedrooms</SelectItem>
                      <SelectItem value="office-small">Small Office</SelectItem>
                      <SelectItem value="office-large">Large Office</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="urgency">How urgent is this? *</Label>
                  <Select
                    onValueChange={value =>
                      form.setValue('urgency', value as any)
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select urgency" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="asap">
                        ASAP (within 48 hours)
                      </SelectItem>
                      <SelectItem value="week">Within a week</SelectItem>
                      <SelectItem value="flexible">I'm flexible</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            )}

            {/* Step 2: Property Details */}
            {currentStep === 1 && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="property_address">
                    Full Property Address *
                  </Label>
                  <Textarea
                    {...form.register('property_address')}
                    placeholder="Please provide the complete address including street, city, and any relevant details"
                    rows={3}
                  />
                </div>

                <div>
                  <Label htmlFor="postcode">Postcode *</Label>
                  <Input
                    {...form.register('postcode')}
                    placeholder="e.g., SW1A 1AA"
                  />
                </div>

                <div>
                  <Label htmlFor="access_info">Access Information</Label>
                  <Textarea
                    {...form.register('access_info')}
                    placeholder="Any access restrictions, parking info, stairs, etc."
                    rows={2}
                  />
                </div>

                <div>
                  <Label htmlFor="special_requirements">
                    Special Requirements
                  </Label>
                  <Textarea
                    {...form.register('special_requirements')}
                    placeholder="Fragile items, hazardous materials, specific instructions, etc."
                    rows={2}
                  />
                </div>
              </div>
            )}

            {/* Step 3: Contact Information */}
            {currentStep === 2 && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="customer_name">Full Name *</Label>
                  <Input
                    {...form.register('customer_name')}
                    placeholder="Your full name"
                  />
                </div>

                <div>
                  <Label htmlFor="customer_email">Email Address *</Label>
                  <Input
                    {...form.register('customer_email')}
                    type="email"
                    placeholder="your.email@example.com"
                  />
                </div>

                <div>
                  <Label htmlFor="customer_phone">Phone Number *</Label>
                  <Input
                    {...form.register('customer_phone')}
                    placeholder="Your phone number"
                  />
                </div>

                <div>
                  <Label htmlFor="preferred_contact">
                    Preferred Contact Method *
                  </Label>
                  <Select
                    onValueChange={value =>
                      form.setValue('preferred_contact', value as any)
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="How would you like us to contact you?" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="phone">Phone Call</SelectItem>
                      <SelectItem value="email">Email</SelectItem>
                      <SelectItem value="whatsapp">WhatsApp</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="best_time_call">Best Time to Call</Label>
                  <Input
                    {...form.register('best_time_call')}
                    placeholder="e.g., Weekdays 9-5, Evenings after 6pm"
                  />
                </div>
              </div>
            )}

            {/* Navigation Buttons */}
            <div className="flex justify-between pt-6">
              <Button
                type="button"
                variant="outline"
                onClick={prevStep}
                disabled={currentStep === 0}
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Previous
              </Button>

              {currentStep < steps.length - 2 ? (
                <Button type="button" onClick={nextStep}>
                  Next
                  <ArrowRight className="h-4 w-4 ml-2" />
                </Button>
              ) : currentStep === steps.length - 2 ? (
                <Button type="button" onClick={nextStep}>
                  Review
                  <ArrowRight className="h-4 w-4 ml-2" />
                </Button>
              ) : (
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Submitting...' : 'Submit Booking Request'}
                </Button>
              )}
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
