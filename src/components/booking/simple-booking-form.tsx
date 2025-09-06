'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
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
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useCreateBooking } from '@/hooks/use-pocketbase';

export function SimpleBookingForm() {
  const [formData, setFormData] = useState({
    customer_name: '',
    customer_email: '',
    customer_phone: '',
    property_address: '',
    postcode: '',
    urgency: '',
    special_requirements: '',
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const { createBooking } = useCreateBooking();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    const result = await createBooking({
      ...formData,
      status: 'new',
      preferred_contact: 'email',
    });

    if (result.success) {
      setSubmitted(true);
    }
    setIsSubmitting(false);
  };

  if (submitted) {
    return (
      <Card className="max-w-md mx-auto">
        <CardContent className="pt-6 text-center">
          <h3 className="text-lg font-semibold text-green-600 mb-2">
            Booking Request Submitted!
          </h3>
          <p className="text-muted-foreground">
            We'll contact you within 24 hours with a quote.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="max-w-md mx-auto">
      <CardHeader>
        <CardTitle>Quick Quote Request</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              value={formData.customer_name}
              onChange={e =>
                setFormData({ ...formData, customer_name: e.target.value })
              }
              required
            />
          </div>

          <div>
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              value={formData.customer_email}
              onChange={e =>
                setFormData({ ...formData, customer_email: e.target.value })
              }
              required
            />
          </div>

          <div>
            <Label htmlFor="phone">Phone</Label>
            <Input
              id="phone"
              value={formData.customer_phone}
              onChange={e =>
                setFormData({ ...formData, customer_phone: e.target.value })
              }
              required
            />
          </div>

          <div>
            <Label htmlFor="address">Property Address</Label>
            <Textarea
              id="address"
              value={formData.property_address}
              onChange={e =>
                setFormData({ ...formData, property_address: e.target.value })
              }
              required
            />
          </div>

          <div>
            <Label htmlFor="postcode">Postcode</Label>
            <Input
              id="postcode"
              value={formData.postcode}
              onChange={e =>
                setFormData({ ...formData, postcode: e.target.value })
              }
              required
            />
          </div>

          <div>
            <Label htmlFor="urgency">How urgent?</Label>
            <Select
              value={formData.urgency}
              onValueChange={value =>
                setFormData({ ...formData, urgency: value })
              }
            >
              <SelectTrigger>
                <SelectValue placeholder="Select urgency" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="asap">ASAP</SelectItem>
                <SelectItem value="week">Within a week</SelectItem>
                <SelectItem value="flexible">Flexible</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label htmlFor="requirements">Special Requirements</Label>
            <Textarea
              id="requirements"
              value={formData.special_requirements}
              onChange={e =>
                setFormData({
                  ...formData,
                  special_requirements: e.target.value,
                })
              }
              placeholder="Any special requirements or items to mention..."
            />
          </div>

          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting ? 'Submitting...' : 'Request Quote'}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
