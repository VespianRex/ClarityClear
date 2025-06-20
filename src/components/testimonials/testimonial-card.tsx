import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Star } from "lucide-react";

export interface TestimonialCardProps {
  quote: string;
  author: string;
  role?: string;
  avatarUrl?: string;
  rating?: number;
  imageHint?: string;
}

export function TestimonialCard({ quote, author, role, avatarUrl, rating, imageHint }: TestimonialCardProps) {
  const authorInitials = author.split(' ').map(n => n[0]).join('').toUpperCase();

  return (
    <Card className="h-full flex flex-col shadow-lg hover:shadow-xl transition-shadow duration-300">
      <CardContent className="pt-8 flex-grow flex flex-col justify-between">
        <div>
          {rating && (
            <div className="flex mb-3">
              {[...Array(Math.floor(rating))].map((_, i) => (
                <Star key={i} className="h-5 w-5 text-yellow-400 fill-current" />
              ))}
              {rating % 1 !== 0 && <Star key="half" className="h-5 w-5 text-yellow-400 fill-current opacity-50" />} 
              {[...Array(5 - Math.ceil(rating))].map((_, i) => (
                 <Star key={`empty-${i}`} className="h-5 w-5 text-gray-300" />
              ))}
            </div>
          )}
          <blockquote className="text-lg text-muted-foreground leading-relaxed italic mb-6">
            "{quote}"
          </blockquote>
        </div>
        <div className="flex items-center mt-auto">
          {avatarUrl && (
             <Avatar className="h-12 w-12 mr-4">
              <AvatarImage src={avatarUrl} alt={author} data-ai-hint={imageHint || 'person portrait'} />
              <AvatarFallback>{authorInitials}</AvatarFallback>
            </Avatar>
          )}
          {!avatarUrl && (
            <Avatar className="h-12 w-12 mr-4 bg-muted">
              <AvatarFallback className="text-primary font-semibold">{authorInitials}</AvatarFallback>
            </Avatar>
          )}
          <div>
            <p className="font-headline text-md font-semibold text-primary">{author}</p>
            {role && <p className="text-sm text-muted-foreground">{role}</p>}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
