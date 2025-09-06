import { NextResponse } from 'next/server';

export async function GET() {
  // Simple health check endpoint for monitoring
  return NextResponse.json(
    { 
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'nextjs'
    },
    { status: 200 }
  );
}