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
import { ArrowLeft, ArrowRight, CheckCircle } from 'lucide-react';
import { useCreateBooking } from '@/hooks/use-pocketbase';
import { sendBookingConfirmation } from '@/lib/email-service';

// Booking form schema
const bookingSchema = z.object({
  serviceType: z.string().min(1, 'Please select a service'),
  propertySize: z.string().min(1, 'Please select property size'),
  urgency: z.enum(['asap', 'week', 'flexible']),
  propertyAddress: z.string().min(10, 'Please provide full address'),
  postcode: z.string().min(5, 'Please provide valid postcode'),
  accessInfo: z.string().optional(),
  specialRequirements: z.string().optional(),
  customerName: z.string().min(2, 'Please provide your name'),
  customerEmail: z.string().email('Please provide valid email'),
  customerPhone: z.string().min(10, 'Please provide valid phone number'),
  preferredContact: z.enum(['phone', 'email', 'whatsapp']),
  bestTimeCall: z.string().optional(),
  additionalServices: z.array(z.string()).optional(),
});

type BookingFormData = z.infer<typeof bookingSchema>;

const steps = [
  {
    id: 1,
    title: 'Service Selection',
    description: 'Choose your service type',
  },
  {
    id: 2,
    title: 'Property Details',
    description: 'Tell us about your property',
  },
  { id: 3, title: 'Contact Information', description: 'How can we reach you?' },
  { id: 4, title: 'Additional Services', description: 'Any extras needed?' },
  { id: 5, title: 'Summary', description: 'Review and submit' },
];

export function BookingSteps() {
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isComplete, setIsComplete] = useState(false);
  const { createBooking } = useCreateBooking();

  const form = useForm<BookingFormData>({
    resolver: zodResolver(bookingSchema),
    defaultValues: {
      additionalServices: [],
    },
  });

  const nextStep = () => {
    if (currentStep < steps.length) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const onSubmit = async (data: BookingFormData) => {
    setIsSubmitting(true);
    try {
      const result = await createBooking({
        ...data,
        status: 'new',
      });

      if (result.success) {
        // Send email notifications
        await sendBookingConfirmation({
          customerName: data.customerName,
          customerEmail: data.customerEmail,
          serviceType: data.serviceType,
          propertyAddress: data.propertyAddress,
          urgency: data.urgency,
          bookingId: result.booking?.id || 'unknown',
        });

        setIsComplete(true);
      } else {
        console.error('Booking failed:', result.error);
      }
    } catch (error) {
      console.error('Booking error:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const progress = (currentStep / steps.length) * 100;

  if (isComplete) {
    return (
      <Card className="max-w-2xl mx-auto">
        <CardContent className="text-center py-12">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-primary mb-4">
            Booking Request Submitted!
          </h2>
          <p className="text-muted-foreground mb-6">
            Thank you for your booking request. We'll contact you within 24
            hours with a detailed quote.
          </p>
          <Button onClick={() => (window.location.href = '/')}>
            Return to Home
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Progress Bar */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          {steps.map(step => (
            <div
              key={step.id}
              className={`flex items-center ${
                step.id <= currentStep ? 'text-accent' : 'text-muted-foreground'
              }`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                  step.id <= currentStep
                    ? 'bg-accent text-accent-foreground'
                    : 'bg-muted text-muted-foreground'
                }`}
              >
                {step.id}
              </div>
              <span className="ml-2 text-sm font-medium hidden sm:block">
                {step.title}
              </span>
            </div>
          ))}
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      <form onSubmit={form.handleSubmit(onSubmit)}>
        <Card>
          <CardHeader>
            <CardTitle>{steps[currentStep - 1].title}</CardTitle>
            <p className="text-muted-foreground">
              {steps[currentStep - 1].description}
            </p>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Step 1: Service Selection */}
            {currentStep === 1 && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="serviceType">Service Type *</Label>
                  <Select
                    onValueChange={value => form.setValue('serviceType', value)}
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
                  <Label htmlFor="propertySize">Property Size *</Label>
                  <Select
                    onValueChange={value =>
                      form.setValue('propertySize', value)
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select property size" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="1-bed">1 Bedroom</SelectItem>
                      <SelectItem value="2-bed">2 Bedroom</SelectItem>
                      <SelectItem value="3-bed">3 Bedroom</SelectItem>
                      <SelectItem value="4-bed">4+ Bedroom</SelectItem>
                      <SelectItem value="commercial">Commercial</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="urgency">Urgency *</Label>
                  <Select
                    onValueChange={value =>
                      form.setValue(
                        'urgency',
                        value as 'asap' | 'week' | 'flexible'
                      )
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="When do you need this done?" />
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
            {currentStep === 2 && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="propertyAddress">Property Address *</Label>
                  <Textarea
                    {...form.register('propertyAddress')}
                    placeholder="Enter full property address"
                    rows={3}
                  />
                </div>

                <div>
                  <Label htmlFor="postcode">Postcode *</Label>
                  <Input
                    {...form.register('postcode')}
                    placeholder="e.g., M1 1AA"
                  />
                </div>

                <div>
                  <Label htmlFor="accessInfo">Access Information</Label>
                  <Textarea
                    {...form.register('accessInfo')}
                    placeholder="Any access restrictions, parking info, stairs, etc."
                    rows={3}
                  />
                </div>

                <div>
                  <Label htmlFor="specialRequirements">
                    Special Requirements
                  </Label>
                  <Textarea
                    {...form.register('specialRequirements')}
                    placeholder="Fragile items, hazardous materials, etc."
                    rows={3}
                  />
                </div>
              </div>
            )}

            {/* Step 3: Contact Information */}
            {currentStep === 3 && (
              <div className="space-y-4">
                <div>
                  <Label htmlFor="customerName">Full Name *</Label>
                  <Input
                    {...form.register('customerName')}
                    placeholder="Your full name"
                  />
                </div>

                <div>
                  <Label htmlFor="customerEmail">Email Address *</Label>
                  <Input
                    {...form.register('customerEmail')}
                    type="email"
                    placeholder="your.email@example.com"
                  />
                </div>

                <div>
                  <Label htmlFor="customerPhone">Phone Number *</Label>
                  <Input
                    {...form.register('customerPhone')}
                    placeholder="Your phone number"
                  />
                </div>

                <div>
                  <Label htmlFor="preferredContact">
                    Preferred Contact Method *
                  </Label>
                  <Select
                    onValueChange={value =>
                      form.setValue(
                        'preferredContact',
                        value as 'phone' | 'email' | 'whatsapp'
                      )
                    }
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="How should we contact you?" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="phone">Phone Call</SelectItem>
                      <SelectItem value="email">Email</SelectItem>
                      <SelectItem value="whatsapp">WhatsApp</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="bestTimeCall">Best Time to Call</Label>
                  <Input
                    {...form.register('bestTimeCall')}
                    placeholder="e.g., Weekdays 9am-5pm"
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
                disabled={currentStep === 1}
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Previous
              </Button>

              {currentStep < steps.length ? (
                <Button type="button" onClick={nextStep}>
                  Next
                  <ArrowRight className="h-4 w-4 ml-2" />
                </Button>
              ) : (
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? 'Submitting...' : 'Submit Booking'}
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      </form>
    </div>
  );
}
