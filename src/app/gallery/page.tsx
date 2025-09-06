'use client';

import { SectionWrapper } from '@/components/common/section-wrapper';
import { BeforeAfterGallery } from '@/components/gallery/before-after-gallery';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Camera, ArrowLeft } from 'lucide-react';
import { FadeInSection } from '@/components/ui/fade-in-section';
import { useServices } from '@/hooks/use-pocketbase';
import Link from 'next/link';

export default function GalleryPage() {
  useServices(); // Keep hook active for potential future use

  return (
    <>
      <SectionWrapper className="bg-secondary">
        <FadeInSection>
          <div className="text-center">
            <div className="flex items-center justify-center gap-2 mb-4">
              <Camera className="h-8 w-8 text-accent" />
              <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary">
                Our Work Gallery
              </h1>
            </div>
            <p className="text-lg sm:text-xl text-muted-foreground max-w-3xl mx-auto mb-6">
              See the incredible transformations we've achieved for our
              customers. Real before and after photos from actual clearance
              projects.
            </p>
            <Badge variant="secondary" className="text-sm">
              Interactive before/after slider - drag to compare!
            </Badge>
          </div>
        </FadeInSection>
      </SectionWrapper>

      <SectionWrapper>
        <FadeInSection delay={0.2}>
          <Tabs defaultValue="all" className="w-full">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
              <TabsList className="grid grid-cols-2 lg:grid-cols-4 w-full sm:w-auto">
                <TabsTrigger value="all">All Projects</TabsTrigger>
                <TabsTrigger value="house">House Clearance</TabsTrigger>
                <TabsTrigger value="office">Office Clearance</TabsTrigger>
                <TabsTrigger value="garden">Garden Clearance</TabsTrigger>
              </TabsList>

              <Button variant="outline" asChild>
                <Link href="/">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Home
                </Link>
              </Button>
            </div>

            <TabsContent value="all" className="space-y-8">
              <BeforeAfterGallery showTitle={false} />
            </TabsContent>

            <TabsContent value="house" className="space-y-8">
              <BeforeAfterGallery showTitle={false} serviceFilter="house" />
            </TabsContent>

            <TabsContent value="office" className="space-y-8">
              <BeforeAfterGallery showTitle={false} serviceFilter="office" />
            </TabsContent>

            <TabsContent value="garden" className="space-y-8">
              <BeforeAfterGallery showTitle={false} serviceFilter="garden" />
            </TabsContent>
          </Tabs>
        </FadeInSection>
      </SectionWrapper>

      {/* Call to Action */}
      <SectionWrapper className="bg-primary text-primary-foreground">
        <FadeInSection delay={0.3}>
          <div className="text-center">
            <h2 className="font-headline text-3xl sm:text-4xl font-bold mb-6">
              Ready for Your Own Transformation?
            </h2>
            <p className="text-lg text-primary-foreground/80 mb-8 max-w-xl mx-auto">
              Join our gallery of satisfied customers. Get your free quote today
              and see what we can do for your space.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button
                asChild
                size="lg"
                className="bg-accent hover:bg-accent/90 text-accent-foreground"
              >
                <Link href="/booking">Get Free Quote</Link>
              </Button>
              <Button
                asChild
                size="lg"
                variant="outline"
                className="border-white text-white hover:bg-white hover:text-primary"
              >
                <Link href="/contact">Contact Us</Link>
              </Button>
            </div>
          </div>
        </FadeInSection>
      </SectionWrapper>
    </>
  );
}
