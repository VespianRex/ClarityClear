'use client';

import Image from 'next/image';
import Link from 'next/link';
import { HeroSection } from '@/components/common/hero-section';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card';
import { CheckCircle, Star, MessageCircle } from 'lucide-react';
import { CTA_BOOKING_HREF, CTA_BOOKING_LABEL } from '@/lib/constants';
import { useServices, useTestimonials } from '@/hooks/use-pocketbase';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { BeforeAfterGallery } from '@/components/gallery/before-after-gallery';
import { FadeInSection } from '@/components/ui/fade-in-section';
import { AnimatedCounter } from '@/components/ui/animated-counter';

// Services will be fetched from PocketBase
const defaultServices = [
  {
    title: 'House Clearance',
    description:
      'Full or partial house clearance, including furniture, appliances, and personal belongings.',
    icon: <CheckCircle className="h-6 w-6 text-accent" />,
    image: 'https://placehold.co/300x200.png',
    imageHint: 'living room clearance',
  },
  {
    title: 'Office Clearance',
    description:
      'Efficient removal of office furniture, IT equipment, and confidential waste.',
    icon: <CheckCircle className="h-6 w-6 text-accent" />,
    image: 'https://placehold.co/300x200.png',
    imageHint: 'office workspace',
  },
  {
    title: 'Garden Waste',
    description:
      'Collection of green waste, soil, rubble, and old garden furniture.',
    icon: <CheckCircle className="h-6 w-6 text-accent" />,
    image: 'https://placehold.co/300x200.png',
    imageHint: 'garden cleanup',
  },
];

// Convert services to display format
const getDisplayServices = (services: any[]) => {
  return services.map(service => ({
    ...service,
    icon: <CheckCircle className="h-6 w-6 text-accent" />,
    image: service.image_url || 'https://placehold.co/300x200.png',
    imageHint: service.image_hint || service.title.toLowerCase(),
  }));
};

export default function HomePage() {
  const { services, isLoading: servicesLoading } = useServices();
  const { testimonials: dynamicTestimonials } = useTestimonials(3);

  // Use PocketBase data or fallback to default
  const displayServices =
    services.length > 0 ? getDisplayServices(services) : defaultServices;
  const displayTestimonials =
    dynamicTestimonials.length > 0
      ? dynamicTestimonials
      : [
          {
            customer_name: 'Sarah M.',
            review_text:
              'ClarityClear made our house move so much easier! Professional, quick, and very friendly staff.',
            rating: 5,
          },
          {
            customer_name: 'John B.',
            review_text:
              'Highly recommend their office clearance service. They handled everything with care and efficiency.',
            rating: 5,
          },
          {
            customer_name: 'Linda P.',
            review_text:
              'Fantastic job clearing out our overgrown garden. It looks like a new space now!',
            rating: 5,
          },
        ];

  return (
    <>
      <HeroSection />

      <SectionWrapper id="services-overview">
        <div className="text-center mb-12">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">
            Our Core Services
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            We offer a range of clearance services tailored to your needs,
            ensuring a smooth and stress-free experience.
          </p>
        </div>
        {servicesLoading ? (
          <div className="flex justify-center py-12">
            <LoadingSpinner size="lg" />
          </div>
        ) : (
          <div className="grid md:grid-cols-3 gap-8">
            {displayServices.map(service => (
              <Card
                key={service.title}
                className="flex flex-col overflow-hidden shadow-lg hover:shadow-xl transition-shadow duration-300"
              >
                <div className="relative h-48 w-full">
                  <Image
                    src={service.image}
                    alt={service.title}
                    layout="fill"
                    objectFit="cover"
                    data-ai-hint={service.imageHint}
                  />
                </div>
                <CardHeader>
                  <div className="flex items-center gap-3 mb-2">
                    {service.icon}
                    <CardTitle className="font-headline text-xl text-primary">
                      {service.title}
                    </CardTitle>
                  </div>
                </CardHeader>
                <CardContent className="flex-grow">
                  <CardDescription>{service.description}</CardDescription>
                </CardContent>
                <div className="p-6 pt-0">
                  <Button
                    variant="link"
                    asChild
                    className="text-accent p-0 h-auto"
                  >
                    <Link href="/services">Learn More &rarr;</Link>
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        )}
        <div className="text-center mt-12">
          <Button asChild size="lg" variant="outline">
            <Link href="/services">View All Services</Link>
          </Button>
        </div>
      </SectionWrapper>

      <SectionWrapper id="why-choose-us" className="bg-secondary">
        <FadeInSection>
          <div className="text-center mb-12">
            <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">
              Why Choose ClarityClear?
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Experience the ClarityClear difference with our commitment to
              quality, reliability, and customer satisfaction.
            </p>
          </div>
        </FadeInSection>

        <div className="grid md:grid-cols-3 gap-8 text-center">
          <FadeInSection delay={0.1}>
            <div className="p-6">
              <Star className="h-12 w-12 text-accent mx-auto mb-4" />
              <h3 className="font-headline text-xl font-semibold text-primary mb-2">
                Reliable & Trustworthy
              </h3>
              <p className="text-muted-foreground">
                Count on us for punctual, dependable, and transparent services
                every time.
              </p>
            </div>
          </FadeInSection>

          <FadeInSection delay={0.2}>
            <div className="p-6">
              <CheckCircle className="h-12 w-12 text-accent mx-auto mb-4" />
              <h3 className="font-headline text-xl font-semibold text-primary mb-2">
                Eco-Friendly Approach
              </h3>
              <p className="text-muted-foreground">
                We prioritize recycling and responsible disposal to minimize
                environmental impact.
              </p>
            </div>
          </FadeInSection>

          <FadeInSection delay={0.3}>
            <div className="p-6">
              <MessageCircle className="h-12 w-12 text-accent mx-auto mb-4" />
              <h3 className="font-headline text-xl font-semibold text-primary mb-2">
                Customer Focused
              </h3>
              <p className="text-muted-foreground">
                Your satisfaction is our top priority. We tailor our services to
                meet your specific needs.
              </p>
            </div>
          </FadeInSection>
        </div>

        {/* Stats Section */}
        <FadeInSection delay={0.4} className="mt-16">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <div>
              <AnimatedCounter
                end={500}
                suffix="+"
                className="text-3xl font-bold text-accent"
              />
              <p className="text-sm text-muted-foreground mt-2">
                Happy Customers
              </p>
            </div>
            <div>
              <AnimatedCounter
                end={1200}
                suffix="+"
                className="text-3xl font-bold text-accent"
              />
              <p className="text-sm text-muted-foreground mt-2">
                Jobs Completed
              </p>
            </div>
            <div>
              <AnimatedCounter
                end={95}
                suffix="%"
                className="text-3xl font-bold text-accent"
              />
              <p className="text-sm text-muted-foreground mt-2">
                Recycled Waste
              </p>
            </div>
            <div>
              <AnimatedCounter
                end={4.9}
                suffix="/5"
                className="text-3xl font-bold text-accent"
              />
              <p className="text-sm text-muted-foreground mt-2">
                Average Rating
              </p>
            </div>
          </div>
        </FadeInSection>
      </SectionWrapper>

      {/* Before/After Gallery Section */}
      <SectionWrapper id="gallery">
        <FadeInSection>
          <BeforeAfterGallery limit={6} />
        </FadeInSection>
      </SectionWrapper>

      <SectionWrapper id="testimonials-preview">
        <div className="text-center mb-12">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">
            Hear From Our Happy Clients
          </h2>
        </div>
        <div className="grid md:grid-cols-3 gap-8">
          {displayTestimonials.slice(0, 3).map(testimonial => (
            <Card key={testimonial.customer_name} className="shadow-lg">
              <CardContent className="pt-6">
                <div className="flex mb-2">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star
                      key={i}
                      className="h-5 w-5 text-yellow-400 fill-current"
                    />
                  ))}
                </div>
                <p className="text-muted-foreground mb-4 italic">
                  "{testimonial.review_text}"
                </p>
                <p className="font-semibold text-primary text-right">
                  - {testimonial.customer_name}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
        <div className="text-center mt-12">
          <Button asChild size="lg" variant="outline">
            <Link href="/testimonials">Read More Testimonials</Link>
          </Button>
        </div>
      </SectionWrapper>

      <SectionWrapper
        id="cta-banner"
        className="bg-primary text-primary-foreground"
      >
        <div className="text-center">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold mb-6">
            Ready to Reclaim Your Space?
          </h2>
          <p className="text-lg text-primary-foreground/80 mb-8 max-w-xl mx-auto">
            Get a free, no-obligation quote for your clearance needs today. It's
            quick and easy!
          </p>
          <Button
            asChild
            size="lg"
            className="bg-accent hover:bg-accent/90 text-accent-foreground text-lg px-10 py-6"
          >
            <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
          </Button>
        </div>
      </SectionWrapper>
    </>
  );
}
