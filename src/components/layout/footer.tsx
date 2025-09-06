import Link from 'next/link';
import { APP_NAME } from '@/lib/constants';
import { Zap } from 'lucide-react';
import { WhatsAppButton } from '@/components/common/whatsapp-button';

export function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="border-t border-border/40 bg-background">
      <div className="container mx-auto max-w-screen-2xl px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
          <div className="flex flex-col items-center md:items-start">
            <Link
              href="/"
              className="flex items-center gap-2 mb-2"
              aria-label={`${APP_NAME} home page`}
            >
              <Zap className="h-7 w-7 text-accent" />
              <span className="font-headline text-xl font-semibold text-primary">
                {APP_NAME}
              </span>
            </Link>
            <p className="text-sm text-muted-foreground text-center md:text-left">
              Your trusted partner for clear spaces and peace of mind.
            </p>
          </div>

          <div className="flex flex-col items-center">
            <h3 className="font-headline text-lg font-semibold mb-2 text-primary">
              Quick Links
            </h3>
            <ul className="space-y-1 text-center">
              <li>
                <Link
                  href="/services"
                  className="text-muted-foreground hover:text-primary transition-colors"
                >
                  Services
                </Link>
              </li>
              <li>
                <Link
                  href="/booking"
                  className="text-muted-foreground hover:text-primary transition-colors"
                >
                  Book Collection
                </Link>
              </li>
              <li>
                <Link
                  href="/faq"
                  className="text-muted-foreground hover:text-primary transition-colors"
                >
                  FAQ
                </Link>
              </li>
              <li>
                <Link
                  href="/contact"
                  className="text-muted-foreground hover:text-primary transition-colors"
                >
                  Contact Us
                </Link>
              </li>
            </ul>
          </div>

          <div className="flex flex-col items-center md:items-end">
            <h3 className="font-headline text-lg font-semibold mb-3 text-primary">
              Get in Touch
            </h3>
            <WhatsAppButton size="lg" />
            {/* Add other social icons here if needed */}
            {/* <div className="flex space-x-4 mt-4">
              {SOCIAL_LINKS.filter(link => link.name !== "WhatsApp").map((link) => (
                <a key={link.name} href={link.href} target="_blank" rel="noopener noreferrer" aria-label={link.name} className="text-muted-foreground hover:text-primary transition-colors">
                  {link.icon && <link.icon className="h-6 w-6" />}
                </a>
              ))}
            </div> */}
          </div>
        </div>
        <div className="mt-8 border-t border-border/40 pt-8 text-center text-sm text-muted-foreground">
          <p>
            &copy; {currentYear} {APP_NAME}. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
