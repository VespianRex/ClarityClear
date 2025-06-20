import { Metadata } from 'next';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { ServiceCard, type ServiceCardProps } from '@/components/services/service-card';
import { Home, Briefcase, Trash2, Building, Recycle, AlertTriangle } from 'lucide-react';
import { CTA_BOOKING_HREF, CTA_BOOKING_LABEL } from '@/lib/constants';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Our Services',
  description: 'Explore the comprehensive clearance and collection services offered by ClarityClear.',
};

const servicesData: ServiceCardProps[] = [
  {
    title: "Full House Clearance",
    description: "Comprehensive removal of all items from a property, including furniture, personal effects, carpets, and white goods. Ideal for probate, downsizing, or preparing a property for sale/let.",
    icon: Home,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Living room being cleared",
    imageHint: "house clearance",
    learnMoreLink: "/booking?service=house-clearance"
  },
  {
    title: "Partial House Clearance",
    description: "Targeted removal of specific items or from particular rooms, such as attics, garages, or sheds. Flexible to suit your exact requirements.",
    icon: Home,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Garage being cleared",
    imageHint: "garage clutter",
    learnMoreLink: "/booking?service=partial-clearance"
  },
  {
    title: "Office & Commercial Clearance",
    description: "Professional clearance of office spaces, retail units, and other commercial properties. We handle furniture, IT equipment, documents, and general waste.",
    icon: Briefcase,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Office space with boxes",
    imageHint: "office move",
    learnMoreLink: "/booking?service=office-clearance"
  },
  {
    title: "Garden Waste Removal",
    description: "Collection and disposal of green waste, soil, rubble, old sheds, garden furniture, and other outdoor items. We help you reclaim your garden.",
    icon: Trash2,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Garden waste piled up",
    imageHint: "garden waste",
    learnMoreLink: "/booking?service=garden-waste"
  },
  {
    title: "Builders Waste Disposal",
    description: "Removal of construction and demolition waste, including rubble, plasterboard, wood, and packaging. We ensure sites are left clean and tidy.",
    icon: Building,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Construction site with debris",
    imageHint: "construction debris",
    learnMoreLink: "/booking?service=builders-waste"
  },
  {
    title: "Recycling & WEEE Disposal",
    description: "Eco-friendly disposal of Waste Electrical and Electronic Equipment (WEEE) and commitment to recycling as much waste as possible.",
    icon: Recycle,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Recycling bins and electronic waste",
    imageHint: "recycling electronics",
    learnMoreLink: "/booking?service=recycling-weee"
  },
  {
    title: "Hoarding Clearance Support",
    description: "Sensitive and discreet clearance services for properties affected by hoarding. We work with compassion and understanding.",
    icon: AlertTriangle,
    imageUrl: "https://placehold.co/600x400.png",
    imageAlt: "Cluttered room",
    imageHint: "hoarding clutter",
    learnMoreLink: "/booking?service=hoarding-clearance"
  },
];

export default function ServicesPage() {
  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">Our Clearance Services</h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-3xl mx-auto">
            At ClarityClear, we provide a wide array of professional clearance and collection services. Whether you're clearing a home, office, or garden, we have the expertise to handle it efficiently and responsibly.
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8">
          {servicesData.map((service) => (
            <ServiceCard key={service.title} {...service} />
          ))}
        </div>
      </SectionWrapper>

      <SectionWrapper id="cta-banner" className="bg-primary text-primary-foreground">
        <div className="text-center">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold mb-6">Ready for a Clearer Space?</h2>
          <p className="text-lg text-primary-foreground/80 mb-8 max-w-xl mx-auto">
            Contact us today for a free, no-obligation quote tailored to your specific clearance needs.
          </p>
          <Button asChild size="lg" className="bg-accent hover:bg-accent/90 text-accent-foreground text-lg px-10 py-6">
            <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
          </Button>
        </div>
      </SectionWrapper>
    </>
  );
}
