#!/usr/bin/env node

/**
 * Seed Sample Data for ClarityClear PocketBase Collections
 */

const POCKETBASE_URL = 'http://localhost:8090';

async function authenticateAdmin() {
  const response = await fetch(`${POCKETBASE_URL}/api/admins/auth-with-password`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      identity: 'admin@clarityclear.com',
      password: 'ClarityClear123',
    }),
  });

  if (!response.ok) {
    throw new Error(`Authentication failed: ${response.statusText}`);
  }

  const data = await response.json();
  return data.token;
}

async function createRecord(token, collection, recordData) {
  const response = await fetch(`${POCKETBASE_URL}/api/collections/${collection}/records`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': token,
    },
    body: JSON.stringify(recordData),
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(`Failed to create record: ${JSON.stringify(errorData)}`);
  }

  return await response.json();
}

async function seedData() {
  try {
    console.log('🌱 Seeding sample data...');
    
    // Authenticate
    const token = await authenticateAdmin();
    console.log('✅ Admin authenticated');

    // Sample services
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

    // Create services
    console.log('📦 Creating services...');
    for (const service of services) {
      try {
        await createRecord(token, 'services', service);
        console.log(`  ✅ Service "${service.title}" created`);
      } catch (error) {
        console.log(`  ⚠️  Service "${service.title}" already exists or failed`);
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
      },
      {
        area_name: 'Liverpool',
        postcodes: ['L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'L10'],
        coverage_radius: 10,
        additional_fee: 35,
        active: true,
        description: 'Liverpool and surrounding areas',
        order: 3
      }
    ];

    // Create service areas
    console.log('🗺️ Creating service areas...');
    for (const area of serviceAreas) {
      try {
        await createRecord(token, 'service_areas', area);
        console.log(`  ✅ Service area "${area.area_name}" created`);
      } catch (error) {
        console.log(`  ⚠️  Service area "${area.area_name}" already exists or failed`);
      }
    }

    // Sample FAQs (if collection exists)
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

    // Create FAQs
    console.log('❓ Creating FAQs...');
    for (const faq of faqs) {
      try {
        await createRecord(token, 'faqs', faq);
        console.log(`  ✅ FAQ "${faq.question.substring(0, 30)}..." created`);
      } catch (error) {
        console.log(`  ⚠️  FAQ already exists or failed`);
      }
    }

    console.log('🎉 Sample data seeded successfully!');
    console.log(`📊 Admin panel: ${POCKETBASE_URL}/_/`);

  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  }
}

// Run the seeding
seedData();