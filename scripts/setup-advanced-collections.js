#!/usr/bin/env node

/**
 * Advanced PocketBase Collections Setup
 * This script creates the remaining advanced collections
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

async function setupAdvancedCollections() {
  try {
    console.log('🚀 Setting up advanced PocketBase collections...');
    
    // Authenticate
    const token = await authenticateAdmin();
    console.log('✅ Admin authenticated');

    // Advanced collection definitions
    const collections = [
      // Review Campaigns collection
      {
        name: 'review_campaigns',
        type: 'base',
        schema: [
          { name: 'customer_email', type: 'email', required: true },
          { name: 'customer_name', type: 'text', required: true },
          { name: 'service_type', type: 'text', required: true },
          { name: 'completion_date', type: 'date', required: true },
          { name: 'review_request_sent', type: 'bool' },
          { name: 'review_request_date', type: 'date' },
          { name: 'follow_up_sent', type: 'bool' },
          { name: 'follow_up_date', type: 'date' },
          { name: 'review_received', type: 'bool' },
          { name: 'review_platform', type: 'select', options: { values: ['google', 'facebook', 'website', 'trustpilot'], maxSelect: 1 } },
          { name: 'review_rating', type: 'number' },
          { name: 'review_url', type: 'url' },
          { name: 'status', type: 'select', options: { values: ['pending', 'sent', 'responded', 'completed', 'opted_out'], maxSelect: 1 } }
        ]
      },

      // Gallery collection
      {
        name: 'gallery',
        type: 'base',
        schema: [
          { name: 'title', type: 'text', required: true },
          { name: 'description', type: 'text' },
          { name: 'before_image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
          { name: 'after_image', type: 'file', options: { maxSelect: 1, maxSize: 5242880 } },
          { name: 'service_type', type: 'text' },
          { name: 'location', type: 'text' },
          { name: 'completion_date', type: 'date' },
          { name: 'featured', type: 'bool' },
          { name: 'order', type: 'number' },
          { name: 'tags', type: 'json', options: { maxSize: 1000000 } }
        ]
      },

      // Service Areas collection
      {
        name: 'service_areas',
        type: 'base',
        schema: [
          { name: 'area_name', type: 'text', required: true },
          { name: 'postcodes', type: 'json', options: { maxSize: 1000000 } },
          { name: 'coverage_radius', type: 'number' },
          { name: 'additional_fee', type: 'number' },
          { name: 'active', type: 'bool', required: true },
          { name: 'description', type: 'text' },
          { name: 'order', type: 'number' }
        ]
      },

      // Contacts collection
      {
        name: 'contacts',
        type: 'base',
        schema: [
          { name: 'name', type: 'text', required: true },
          { name: 'email', type: 'email', required: true },
          { name: 'phone', type: 'text' },
          { name: 'subject', type: 'text' },
          { name: 'message', type: 'editor' },
          { name: 'source', type: 'text' },
          { name: 'status', type: 'select', options: { values: ['new', 'contacted', 'responded', 'resolved'], maxSelect: 1 } }
        ]
      },

      // Site Settings collection
      {
        name: 'site_settings',
        type: 'base',
        schema: [
          { name: 'key', type: 'text', required: true },
          { name: 'value', type: 'json', options: { maxSize: 2000000 } },
          { name: 'category', type: 'text' },
          { name: 'description', type: 'text' },
          { name: 'type', type: 'text' }
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

    console.log('🎉 Advanced collections setup completed!');
    console.log(`📊 Admin panel: ${POCKETBASE_URL}/_/`);

  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Run the setup
setupAdvancedCollections();