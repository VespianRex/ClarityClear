import { Metadata } from 'next';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { BookingForm } from '@/components/booking/booking-form';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

export const metadata: Metadata = {
  title: 'Book a Collection',
  description: 'Get a free quote for your house clearance or collection service from ClarityClear.',
};

export default function BookingPage() {
  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">Book Your Collection</h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto">
            Fill out the form below to request a quote for our clearance services. We'll get back to you shortly!
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper>
        <Card className="max-w-3xl mx-auto shadow-xl">
          <CardHeader>
            <CardTitle className="font-headline text-2xl sm:text-3xl text-primary text-center">Collection Booking Request</CardTitle>
            <CardDescription className="text-center">
              Provide your details and we'll tailor a quote for you.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <BookingForm />
          </CardContent>
        </Card>
      </SectionWrapper>
    </>
  );
}
