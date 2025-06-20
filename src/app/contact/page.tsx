
import { Metadata } from 'next';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { ContactForm } from '@/components/contact/contact-form';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Mail, Phone, MapPin } from 'lucide-react';
import { APP_NAME, CONTACT_EMAIL, WHATSAPP_PHONE_NUMBER, CTA_BOOKING_HREF, CTA_BOOKING_LABEL } from '@/lib/constants';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Contact Us',
  description: `Get in touch with ${APP_NAME} for any inquiries or to request a quote.`,
};

export default function ContactPage() {
  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">Contact Us</h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto">
            We're here to help! Whether you have a question about our services, need a quote, or just want to say hello, feel free to reach out.
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper>
        <div className="grid md:grid-cols-2 gap-12 items-start">
          <div className="space-y-8">
            <div>
              <h2 className="font-headline text-3xl font-bold text-primary mb-6">Get in Touch Directly</h2>
              <div className="space-y-6">
                <a href={`mailto:${CONTACT_EMAIL}`} className="flex items-start group">
                  <Mail className="h-7 w-7 text-accent mr-4 mt-1 shrink-0" />
                  <div>
                    <h3 className="font-semibold text-primary text-xl group-hover:underline">Email Us</h3>
                    <p className="text-muted-foreground">{CONTACT_EMAIL}</p>
                    <p className="text-sm text-accent group-hover:underline">Send us an email &rarr;</p>
                  </div>
                </a>
                <a href={`https://wa.me/${WHATSAPP_PHONE_NUMBER}`} target="_blank" rel="noopener noreferrer" className="flex items-start group">
                  <Phone className="h-7 w-7 text-accent mr-4 mt-1 shrink-0" />
                  <div>
                    <h3 className="font-semibold text-primary text-xl group-hover:underline">Call or WhatsApp</h3>
                    <p className="text-muted-foreground">+{WHATSAPP_PHONE_NUMBER.slice(0,1)} ({WHATSAPP_PHONE_NUMBER.slice(1,4)}) {WHATSAPP_PHONE_NUMBER.slice(4,7)}-{WHATSAPP_PHONE_NUMBER.slice(7)}</p>
                     <p className="text-sm text-accent group-hover:underline">Chat with us on WhatsApp &rarr;</p>
                  </div>
                </a>
                 <div className="flex items-start">
                  <MapPin className="h-7 w-7 text-accent mr-4 mt-1 shrink-0" />
                  <div>
                    <h3 className="font-semibold text-primary text-xl">Our Office (By Appointment)</h3>
                    <p className="text-muted-foreground">123 Clarity Street<br />Clean City, CS 12345<br />United Kingdom</p>
                    <p className="text-sm text-muted-foreground">Please call to schedule a visit.</p>
                  </div>
                </div>
              </div>
            </div>
             <div>
                <h3 className="font-headline text-2xl font-bold text-primary mb-4">Need to Book a Collection?</h3>
                <p className="text-muted-foreground mb-4">
                    For the quickest way to get a quote and schedule your clearance, please use our online booking form.
                </p>
                <Button asChild size="lg" className="bg-primary hover:bg-primary/90 text-primary-foreground">
                    <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
                </Button>
            </div>
          </div>

          <Card className="shadow-xl">
            <CardHeader>
              <CardTitle className="font-headline text-2xl sm:text-3xl text-primary">Send Us a Message</CardTitle>
              <CardDescription>
                Fill out the form below and we'll get back to you as soon as possible.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ContactForm />
            </CardContent>
          </Card>
        </div>
      </SectionWrapper>
    </>
  );
}
