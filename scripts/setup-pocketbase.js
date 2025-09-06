#!/usr/bin/env node

/**
 * PocketBase Setup Script for ClarityClear
 * This script creates the necessary collections and sample data
 */

const PocketBase = require('pocketbase').default;

const POCKETBASE_URL = process.env.NEXT_PUBLIC_POCKETBASE_URL || 'http://localhost:8090';
const ADMIN_EMAIL = process.env.POCKETBASE_ADMIN_EMAIL || 'admin@clarityclear.com';
const ADMIN_PASSWORD = process.env.POCKETBASE_ADMIN_PASSWORD || 'admin123456';

async function setupPocketBase() {
  const pb = new PocketBase(POCKETBASE_URL);

  try {
    console.log('🚀 Setting up PocketBase for ClarityClear...');
    
    // Authenticate as admin
    await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASSWORD);
    console.log('✅ Admin authenticated');

    // Create collections
    await createCollections(pb);
    
    // Seed sample data
    await seedData(pb);
    
    console.log('🎉 PocketBase setup completed successfully!');
    console.log(`📊 Admin panel: ${POCKETBASE_URL}/_/`);
    
  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    process.exit(1);
  }
}

async function createCollections(pb) {
  console.log('📦 Creating collections...');

  // Services collection
  try {
    await pb.collections.create({
      name: 'services',
      type: 'base',
      schema: [
        { name: 'title', type: 'text', required: true },
        { name: 'description', type: 'editor' },
        { name: 'short_description', type: 'text' },
        { name: 'price_from', type: 'number' },
        { name: 'price_to', type: 'number' },
        { name: 'image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
        { name: 'gallery', type: 'file', options: { maxSelect: 10, maxSize: 5242880 } },
        { name: 'features', type: 'json' },
        { name: 'availability', type: 'bool', required: true },
        { name: 'order', type: 'number' }
      ]
    });
    console.log('  ✅ Services collection created');
  } catch (e) {
    console.log('  ⚠️  Services collection already exists');
  }

  // Testimonials collection
  try {
    await pb.collections.create({
      name: 'testimonials',
      type: 'base',
      schema: [
        { name: 'customer_name', type: 'text', required: true },
        { name: 'customer_initial', type: 'text' },
        { name: 'rating', type: 'number', required: true },
        { name: 'review_text', type: 'editor', required: true },
        { name: 'service_type', type: 'relation', options: { collectionId: 'services' } },
        { name: 'location', type: 'text' },
        { name: 'date_of_service', type: 'date' },
        { name: 'approved', type: 'bool' },
        { name: 'featured', type: 'bool' }
      ]
    });
    console.log('  ✅ Testimonials collection created');
  } catch (e) {
    console.log('  ⚠️  Testimonials collection already exists');
  }

  // Bookings collection
  try {
    await pb.collections.create({
      name: 'bookings',
      type: 'base',
      schema: [
        { name: 'service_type', type: 'relation', options: { collectionId: 'services' } },
        { name: 'customer_name', type: 'text', required: true },
        { name: 'customer_email', type: 'email', required: true },
        { name: 'customer_phone', type: 'text', required: true },
        { name: 'property_address', type: 'editor', required: true },
        { name: 'postcode', type: 'text', required: true },
        { name: 'property_size', type: 'text' },
        { name: 'urgency', type: 'select', options: { values: ['asap', 'week', 'flexible'] } },
        { name: 'access_info', type: 'editor' },
        { name: 'special_requirements', type: 'editor' },
        { name: 'additional_services', type: 'json' },
        { name: 'preferred_contact', type: 'select', options: { values: ['phone', 'email', 'whatsapp'] } },
        { name: 'best_time_call', type: 'text' },
        { name: 'status', type: 'select', options: { values: ['new', 'contacted', 'quoted', 'booked', 'completed'] } },
        { name: 'estimated_price', type: 'number' },
        { name: 'notes', type: 'editor' }
      ]
    });
    console.log('  ✅ Bookings collection created');
  } catch (e) {
    console.log('  ⚠️  Bookings collection already exists');
  }

  // FAQs collection
  try {
    await pb.collections.create({
      name: 'faqs',
      type: 'base',
      schema: [
        { name: 'question', type: 'text', required: true },
        { name: 'answer', type: 'editor', required: true },
        { name: 'category', type: 'text' },
        { name: 'order', type: 'number' },
        { name: 'published', type: 'bool' }
      ]
    });
    console.log('  ✅ FAQs collection created');
  } catch (e) {
    console.log('  ⚠️  FAQs collection already exists');
  }

  // Articles collection
  try {
    await pb.collections.create({
      name: 'articles',
      type: 'base',
      schema: [
        { name: 'title', type: 'text', required: true },
        { name: 'slug', type: 'text', required: true },
        { name: 'content', type: 'editor', required: true },
        { name: 'excerpt', type: 'text' },
        { name: 'category', type: 'text' },
        { name: 'tags', type: 'json' },
        { name: 'featured_image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
        { name: 'published', type: 'bool' },
        { name: 'publish_date', type: 'date' },
        { name: 'seo_title', type: 'text' },
        { name: 'seo_description', type: 'text' }
      ]
    });
    console.log('  ✅ Articles collection created');
  } catch (e) {
    console.log('  ⚠️  Articles collection already exists');
  }

  // Settings collection
  try {
    await pb.collections.create({
      name: 'settings',
      type: 'base',
      schema: [
        { name: 'key', type: 'text', required: true },
        { name: 'value', type: 'json' },
        { name: 'description', type: 'text' }
      ]
    });
    console.log('  ✅ Settings collection created');
  } catch (e) {
    console.log('  ⚠️  Settings collection already exists');
  }
}

async function seedData(pb) {
  console.log('🌱 Seeding sample data...');

  // Sample services
  const services = [
    {
      title: 'House Clearance',
      description: 'Complete house clearance service including furniture, appliances, and personal belongings. We handle everything from single rooms to entire properties.',
      short_description: 'Full or partial house clearance with professional care',
      price_from: 150,
      price_to: 800,
      features: ['Free quotation', 'Fully insured', 'Same day service available', 'Eco-friendly disposal'],
      availability: true,
      order: 1
    },
    {
      title: 'Office Clearance',
      description: 'Efficient office clearance service for businesses of all sizes. We safely dispose of IT equipment, furniture, and confidential documents.',
      short_description: 'Professional office and commercial clearance',
      price_from: 200,
      price_to: 1200,
      features: ['Secure data destruction', 'Certificate of disposal', 'Out of hours service', 'Furniture donation'],
      availability: true,
      order: 2
    },
    {
      title: 'Garden Clearance',
      description: 'Garden waste removal including green waste, soil, rubble, and old garden furniture. Transform your outdoor space.',
      short_description: 'Garden waste and outdoor clearance service',
      price_from: 100,
      price_to: 500,
      features: ['Green waste recycling', 'Soil and rubble removal', 'Shed dismantling', 'Garden furniture removal'],
      availability: true,
      order: 3
    }
  ];

  for (const service of services) {
    try {
      await pb.collection('services').create(service);
    } catch (e) {
      console.log(`  ⚠️  Service "${service.title}" already exists`);
    }
  }

  // Sample testimonials
  const testimonials = [
    {
      customer_name: 'Sarah Mitchell',
      customer_initial: 'S.M.',
      rating: 5,
      review_text: 'ClarityClear made our house move so much easier! The team was professional, quick, and very friendly. They handled everything with care and left the place spotless.',
      location: 'Manchester',
      date_of_service: '2024-01-15',
      approved: true,
      featured: true
    },
    {
      customer_name: 'John Bradley',
      customer_initial: 'J.B.',
      rating: 5,
      review_text: 'Highly recommend their office clearance service. They handled our IT equipment disposal professionally and provided all the necessary certificates.',
      location: 'Birmingham',
      date_of_service: '2024-01-20',
      approved: true,
      featured: true
    },
    {
      customer_name: 'Linda Peterson',
      customer_initial: 'L.P.',
      rating: 5,
      review_text: 'Fantastic job clearing out our overgrown garden. The team worked efficiently and recycled everything possible. It looks like a new space now!',
      location: 'Leeds',
      date_of_service: '2024-01-25',
      approved: true,
      featured: false
    }
  ];

  for (const testimonial of testimonials) {
    try {
      await pb.collection('testimonials').create(testimonial);
    } catch (e) {
      console.log(`  ⚠️  Testimonial from "${testimonial.customer_name}" already exists`);
    }
  }

  // Sample FAQs
  const faqs = [
    {
      question: 'How quickly can you provide a quote?',
      answer: 'We aim to provide quotes within 24 hours. For urgent requests, we can often provide same-day quotes.',
      category: 'general',
      order: 1,
      published: true
    },
    {
      question: 'Do you provide certificates of disposal?',
      answer: 'Yes, we provide waste transfer notes and certificates of disposal for all commercial clearances and upon request for domestic clearances.',
      category: 'disposal',
      order: 2,
      published: true
    },
    {
      question: 'Are you fully insured?',
      answer: 'Yes, we carry full public liability insurance and waste carriers license. All our team members are fully trained and insured.',
      category: 'insurance',
      order: 3,
      published: true
    }
  ];

  for (const faq of faqs) {
    try {
      await pb.collection('faqs').create(faq);
    } catch (e) {
      console.log(`  ⚠️  FAQ "${faq.question}" already exists`);
    }
  }

  console.log('✅ Sample data seeded successfully');
}

// Run the setup
setupPocketBase();