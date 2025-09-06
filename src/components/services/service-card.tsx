import Image from 'next/image';
import Link from 'next/link';
import type { LucideIcon } from 'lucide-react';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';

export interface ServiceCardProps {
  title: string;
  description: string;
  icon?: LucideIcon;
  imageUrl: string;
  imageAlt: string;
  imageHint?: string;
  learnMoreLink?: string;
}

export function ServiceCard({
  title,
  description,
  icon: Icon,
  imageUrl,
  imageAlt,
  imageHint,
  learnMoreLink = '#',
}: ServiceCardProps) {
  return (
    <Card className="flex flex-col overflow-hidden shadow-lg hover:shadow-xl transition-shadow duration-300 h-full">
      <div className="relative h-56 w-full">
        <Image
          src={imageUrl}
          alt={imageAlt}
          layout="fill"
          objectFit="cover"
          data-ai-hint={imageHint || title.toLowerCase().replace(/\s+/g, ' ')}
        />
      </div>
      <CardHeader>
        <div className="flex items-center gap-3">
          {Icon && <Icon className="h-8 w-8 text-accent shrink-0" />}
          <CardTitle className="font-headline text-2xl text-primary">
            {title}
          </CardTitle>
        </div>
      </CardHeader>
      <CardContent className="flex-grow">
        <CardDescription className="text-base leading-relaxed">
          {description}
        </CardDescription>
      </CardContent>
      <CardFooter>
        <Button
          asChild
          variant="default"
          className="w-full bg-accent hover:bg-accent/90 text-accent-foreground"
        >
          <Link href={learnMoreLink}>Get a Quote</Link>
        </Button>
      </CardFooter>
    </Card>
  );
}
