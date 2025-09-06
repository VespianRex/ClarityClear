import Link from 'next/link';
import Image from 'next/image';
import { Button } from '@/components/ui/button';
import { CTA_BOOKING_HREF, CTA_BOOKING_LABEL, APP_NAME } from '@/lib/constants';
import { MoveRight, Sparkles } from 'lucide-react';
import { WhatsAppButton } from '@/components/common/whatsapp-button';

export function HeroSection() {
  return (
    <section className="bg-secondary">
      <div className="container mx-auto max-w-screen-xl px-4 sm:px-6 lg:px-8 py-16 md:py-24 lg:py-32">
        <div className="grid md:grid-cols-2 gap-8 md:gap-12 items-center">
          <div className="text-center md:text-left">
            <h1 className="font-headline text-4xl sm:text-5xl lg:text-6xl font-bold text-primary mb-6 leading-tight">
              Effortless Clearance,
              <br />
              <span className="text-accent">Sparkling Clarity.</span>
            </h1>
            <p className="text-lg sm:text-xl text-muted-foreground mb-8 max-w-xl mx-auto md:mx-0">
              {APP_NAME} offers professional and reliable house clearance
              services. Reclaim your space with our hassle-free solutions.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center md:justify-start items-center">
              <Button
                asChild
                size="lg"
                className="bg-accent hover:bg-accent/90 text-accent-foreground text-lg px-8 py-6"
              >
                <Link href={CTA_BOOKING_HREF}>
                  {CTA_BOOKING_LABEL}
                  <MoveRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
              <WhatsAppButton size="lg" text="Chat with Us" />
            </div>
          </div>
          <div className="relative aspect-video rounded-lg overflow-hidden shadow-2xl">
            <Image
              src="https://placehold.co/600x400.png"
              alt="Clean and organized living space"
              layout="fill"
              objectFit="cover"
              data-ai-hint="tidy room"
              priority
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent"></div>
            <div className="absolute bottom-4 left-4 bg-background/80 backdrop-blur-sm p-3 rounded-md shadow-md">
              <div className="flex items-center gap-2 text-primary">
                <Sparkles className="h-5 w-5 text-accent" />
                <span className="text-sm font-medium">
                  Fast & Efficient Service
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
