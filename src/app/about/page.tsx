import Image from 'next/image';
import { Metadata } from 'next';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { CheckSquare, Handshake, Leaf, Target } from 'lucide-react';
import { APP_NAME } from '@/lib/constants';

export const metadata: Metadata = {
  title: 'About Us',
};

export default function AboutPage() {
  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">About {APP_NAME}</h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto">
            Your trusted partner in creating clear, manageable spaces with professionalism and care.
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper id="our-story">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <div>
            <h2 className="font-headline text-3xl font-bold text-primary mb-6">Our Story</h2>
            <p className="text-muted-foreground mb-4 leading-relaxed">
              Founded with a passion for helping individuals and businesses reclaim their environments, {APP_NAME} has grown into a leading provider of clearance services. We understand that dealing with clutter, whether at home or in the workplace, can be overwhelming. That's why we're dedicated to offering a service that is not only efficient and reliable but also empathetic and understanding of our clients' needs.
            </p>
            <p className="text-muted-foreground leading-relaxed">
              Our team is comprised of experienced professionals who are committed to delivering a high-quality service from start to finish. We pride ourselves on our attention to detail, our commitment to eco-friendly practices, and our unwavering focus on customer satisfaction.
            </p>
          </div>
          <div className="relative aspect-square rounded-lg overflow-hidden shadow-xl">
            <Image 
              src="https://placehold.co/500x500.png" 
              alt="ClarityClear team at work" 
              layout="fill"
              objectFit="cover"
              data-ai-hint="team work"
            />
          </div>
        </div>
      </SectionWrapper>

      <SectionWrapper id="mission-values" className="bg-secondary">
        <div className="grid md:grid-cols-2 gap-12">
          <div>
            <h2 className="font-headline text-3xl font-bold text-primary mb-6 flex items-center">
              <Target className="h-8 w-8 text-accent mr-3" />
              Our Mission
            </h2>
            <p className="text-muted-foreground leading-relaxed text-lg">
              To provide exceptional clearance solutions that simplify our clients' lives, enhance their spaces, and contribute positively to the environment through responsible disposal and recycling practices.
            </p>
          </div>
          <div>
            <h2 className="font-headline text-3xl font-bold text-primary mb-6">Our Core Values</h2>
            <ul className="space-y-4">
              <li className="flex items-start">
                <CheckSquare className="h-6 w-6 text-accent mr-3 mt-1 shrink-0" />
                <div>
                  <h3 className="font-semibold text-primary text-lg">Integrity</h3>
                  <p className="text-muted-foreground">Operating with honesty, transparency, and respect in all our interactions.</p>
                </div>
              </li>
              <li className="flex items-start">
                <Handshake className="h-6 w-6 text-accent mr-3 mt-1 shrink-0" />
                <div>
                  <h3 className="font-semibold text-primary text-lg">Customer Focus</h3>
                  <p className="text-muted-foreground">Putting our clients' needs first and striving to exceed their expectations.</p>
                </div>
              </li>
              <li className="flex items-start">
                <Leaf className="h-6 w-6 text-accent mr-3 mt-1 shrink-0" />
                <div>
                  <h3 className="font-semibold text-primary text-lg">Sustainability</h3>
                  <p className="text-muted-foreground">Committing to environmentally responsible practices in all our operations.</p>
                </div>
              </li>
               <li className="flex items-start">
                <CheckSquare className="h-6 w-6 text-accent mr-3 mt-1 shrink-0" />
                <div>
                  <h3 className="font-semibold text-primary text-lg">Professionalism</h3>
                  <p className="text-muted-foreground">Maintaining high standards of service, efficiency, and reliability.</p>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </SectionWrapper>
       <SectionWrapper id="commitment">
         <div className="text-center max-w-3xl mx-auto">
            <h2 className="font-headline text-3xl font-bold text-primary mb-6">Our Commitment to You</h2>
            <p className="text-muted-foreground text-lg leading-relaxed mb-4">
              At {APP_NAME}, we're more than just a clearance company. We're your partners in creating a cleaner, more organized, and stress-free environment. We are committed to providing a seamless experience, from your initial inquiry to the final sweep-up. Our team is trained to handle all items with care and discretion, ensuring your peace of mind throughout the process.
            </p>
            <p className="text-muted-foreground text-lg leading-relaxed">
              We believe in building lasting relationships with our clients based on trust and exceptional service. Let us help you achieve clarity and order in your space.
            </p>
         </div>
      </SectionWrapper>
    </>
  );
}
