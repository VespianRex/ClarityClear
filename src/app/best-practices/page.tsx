
import { Metadata } from 'next';
import { SectionWrapper } from '@/components/common/section-wrapper';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { Lightbulb, ListChecks, ShieldCheck, Recycle, Home as HomeIcon } from 'lucide-react'; // Changed Home to HomeIcon for clarity
import { Button } from '@/components/ui/button'; // Added Button import

export const metadata: Metadata = {
  title: 'Best Practices for House Clearance',
  description: 'Helpful tips and advice for a smooth and efficient house clearance process from ClarityClear.',
};

const bestPractices = [
  {
    id: "bp1",
    title: "Plan Ahead and Declutter Early",
    icon: Lightbulb,
    content: "Start by sorting items into categories: keep, donate, sell, and discard. This will give you a clearer idea of the volume and type of items to be cleared. Decluttering gradually can make the process less overwhelming. Consider sentimental items separately and give yourself time to decide on their future."
  },
  {
    id: "bp2",
    title: "Inventory Important Items",
    icon: ListChecks,
    content: "Make a list of valuable or significant items, especially if you're dealing with an estate clearance. This includes important documents, jewelry, antiques, or items with sentimental value. Secure these items separately before the main clearance begins."
  },
  {
    id: "bp3",
    title: "Choose a Reputable Clearance Company",
    icon: ShieldCheck,
    content: "Look for a company that is licensed, insured, and has good reviews. Ensure they have a clear policy on recycling and waste disposal. Ask for a detailed quote and understand what services are included. ClarityClear is fully licensed and committed to transparent, professional service."
  },
  {
    id: "bp4",
    title: "Understand Recycling and Disposal",
    icon: Recycle,
    content: "Ask your chosen clearance company about their recycling rates and how they handle different types of waste (e.g., WEEE, hazardous materials). A responsible company will aim to recycle as much as possible and dispose of waste legally and ethically. This helps minimize environmental impact."
  },
  {
    id: "bp5",
    title: "Prepare the Property",
    icon: HomeIcon, // Use imported HomeIcon from lucide-react
    content: "Ensure clear access for the clearance team. Remove any obstacles and inform them of any access restrictions (e.g., parking, stairs). If possible, group items for disposal in one area to speed up the process. Communicate any specific instructions clearly to the team."
  },
  {
    id: "bp6",
    title: "Be Aware of Prohibited Items",
    icon: ShieldCheck, // Consider a more specific icon like AlertTriangle if appropriate for "prohibited"
    content: "Most clearance companies cannot remove certain hazardous materials like asbestos, certain chemicals, or medical waste without special arrangements. Discuss any potentially problematic items with the company beforehand."
  }
];


export default function BestPracticesPage() {
  return (
    <>
      <SectionWrapper className="bg-secondary">
        <div className="text-center">
          <h1 className="font-headline text-4xl sm:text-5xl font-bold text-primary mb-4">House Clearance Best Practices</h1>
          <p className="text-lg sm:text-xl text-muted-foreground max-w-3xl mx-auto">
            Follow these tips to ensure your house clearance process is as smooth, efficient, and stress-free as possible.
          </p>
        </div>
      </SectionWrapper>

      <SectionWrapper>
        <div className="max-w-3xl mx-auto">
          <Accordion type="single" collapsible className="w-full">
            {bestPractices.map((practice) => (
              <AccordionItem value={practice.id} key={practice.id}>
                <AccordionTrigger className="text-left hover:no-underline">
                  <div className="flex items-center gap-3">
                    <practice.icon className="h-6 w-6 text-accent shrink-0" />
                    <span className="font-headline text-xl text-primary">{practice.title}</span>
                  </div>
                </AccordionTrigger>
                <AccordionContent className="text-base text-muted-foreground leading-relaxed pl-9">
                  {practice.content}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      </SectionWrapper>

      <SectionWrapper className="bg-primary text-primary-foreground">
        <div className="text-center">
            <h2 className="font-headline text-3xl font-bold mb-4">Need Professional Help?</h2>
            <p className="text-lg text-primary-foreground/80 mb-6 max-w-xl mx-auto">
                ClarityClear offers expert house clearance services. Contact us for a free quote and a hassle-free experience.
            </p>
            <Button asChild size="lg" className="bg-accent hover:bg-accent/90 text-accent-foreground">
                <a href="/booking">Get Your Free Quote</a>
            </Button>
        </div>
      </SectionWrapper>
    </>
  );
}
