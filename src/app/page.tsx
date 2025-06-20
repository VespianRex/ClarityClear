import Image from 'next/image';
import Link from 'next/link';
import { HeroSection } from '@/components/common/hero-section';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { CheckCircle, Star, MessageCircle } from 'lucide-react';
import { CTA_BOOKING_HREF, CTA_BOOKING_LABEL } from '@/lib/constants';

// Placeholder data - replace with actual data or fetch from a CMS/DB
const services = [
  { title: "House Clearance", description: "Full or partial house clearance, including furniture, appliances, and personal belongings.", icon: <CheckCircle className="h-6 w-6 text-accent" />, image: "https://placehold.co/300x200.png", imageHint: "living room clearance" },
  { title: "Office Clearance", description: "Efficient removal of office furniture, IT equipment, and confidential waste.", icon: <CheckCircle className="h-6 w-6 text-accent" />, image: "https://placehold.co/300x200.png", imageHint: "office workspace" },
  { title: "Garden Waste", description: "Collection of green waste, soil, rubble, and old garden furniture.", icon: <CheckCircle className="h-6 w-6 text-accent" />, image: "https://placehold.co/300x200.png", imageHint: "garden cleanup" },
];

const testimonials = [
  { quote: "ClarityClear made our house move so much easier! Professional, quick, and very friendly staff.", author: "Sarah M.", rating: 5 },
  { quote: "Highly recommend their office clearance service. They handled everything with care and efficiency.", author: "John B.", rating: 5 },
  { quote: "Fantastic job clearing out our overgrown garden. It looks like a new space now!", author: "Linda P.", rating: 5 },
];

export default function HomePage() {
  return (
    <>
      <HeroSection />

      <SectionWrapper id="services-overview">
        <div className="text-center mb-12">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">Our Core Services</h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            We offer a range of clearance services tailored to your needs, ensuring a smooth and stress-free experience.
          </p>
        </div>
        <div className="grid md:grid-cols-3 gap-8">
          {services.map((service) => (
            <Card key={service.title} className="flex flex-col overflow-hidden shadow-lg hover:shadow-xl transition-shadow duration-300">
              <div className="relative h-48 w-full">
                <Image src={service.image} alt={service.title} layout="fill" objectFit="cover" data-ai-hint={service.imageHint} />
              </div>
              <CardHeader>
                <div className="flex items-center gap-3 mb-2">
                  {service.icon}
                  <CardTitle className="font-headline text-xl text-primary">{service.title}</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="flex-grow">
                <CardDescription>{service.description}</CardDescription>
              </CardContent>
              <div className="p-6 pt-0">
                 <Button variant="link" asChild className="text-accent p-0 h-auto">
                    <Link href="/services">Learn More &rarr;</Link>
                 </Button>
              </div>
            </Card>
          ))}
        </div>
        <div className="text-center mt-12">
            <Button asChild size="lg" variant="outline">
                <Link href="/services">View All Services</Link>
            </Button>
        </div>
      </SectionWrapper>

      <SectionWrapper id="why-choose-us" className="bg-secondary">
        <div className="text-center mb-12">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">Why Choose ClarityClear?</h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Experience the ClarityClear difference with our commitment to quality, reliability, and customer satisfaction.
          </p>
        </div>
        <div className="grid md:grid-cols-3 gap-8 text-center">
            <div className="p-6">
                <Star className="h-12 w-12 text-accent mx-auto mb-4" />
                <h3 className="font-headline text-xl font-semibold text-primary mb-2">Reliable & Trustworthy</h3>
                <p className="text-muted-foreground">Count on us for punctual, dependable, and transparent services every time.</p>
            </div>
            <div className="p-6">
                <CheckCircle className="h-12 w-12 text-accent mx-auto mb-4" />
                <h3 className="font-headline text-xl font-semibold text-primary mb-2">Eco-Friendly Approach</h3>
                <p className="text-muted-foreground">We prioritize recycling and responsible disposal to minimize environmental impact.</p>
            </div>
            <div className="p-6">
                <MessageCircle className="h-12 w-12 text-accent mx-auto mb-4" />
                <h3 className="font-headline text-xl font-semibold text-primary mb-2">Customer Focused</h3>
                <p className="text-muted-foreground">Your satisfaction is our top priority. We tailor our services to meet your specific needs.</p>
            </div>
        </div>
      </SectionWrapper>

      <SectionWrapper id="testimonials-preview">
        <div className="text-center mb-12">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">Hear From Our Happy Clients</h2>
        </div>
        <div className="grid md:grid-cols-3 gap-8">
          {testimonials.slice(0,3).map((testimonial) => (
             <Card key={testimonial.author} className="shadow-lg">
                <CardContent className="pt-6">
                    <div className="flex mb-2">
                        {[...Array(testimonial.rating)].map((_, i) => (
                            <Star key={i} className="h-5 w-5 text-yellow-400 fill-current" />
                        ))}
                    </div>
                    <p className="text-muted-foreground mb-4 italic">"{testimonial.quote}"</p>
                    <p className="font-semibold text-primary text-right">- {testimonial.author}</p>
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

      <SectionWrapper id="cta-banner" className="bg-primary text-primary-foreground">
        <div className="text-center">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold mb-6">Ready to Reclaim Your Space?</h2>
          <p className="text-lg text-primary-foreground/80 mb-8 max-w-xl mx-auto">
            Get a free, no-obligation quote for your clearance needs today. It's quick and easy!
          </p>
          <Button asChild size="lg" className="bg-accent hover:bg-accent/90 text-accent-foreground text-lg px-10 py-6">
            <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
          </Button>
        </div>
      </SectionWrapper>
    </>
  );
}
