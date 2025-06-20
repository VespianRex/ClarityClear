"use client";

import * as React from "react";
import Link from "next/link";
import { Menu, X, Zap } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger, SheetClose } from "@/components/ui/sheet";
import { NAV_LINKS, APP_NAME, CTA_BOOKING_LABEL, CTA_BOOKING_HREF } from "@/lib/constants";
import type { NavLink as NavLinkType } from "@/lib/constants";

const NavLink: React.FC<{ link: NavLinkType; onClick?: () => void }> = ({ link, onClick }) => (
  <Link
    href={link.href}
    className="font-medium text-foreground/80 hover:text-primary transition-colors flex items-center gap-2 py-2"
    onClick={onClick}
    aria-label={link.label}
  >
    {link.icon && <link.icon className="h-5 w-5" />}
    {link.label}
  </Link>
);

export function Navbar() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = React.useState(false);

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-16 max-w-screen-2xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <Link href="/" className="flex items-center gap-2" aria-label={`${APP_NAME} home page`}>
          <Zap className="h-7 w-7 text-accent" />
          <span className="font-headline text-2xl font-semibold text-primary">{APP_NAME}</span>
        </Link>

        <nav className="hidden md:flex items-center space-x-6">
          {NAV_LINKS.map((link) => (
            <NavLink key={link.href} link={link} />
          ))}
        </nav>

        <div className="flex items-center gap-4">
          <Button asChild variant="default" className="hidden md:inline-flex bg-accent hover:bg-accent/90 text-accent-foreground">
            <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
          </Button>

          <Sheet open={isMobileMenuOpen} onOpenChange={setIsMobileMenuOpen}>
            <SheetTrigger asChild className="md:hidden">
              <Button variant="ghost" size="icon" aria-label="Open mobile menu">
                <Menu className="h-6 w-6" />
              </Button>
            </SheetTrigger>
            <SheetContent side="right" className="w-full max-w-xs bg-background p-6">
              <div className="flex flex-col space-y-6">
                <div className="flex justify-between items-center">
                 <Link href="/" className="flex items-center gap-2" onClick={() => setIsMobileMenuOpen(false)}>
                    <Zap className="h-6 w-6 text-accent" />
                    <span className="font-headline text-xl font-semibold text-primary">{APP_NAME}</span>
                  </Link>
                  <SheetClose asChild>
                     <Button variant="ghost" size="icon" aria-label="Close mobile menu">
                        <X className="h-6 w-6" />
                      </Button>
                  </SheetClose>
                </div>
                <nav className="flex flex-col space-y-4">
                  {NAV_LINKS.map((link) => (
                    <NavLink key={link.href} link={link} onClick={() => setIsMobileMenuOpen(false)} />
                  ))}
                </nav>
                <Button asChild variant="default" className="w-full bg-accent hover:bg-accent/90 text-accent-foreground" onClick={() => setIsMobileMenuOpen(false)}>
                  <Link href={CTA_BOOKING_HREF}>{CTA_BOOKING_LABEL}</Link>
                </Button>
              </div>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  );
}
