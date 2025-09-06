'use client';

import useSWR from 'swr';
import pb from '@/lib/pocketbase';

export interface GalleryItem {
  id: string;
  title: string;
  description: string;
  before_image: string;
  after_image: string;
  before_image_url: string;
  after_image_url: string;
  service_type: string;
  location: string;
  completion_date: string;
  featured: boolean;
  order: number;
  tags: string[];
  created: string;
  updated: string;
}

// Custom hook for gallery items
export function useGallery(limit?: number, serviceFilter?: string) {
  const { data, error, isLoading } = useSWR(
    `gallery-${limit || 'all'}-${serviceFilter || 'all'}`,
    async () => {
      let filter = 'featured = true';
      if (serviceFilter) {
        filter += ` && service_type = "${serviceFilter}"`;
      }

      const options: any = {
        sort: '-featured,-order,-completion_date',
        filter,
        expand: 'service_type',
      };

      if (limit) {
        const result = await pb
          .collection('gallery')
          .getList(1, limit, options);
        return result.items;
      } else {
        return await pb.collection('gallery').getFullList(options);
      }
    }
  );

  // Process the data to include image URLs
  const processedData = (data || []).map((item: any) => ({
    ...item,
    before_image_url: item.before_image
      ? pb.files.getUrl(item, item.before_image)
      : '/placeholder-before.jpg',
    after_image_url: item.after_image
      ? pb.files.getUrl(item, item.after_image)
      : '/placeholder-after.jpg',
  }));

  return {
    galleryItems: processedData as GalleryItem[],
    isLoading,
    error,
  };
}

// Hook for featured gallery items only
export function useFeaturedGallery(limit = 6) {
  const { data, error, isLoading } = useSWR(
    `featured-gallery-${limit}`,
    async () => {
      const result = await pb.collection('gallery').getList(1, limit, {
        sort: '-order,-completion_date',
        filter: 'featured = true',
        expand: 'service_type',
      });
      return result.items;
    }
  );

  const processedData = (data || []).map((item: any) => ({
    ...item,
    before_image_url: item.before_image
      ? pb.files.getUrl(item, item.before_image)
      : '/placeholder-before.jpg',
    after_image_url: item.after_image
      ? pb.files.getUrl(item, item.after_image)
      : '/placeholder-after.jpg',
  }));

  return {
    galleryItems: processedData as GalleryItem[],
    isLoading,
    error,
  };
}
