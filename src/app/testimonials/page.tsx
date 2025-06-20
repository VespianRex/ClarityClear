import { Metadata } from 'next';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { TestimonialCard, type TestimonialCardProps } from '@/components/testimonials/testimonial-card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import { CTA_BOOKING_HREF, CTA_BOOKING_LABEL } from '@/lib/constants';

export const metadata: Metadata = {
  title: 'Customer Testimonials',
  description: 'Read what our satisfied customers have to say about ClarityClear\'s services.',
};

const testimonialsData: TestimonialCardProps[] = [
  {
    quote: "ClarityClear transformed our cluttered attic into a usable space again! The team was incredibly professional, efficient, and respectful of our home. Highly recommended!",
    author: "Emily Carter",
    role: "Homeowner, Brighton",
    rating: 5,
    avatarUrl: "https://placehold.co/100x100.png",
    imageHint: "smiling woman"
  },
  {
    quote: "After my parents passed, clearing their house felt like an insurmountable task. ClarityClear handled everything with such sensitivity and care. They made a difficult time much more manageable.",
    author: "David Lee",
    role: "Probate Client, London",
    rating: 5,
    avatarUrl: "https://placehold.co/100x100.png",
    imageHint: "man thinking"
  },
  {
    quote: "Our office move was seamless thanks to ClarityClear. They cleared out our old premises quickly and disposed of all unwanted IT equipment responsibly. Top-notch service!",
    author: "Sophie Chen",
    role: "Office Manager, Tech Solutions Ltd.",
    rating: 5,
    avatarUrl: "https://placehold.co/100x100.png",
    imageHint: "professional woman"
  },
  {
    quote: "The garden was completely overgrown, but ClarityClear tackled it with ease. They removed all the green waste and old shed, leaving it spotless. I'm thrilled with the result.",
    author: "Michael Brown",
    role: "Homeowner, Kent",
    rating: 4.5,
    avatarUrl: "https://placehold.co/100x100.png",
    imageHint: "man gardening"
  },
  {
    quote: "Dealing with a hoarder's property is never easy, but ClarityClear approached the situation with utmost professionalism and compassion. They were a lifesaver.",
    author: "Maria Rodriguez",
    role: "Property Manager",
    rating: 5,
    avatarUrl: "https://placehold.co/100x100.png",
    imageHint: "woman property manager"
  },
  {
    quote: "Fast, friendly, and fair pricing. I needed a quick garage clearance and they delivered. Will definitely use their services again.",
    author: "Tom Evans",
    role: "Homeowner, Surrey",
    rating: 5,
    avatarUrl: "https://placehold.co/100x100.png",
    imageHint: "man happy"
  }
];

export default function TestimonialsPage() {
  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">What Our Customers Say</h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto">
            We pride ourselves on delivering exceptional service. Here's what some of our valued clients think about their experience with ClarityClear.
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {testimonialsData.map((testimonial, index) => (
            <TestimonialCard key={index} {...testimonial} />
          ))}
        </div>
      </SectionWrapper>

      <SectionWrapper id="cta-banner" className="bg-primary text-primary-foreground">
        <div className="text-center">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold mb-6">Experience the ClarityClear Difference</h2>
          <p className="text-lg text-primary-foreground/80 mb-8 max-w-xl mx-auto">
            Join our growing list of satisfied customers. Get your free, no-obligation quote today!
          </p>
          <Button asChild size="lg" className="bg-accent hover:bg-accent/90 text-accent-foreground text-lg px-10 py-6">
            <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
          </Button>
        </div>
      </SectionWrapper>
    </>
  );
}
