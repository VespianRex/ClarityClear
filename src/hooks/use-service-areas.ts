'use client';

import useSWR from 'swr';
import pb from '@/lib/pocketbase';

export interface ServiceArea {
  id: string;
  area_name: string;
  postcodes: string[];
  coverage_radius: number;
  additional_fee: number;
  active: boolean;
  description: string;
  order: number;
  created: string;
  updated: string;
}

// Custom hook for service areas
export function useServiceAreas() {
  const { data, error, isLoading } = useSWR('service-areas', async () => {
    return await pb.collection('service_areas').getFullList({
      sort: 'order,area_name',
      filter: 'active = true',
    });
  });

  return {
    serviceAreas: (data as unknown as ServiceArea[]) || [],
    isLoading,
    error,
  };
}

// Helper function to check if a postcode is covered
export function checkPostcodeCoverage(
  postcode: string,
  serviceAreas: ServiceArea[]
) {
  const normalizedPostcode = postcode.trim().toUpperCase();

  const coveredArea = serviceAreas.find(area =>
    area.postcodes.some(pc => normalizedPostcode.startsWith(pc.toUpperCase()))
  );

  return {
    covered: !!coveredArea,
    area: coveredArea,
    additionalFee: coveredArea?.additional_fee || 0,
  };
}
