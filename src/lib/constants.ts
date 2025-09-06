import type { LucideIcon } from 'lucide-react';
import {
  Home,
  Briefcase,
  Users,
  Star,
  HelpCircle,
  MessageSquareText,
  Mail,
} from 'lucide-react';

export const APP_NAME = 'ClarityClear';

export const WHATSAPP_PHONE_NUMBER = '1234567890'; // Replace with a real number
export const WHATSAPP_PREFILL_MESSAGE =
  "Hello ClarityClear! I'm interested in your collection services and would like a quote.";

export interface NavLink {
  href: string;
  label: string;
  icon?: LucideIcon;
}

export const NAV_LINKS: NavLink[] = [
  { href: '/', label: 'Home', icon: Home },
  { href: '/services', label: 'Services', icon: Briefcase },
  { href: '/gallery', label: 'Gallery', icon: Star },
  { href: '/about', label: 'About Us', icon: Users },
  { href: '/testimonials', label: 'Testimonials', icon: Star },
  { href: '/faq', label: 'FAQ', icon: HelpCircle },
  { href: '/contact', label: 'Contact Us', icon: Mail },
];

export const CTA_BOOKING_LABEL = 'Book a Collection';
export const CTA_BOOKING_HREF = '/booking';

export const CONTACT_EMAIL = `info@${APP_NAME.toLowerCase().replace(/\s+/g, '')}.com`;

export const SOCIAL_LINKS = [
  {
    name: 'WhatsApp',
    href: `https://wa.me/${WHATSAPP_PHONE_NUMBER}?text=${encodeURIComponent(WHATSAPP_PREFILL_MESSAGE)}`,
    icon: MessageSquareText,
  },
  // Add other social links here e.g. Facebook, Instagram
];
