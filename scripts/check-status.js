#!/usr/bin/env node

/**
 * PocketBase Collections Status Check
 * This script verifies all collections exist and shows their record counts
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

async function getCollections(token) {
  const response = await fetch(`${POCKETBASE_URL}/api/collections`, {
    method: 'GET',
    headers: {
      'Authorization': token,
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to get collections: ${response.statusText}`);
  }

  const data = await response.json();
  return data.items;
}

async function getRecordCount(token, collectionName) {
  try {
    const response = await fetch(`${POCKETBASE_URL}/api/collections/${collectionName}/records?perPage=1`, {
      method: 'GET',
      headers: {
        'Authorization': token,
      },
    });

    if (!response.ok) {
      return 'Error';
    }

    const data = await response.json();
    return data.totalItems;
  } catch (error) {
    return 'Error';
  }
}

async function checkStatus() {
  try {
    console.log('🔍 Checking PocketBase collections status...\n');
    
    // Authenticate
    const token = await authenticateAdmin();
    console.log('✅ Admin authenticated\n');

    // Get all collections
    const collections = await getCollections(token);
    
    // Expected collections
    const expectedCollections = [
      'services',
      'testimonials', 
      'faqs',
      'team_members',
      'bookings',
      'articles',
      'settings',
      'review_campaigns',
      'gallery',
      'service_areas',
      'contacts',
      'site_settings'
    ];

    console.log('📊 COLLECTION STATUS:');
    console.log('═'.repeat(50));
    
    const existingCollections = collections.map(c => c.name);
    
    for (const collectionName of expectedCollections) {
      const exists = existingCollections.includes(collectionName);
      const count = exists ? await getRecordCount(token, collectionName) : 'N/A';
      const status = exists ? '✅' : '❌';
      const priority = ['services', 'bookings', 'testimonials', 'faqs'].includes(collectionName) ? '[CRITICAL]' : '[FEATURE]';
      
      console.log(`${status} ${collectionName.padEnd(20)} ${count.toString().padStart(5)} records ${priority}`);
    }

    console.log('═'.repeat(50));
    
    const missingCount = expectedCollections.filter(name => !existingCollections.includes(name)).length;
    const totalCount = expectedCollections.length;
    const completedCount = totalCount - missingCount;
    
    console.log(`\n📈 SUMMARY:`);
    console.log(`   Total Expected: ${totalCount}`);
    console.log(`   ✅ Completed: ${completedCount}`);
    console.log(`   ❌ Missing: ${missingCount}`);
    console.log(`   📊 Progress: ${Math.round((completedCount/totalCount)*100)}%`);
    
    if (missingCount === 0) {
      console.log('\n🎉 ALL COLLECTIONS ARE SET UP CORRECTLY!');
      console.log('   The ClarityClear website should now be fully functional.');
    } else {
      console.log('\n⚠️  Some collections are still missing.');
      console.log('   Critical features may not work properly.');
    }

    console.log(`\n📊 Admin panel: ${POCKETBASE_URL}/_/`);

  } catch (error) {
    console.error('❌ Status check failed:', error.message);
    process.exit(1);
  }
}

// Run the status check
checkStatus();