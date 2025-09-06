import PocketBase from 'pocketbase';

// Initialize PocketBase client
const pb = new PocketBase(
  process.env.NEXT_PUBLIC_POCKETBASE_URL || 'http://localhost:8090'
);

// Disable auto cancellation for better UX
pb.autoCancellation(false);

export default pb;

// Type definitions for PocketBase collections
export interface Service {
  id: string;
  title: string;
  description: string;
  short_description: string;
  price_from: number;
  price_to: number;
  image: string;
  gallery: string[];
  features: string[];
  availability: boolean;
  order: number;
  icon_name?: string;
  image_url?: string;
  image_hint?: string;
  learn_more_link?: string;
  created: string;
  updated: string;
}

export interface Testimonial {
  id: string;
  customer_name: string;
  customer_initial: string;
  rating: number;
  review_text: string;
  service_type: string;
  location: string;
  date_of_service: string;
  approved: boolean;
  featured: boolean;
  created: string;
}

export interface Booking {
  id: string;
  service_type: string;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  property_address: string;
  postcode: string;
  property_size: string;
  urgency: 'asap' | 'week' | 'flexible';
  access_info: string;
  special_requirements: string;
  additional_services: string[];
  preferred_contact: 'phone' | 'email' | 'whatsapp';
  best_time_call: string;
  status: 'new' | 'contacted' | 'quoted' | 'booked' | 'completed';
  estimated_price: number;
  notes: string;
  created: string;
  updated: string;
}

export interface FAQ {
  id: string;
  question: string;
  answer: string;
  category: string;
  order: number;
  published: boolean;
  icon_name?: string;
  created: string;
  updated: string;
}

export interface Article {
  id: string;
  title: string;
  slug: string;
  content: string;
  excerpt: string;
  category: string;
  tags: string[];
  featured_image: string;
  published: boolean;
  publish_date: string;
  seo_title: string;
  seo_description: string;
  created: string;
  updated: string;
}

export interface Settings {
  id: string;
  key: string;
  value: any;
  description: string;
  created: string;
  updated: string;
}

// Helper functions for common operations
export const pocketbaseHelpers = {
  // Services
  async getServices(): Promise<Service[]> {
    return await pb.collection('services').getFullList({
      sort: 'order,title',
      filter: 'availability = true',
    });
  },

  async getService(id: string): Promise<Service> {
    return await pb.collection('services').getOne(id);
  },

  // Testimonials
  async getTestimonials(limit = 10): Promise<Testimonial[]> {
    const result = await pb.collection('testimonials').getList(1, limit, {
      sort: '-created',
      filter: 'approved = true',
    });
    return result.items as unknown as Testimonial[];
  },

  async getFeaturedTestimonials(): Promise<Testimonial[]> {
    return await pb.collection('testimonials').getFullList({
      sort: '-created',
      filter: 'approved = true && featured = true',
    });
  },

  // Bookings
  async createBooking(data: Partial<Booking>): Promise<Booking> {
    return await pb.collection('bookings').create(data);
  },

  // FAQs
  async getFAQs(category?: string): Promise<FAQ[]> {
    const filter = category
      ? `published = true && category = "${category}"`
      : 'published = true';

    return await pb.collection('faqs').getFullList({
      sort: 'order,question',
      filter,
    });
  },

  // Articles
  async getArticles(limit = 10): Promise<Article[]> {
    const result = await pb.collection('articles').getList(1, limit, {
      sort: '-publish_date',
      filter: 'published = true',
    });
    return result.items as unknown as Article[];
  },

  async getArticle(slug: string): Promise<Article> {
    return await pb.collection('articles').getFirstListItem(`slug = "${slug}"`);
  },

  // Settings
  async getSetting(key: string): Promise<any> {
    try {
      const setting = await pb
        .collection('settings')
        .getFirstListItem(`key = "${key}"`);
      return setting.value;
    } catch {
      return null;
    }
  },

  // File URL helper
  getFileUrl(record: any, filename: string): string {
    return pb.files.getUrl(record, filename);
  },
};
