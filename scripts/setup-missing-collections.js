#!/usr/bin/env node

/**
 * Missing Collections Setup Script for ClarityClear
 * This script creates all the missing collections needed by the frontend
 */

const PocketBase = require('pocketbase').default;

const POCKETBASE_URL = process.env.NEXT_PUBLIC_POCKETBASE_URL || 'http://localhost:8090';
const ADMIN_EMAIL = process.env.POCKETBASE_ADMIN_EMAIL || 'admin@clarityclear.com';
const ADMIN_PASSWORD = process.env.POCKETBASE_ADMIN_PASSWORD || 'ClarityClear123';

async function setupMissingCollections() {
  const pb = new PocketBase(POCKETBASE_URL);

  try {
    console.log('🚀 Creating missing PocketBase collections for ClarityClear...');
    
    // Authenticate as admin
    await pb.admins.authWithPassword(ADMIN_EMAIL, ADMIN_PASSWORD);
    console.log('✅ Admin authenticated');

    // Create all missing collections
    await createMissingCollections(pb);
    
    // Seed sample data for critical collections
    await seedCriticalData(pb);
    
    console.log('🎉 Missing collections setup completed successfully!');
    console.log(`📊 Admin panel: ${POCKETBASE_URL}/_/`);
    
  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    if (error.response) {
      console.error('Response data:', error.response);
    }
    process.exit(1);
  }
}

async function createMissingCollections(pb) {
  console.log('📦 Creating missing collections...');

  // 1. Services collection (CRITICAL - Basic setup script failed)
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
        { name: 'order', type: 'number' },
        { name: 'icon_name', type: 'text' },
        { name: 'image_url', type: 'url' },
        { name: 'image_hint', type: 'text' },
        { name: 'learn_more_link', type: 'url' }
      ]
    });
    console.log('  ✅ Services collection created');
  } catch (e) {
    console.log('  ⚠️  Services collection already exists');
  }

  // 2. Bookings collection (CRITICAL - Basic setup script failed)
  try {
    await pb.collections.create({
      name: 'bookings',
      type: 'base',
      schema: [
        { name: 'service_type', type: 'relation', options: { collectionId: '', maxSelect: 1 } },
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

  // 3. Articles collection (Basic setup script failed)
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

  // 4. Settings collection (Basic setup script failed)
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

  // 5. Review Campaigns collection (Advanced feature)
  try {
    await pb.collections.create({
      name: 'review_campaigns',
      type: 'base',
      schema: [
        { name: 'booking_id', type: 'relation', options: { collectionId: '', maxSelect: 1 } },
        { name: 'customer_email', type: 'email', required: true },
        { name: 'customer_name', type: 'text', required: true },
        { name: 'service_type', type: 'text', required: true },
        { name: 'completion_date', type: 'date', required: true },
        { name: 'review_request_sent', type: 'bool' },
        { name: 'review_request_date', type: 'date' },
        { name: 'follow_up_sent', type: 'bool' },
        { name: 'follow_up_date', type: 'date' },
        { name: 'review_received', type: 'bool' },
        { name: 'review_platform', type: 'select', options: { values: ['google', 'facebook', 'website', 'trustpilot'] } },
        { name: 'review_rating', type: 'number' },
        { name: 'review_url', type: 'url' },
        { name: 'status', type: 'select', options: { values: ['pending', 'sent', 'responded', 'completed', 'opted_out'] } }
      ]
    });
    console.log('  ✅ Review Campaigns collection created');
  } catch (e) {
    console.log('  ⚠️  Review Campaigns collection already exists');
  }

  // 6. Gallery collection (Advanced feature)
  try {
    await pb.collections.create({
      name: 'gallery',
      type: 'base',
      schema: [
        { name: 'title', type: 'text', required: true },
        { name: 'description', type: 'text' },
        { name: 'before_image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
        { name: 'after_image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
        { name: 'service_type', type: 'relation', options: { collectionId: '', maxSelect: 1 } },
        { name: 'location', type: 'text' },
        { name: 'completion_date', type: 'date' },
        { name: 'featured', type: 'bool' },
        { name: 'order', type: 'number' },
        { name: 'tags', type: 'json' }
      ]
    });
    console.log('  ✅ Gallery collection created');
  } catch (e) {
    console.log('  ⚠️  Gallery collection already exists');
  }

  // 7. Service Areas collection (Advanced feature)
  try {
    await pb.collections.create({
      name: 'service_areas',
      type: 'base',
      schema: [
        { name: 'area_name', type: 'text', required: true },
        { name: 'postcodes', type: 'json' },
        { name: 'coverage_radius', type: 'number' },
        { name: 'additional_fee', type: 'number' },
        { name: 'active', type: 'bool', required: true },
        { name: 'description', type: 'text' },
        { name: 'order', type: 'number' }
      ]
    });
    console.log('  ✅ Service Areas collection created');
  } catch (e) {
    console.log('  ⚠️  Service Areas collection already exists');
  }

  // 8. Contacts collection (Advanced feature)
  try {
    await pb.collections.create({
      name: 'contacts',
      type: 'base',
      schema: [
        { name: 'name', type: 'text', required: true },
        { name: 'email', type: 'email', required: true },
        { name: 'phone', type: 'text' },
        { name: 'subject', type: 'text' },
        { name: 'message', type: 'editor', required: true },
        { name: 'source', type: 'text' },
        { name: 'status', type: 'select', options: { values: ['new', 'contacted', 'responded', 'resolved'] } }
      ]
    });
    console.log('  ✅ Contacts collection created');
  } catch (e) {
    console.log('  ⚠️  Contacts collection already exists');
  }

  // 9. Site Settings collection (Advanced feature)
  try {
    await pb.collections.create({
      name: 'site_settings',
      type: 'base',
      schema: [
        { name: 'key', type: 'text', required: true },
        { name: 'value', type: 'json' },
        { name: 'category', type: 'text' },
        { name: 'description', type: 'text' },
        { name: 'type', type: 'text' }
      ]
    });
    console.log('  ✅ Site Settings collection created');
  } catch (e) {
    console.log('  ⚠️  Site Settings collection already exists');
  }
}

async function seedCriticalData(pb) {
  console.log('🌱 Seeding critical data...');

  // Sample services (CRITICAL)
  const services = [
    {
      title: 'House Clearance',
      description: 'Complete house clearance service including furniture, appliances, and personal belongings. We handle everything from single rooms to entire properties with care and professionalism.',
      short_description: 'Full or partial house clearance with professional care',
      price_from: 150,
      price_to: 800,
      features: ['Free quotation', 'Fully insured', 'Same day service available', 'Eco-friendly disposal'],
      availability: true,
      order: 1
    },
    {
      title: 'Office Clearance',
      description: 'Efficient office clearance service for businesses of all sizes. We safely dispose of IT equipment, furniture, and confidential documents with secure data destruction.',
      short_description: 'Professional office and commercial clearance',
      price_from: 200,
      price_to: 1200,
      features: ['Secure data destruction', 'Certificate of disposal', 'Out of hours service', 'Furniture donation'],
      availability: true,
      order: 2
    },
    {
      title: 'Garden Clearance',
      description: 'Garden waste removal including green waste, soil, rubble, and old garden furniture. We help you transform and reclaim your outdoor space.',
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
      console.log(`  ✅ Service "${service.title}" created`);
    } catch (e) {
      console.log(`  ⚠️  Service "${service.title}" already exists`);
    }
  }

  // Sample service areas
  const serviceAreas = [
    {
      area_name: 'Manchester City Centre',
      postcodes: ['M1', 'M2', 'M3', 'M4', 'M5'],
      coverage_radius: 5,
      additional_fee: 0,
      active: true,
      description: 'Central Manchester coverage area',
      order: 1
    },
    {
      area_name: 'Greater Manchester',
      postcodes: ['M6', 'M7', 'M8', 'M9', 'M10', 'M11', 'M12', 'M13', 'M14', 'M15', 'M16', 'M17', 'M18', 'M19', 'M20'],
      coverage_radius: 15,
      additional_fee: 25,
      active: true,
      description: 'Extended Manchester coverage with small additional fee',
      order: 2
    }
  ];

  for (const area of serviceAreas) {
    try {
      await pb.collection('service_areas').create(area);
      console.log(`  ✅ Service area "${area.area_name}" created`);
    } catch (e) {
      console.log(`  ⚠️  Service area "${area.area_name}" already exists`);
    }
  }

  console.log('✅ Critical data seeded successfully');
}

// Run the setup
setupMissingCollections();