'use client';

import { SectionWrapper } from '@/components/common/section-wrapper';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
import { HelpCircle, DollarSign, Clock, Recycle, MapPin } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { useFAQs } from '@/hooks/use-pocketbase';
import Link from 'next/link';
import { CTA_BOOKING_HREF, CTA_BOOKING_LABEL } from '@/lib/constants';
import { WhatsAppButton } from '@/components/common/whatsapp-button';

const faqData = [
  {
    id: 'faq1',
    question: 'What types of items can you clear?',
    answer:
      "We can clear a wide range of items, including furniture, appliances, personal belongings, garden waste, office equipment, and builders' waste. However, there are some restrictions on hazardous materials. Please contact us if you have specific concerns.",
    icon: Recycle,
  },
  {
    id: 'faq2',
    question: 'How much does a clearance service cost?',
    answer:
      'The cost of a clearance service depends on various factors, such as the volume and type of items, an  y access restrictions, and the location. We offer a free, no-obligation quote tailored to your specific needs. Contact us to schedule a survey or discuss your requirements.',
    icon: DollarSign,
  },
  {
    id: 'faq3',
    question: 'How quickly can you provide the service?',
    answer:
      'We strive to provide a prompt service. Depending on our schedule and the size of the job, we can often arrange a clearance within a few days. For urgent requests, please call us directly to discuss availability.',
    icon: Clock,
  },
  {
    id: 'faq4',
    question: 'What areas do you cover?',
    answer:
      'ClarityClear provides services across [Your Service Area - e.g., London, Surrey, Kent]. Please check our website or contact us to confirm if we cover your specific postcode.',
    icon: MapPin,
  },
  {
    id: 'faq5',
    question: 'Do I need to be present during the clearance?',
    answer:
      "It's not always necessary for you to be present, as long as we have clear access to the items that need to be cleared and instructions are agreed upon beforehand. We can discuss arrangements that suit your schedule.",
    icon: HelpCircle,
  },
  {
    id: 'faq6',
    question: 'What happens to the items you clear?',
    answer:
      'We are committed to responsible disposal. We aim to recycle or reuse as much as possible, working with licensed recycling facilities and charities. Items that cannot be recycled or reused are disposed of ethically and legally.',
    icon: Recycle,
  },
  {
    id: 'faq7',
    question: 'Are you licensed and insured?',
    answer:
      "Yes, ClarityClear is fully licensed by the Environment Agency as a waste carrier and we hold comprehensive public liability insurance. You can have peace of mind knowing you're dealing with a professional and reputable company.",
    icon: HelpCircle,
  },
];

export default function FaqPage() {
  const { faqs, isLoading } = useFAQs();

  // Icon mapping for dynamic FAQs
  const iconMap = {
    HelpCircle: HelpCircle,
    DollarSign: DollarSign,
    Clock: Clock,
    Recycle: Recycle,
    MapPin: MapPin,
  };

  // Convert PocketBase FAQs to display format
  const dynamicFaqs = faqs.map((faq) => ({
    id: `faq-${faq.id}`,
    question: faq.question,
    answer: faq.answer,
    icon: iconMap[faq.icon_name as keyof typeof iconMap] || HelpCircle,
  }));

  // Use dynamic FAQs or fallback to static
  const displayFaqs = faqs.length > 0 ? dynamicFaqs : faqData;

  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">
            Frequently Asked Questions
          </h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto">
            Have questions? We've got answers. Find information about our
            services, processes, and more.
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper>
        <div className="max-w-3xl mx-auto">
          {isLoading ? (
            <div className="flex justify-center py-12">
              <LoadingSpinner size="lg" />
            </div>
          ) : (
            <Accordion type="single" collapsible className="w-full">
              {displayFaqs.map(faq => (
                <AccordionItem value={faq.id} key={faq.id}>
                  <AccordionTrigger className="text-left hover:no-underline">
                    <div className="flex items-center gap-3">
                      <faq.icon className="h-6 w-6 text-accent shrink-0" />
                      <span className="font-headline text-xl text-primary">
                        {faq.question}
                      </span>
                    </div>
                  </AccordionTrigger>
                  <AccordionContent className="text-base text-muted-foreground leading-relaxed pl-9">
                    {faq.answer}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          )}
        </div>
      </SectionWrapper>

      <SectionWrapper className="bg-primary text-primary-foreground">
        <div className="text-center">
          <h2 className="font-headline text-3xl font-bold mb-4">
            Can't Find Your Answer?
          </h2>
          <p className="text-lg text-primary-foreground/80 mb-6 max-w-xl mx-auto">
            If you have more questions or need specific advice, don't hesitate
            to get in touch. Our friendly team is here to help.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Button
              asChild
              size="lg"
              className="bg-accent hover:bg-accent/90 text-accent-foreground"
            >
              <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
            </Button>
            <WhatsAppButton size="lg" />
          </div>
        </div>
      </SectionWrapper>
    </>
  );
}
