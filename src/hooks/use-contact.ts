'use client';

import { useState } from 'react';
import pb from '@/lib/pocketbase';

export interface ContactFormData {
  name: string;
  email: string;
  phone?: string;
  subject?: string;
  message: string;
  source?: string;
}

export function useCreateContact() {
  const [isSubmitting, setIsSubmitting] = useState(false);

  const createContact = async (data: ContactFormData) => {
    setIsSubmitting(true);
    try {
      const contact = await pb.collection('contacts').create({
        ...data,
        status: 'new',
        source: data.source || 'contact-form',
      });

      return { success: true, contact };
    } catch (error: any) {
      console.error('Contact submission error:', error);
      return {
        success: false,
        error: error.message || 'Failed to submit contact form',
      };
    } finally {
      setIsSubmitting(false);
    }
  };

  return { createContact, isSubmitting };
}
