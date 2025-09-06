#!/usr/bin/env node

/**
 * Simple PocketBase Collections Setup
 * This script creates collections using direct HTTP requests
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

async function createCollection(token, collectionData) {
  const response = await fetch(`${POCKETBASE_URL}/api/collections`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': token,
    },
    body: JSON.stringify(collectionData),
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(`Failed to create collection: ${JSON.stringify(errorData)}`);
  }

  return await response.json();
}

async function setupCollections() {
  try {
    console.log('🚀 Setting up PocketBase collections...');
    
    // Authenticate
    const token = await authenticateAdmin();
    console.log('✅ Admin authenticated');

    // Collection definitions
    const collections = [
      // Services collection
      {
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
          { name: 'features', type: 'json', options: { maxSize: 2000000 } },
          { name: 'availability', type: 'bool', required: true },
          { name: 'order', type: 'number' }
        ]
      },
      
      // Bookings collection
      {
        name: 'bookings',
        type: 'base',
        schema: [
          { name: 'customer_name', type: 'text', required: true },
          { name: 'customer_email', type: 'email', required: true },
          { name: 'customer_phone', type: 'text', required: true },
          { name: 'property_address', type: 'editor' },
          { name: 'postcode', type: 'text', required: true },
          { name: 'property_size', type: 'text' },
          { name: 'urgency', type: 'select', options: { values: ['asap', 'week', 'flexible'], maxSelect: 1 } },
          { name: 'access_info', type: 'editor' },
          { name: 'special_requirements', type: 'editor' },
          { name: 'preferred_contact', type: 'select', options: { values: ['phone', 'email', 'whatsapp'], maxSelect: 1 } },
          { name: 'best_time_call', type: 'text' },
          { name: 'status', type: 'select', options: { values: ['new', 'contacted', 'quoted', 'booked', 'completed'], maxSelect: 1 } },
          { name: 'estimated_price', type: 'number' },
          { name: 'notes', type: 'editor' }
        ]
      },

      // Articles collection
      {
        name: 'articles',
        type: 'base',
        schema: [
          { name: 'title', type: 'text', required: true },
          { name: 'slug', type: 'text', required: true },
          { name: 'content', type: 'editor' },
          { name: 'excerpt', type: 'text' },
          { name: 'category', type: 'text' },
          { name: 'tags', type: 'json', options: { maxSize: 1000000 } },
          { name: 'featured_image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
          { name: 'published', type: 'bool' },
          { name: 'publish_date', type: 'date' }
        ]
      },

      // Settings collection
      {
        name: 'settings',
        type: 'base',
        schema: [
          { name: 'key', type: 'text', required: true },
          { name: 'value', type: 'json', options: { maxSize: 2000000 } },
          { name: 'description', type: 'text' }
        ]
      }
    ];

    // Create collections
    for (const collection of collections) {
      try {
        await createCollection(token, collection);
        console.log(`  ✅ ${collection.name} collection created`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`  ⚠️  ${collection.name} collection already exists`);
        } else {
          console.log(`  ❌ Failed to create ${collection.name}: ${error.message}`);
        }
      }
    }

    console.log('🎉 Basic collections setup completed!');
    console.log(`📊 Admin panel: ${POCKETBASE_URL}/_/`);

  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Run the setup
setupCollections();