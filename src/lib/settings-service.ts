'use client';

import pb from '@/lib/pocketbase';

export interface SiteSetting {
  id: string;
  key: string;
  value: any;
  category: string;
  description: string;
  type: 'boolean' | 'string' | 'number' | 'json';
  public: boolean;
  created: string;
  updated: string;
}

// Default settings for ClarityClear
export const defaultSettings = {
  // Revenue Features (Phase C - Toggleable)
  'features.pricing_calculator': {
    value: true,
    category: 'features',
    description: 'Enable dynamic pricing calculator',
    type: 'boolean' as const,
    public: true,
  },
  'features.online_payments': {
    value: false,
    category: 'features',
    description: 'Enable online payment processing',
    type: 'boolean' as const,
    public: true,
  },
  'features.review_automation': {
    value: true,
    category: 'features',
    description: 'Enable automated review collection',
    type: 'boolean' as const,
    public: false,
  },

  // Business Operations
  'email.notifications_enabled': {
    value: true,
    category: 'email',
    description: 'Enable email notifications',
    type: 'boolean' as const,
    public: false,
  },
  'email.admin_email': {
    value: 'admin@clarityclear.com',
    category: 'email',
    description: 'Admin notification email',
    type: 'string' as const,
    public: false,
  },

  // Service Configuration
  'services.show_pricing': {
    value: true,
    category: 'services',
    description: 'Show pricing information on services',
    type: 'boolean' as const,
    public: true,
  },
  'services.require_postcode_check': {
    value: false,
    category: 'services',
    description: 'Require postcode verification before booking',
    type: 'boolean' as const,
    public: true,
  },

  // Contact & Communication
  'contact.whatsapp_enabled': {
    value: true,
    category: 'contact',
    description: 'Enable WhatsApp integration',
    type: 'boolean' as const,
    public: true,
  },
  'contact.phone_number': {
    value: '1234567890',
    category: 'contact',
    description: 'Business phone number',
    type: 'string' as const,
    public: true,
  },

  // UI/UX Settings
  'ui.show_testimonials': {
    value: true,
    category: 'ui',
    description: 'Display testimonials on homepage',
    type: 'boolean' as const,
    public: true,
  },
  'ui.show_service_areas': {
    value: true,
    category: 'ui',
    description: 'Display service area information',
    type: 'boolean' as const,
    public: true,
  },
};

class SettingsService {
  private cache: Map<string, any> = new Map();
  private initialized = false;

  async initialize() {
    if (this.initialized) return;

    try {
      // Create default settings if they don't exist
      for (const [key, config] of Object.entries(defaultSettings)) {
        try {
          await pb
            .collection('site_settings')
            .getFirstListItem(`key = "${key}"`);
        } catch {
          // Setting doesn't exist, create it
          await pb.collection('site_settings').create({
            key,
            ...config,
          });
        }
      }

      this.initialized = true;
    } catch (error) {
      console.error('Failed to initialize settings:', error);
    }
  }

  async getSetting(key: string, defaultValue?: any): Promise<any> {
    try {
      if (this.cache.has(key)) {
        return this.cache.get(key);
      }

      const setting = await pb
        .collection('site_settings')
        .getFirstListItem(`key = "${key}"`);
      this.cache.set(key, setting.value);
      return setting.value;
    } catch {
      return defaultValue !== undefined
        ? defaultValue
        : defaultSettings[key as keyof typeof defaultSettings]?.value;
    }
  }

  async setSetting(key: string, value: any): Promise<boolean> {
    try {
      const setting = await pb
        .collection('site_settings')
        .getFirstListItem(`key = "${key}"`);
      await pb.collection('site_settings').update(setting.id, { value });
      this.cache.set(key, value);
      return true;
    } catch {
      // Create new setting
      try {
        await pb.collection('site_settings').create({
          key,
          value,
          category: 'custom',
          description: `Custom setting: ${key}`,
          type:
            typeof value === 'boolean'
              ? 'boolean'
              : typeof value === 'number'
                ? 'number'
                : 'string',
          public: false,
        });
        this.cache.set(key, value);
        return true;
      } catch (error) {
        console.error('Failed to create setting:', error);
        return false;
      }
    }
  }

  async getPublicSettings(): Promise<Record<string, any>> {
    try {
      const settings = await pb.collection('site_settings').getFullList({
        filter: 'public = true',
      });

      const publicSettings: Record<string, any> = {};
      settings.forEach(setting => {
        publicSettings[setting.key] = setting.value;
      });

      return publicSettings;
    } catch (error) {
      console.error('Failed to get public settings:', error);
      return {};
    }
  }

  // Feature flag helpers
  async isFeatureEnabled(feature: string): Promise<boolean> {
    return await this.getSetting(`features.${feature}`, false);
  }

  async enableFeature(feature: string): Promise<boolean> {
    return await this.setSetting(`features.${feature}`, true);
  }

  async disableFeature(feature: string): Promise<boolean> {
    return await this.setSetting(`features.${feature}`, false);
  }

  clearCache() {
    this.cache.clear();
  }
}

export const settingsService = new SettingsService();

// React hook for settings
export function useSettings() {
  return {
    getSetting: settingsService.getSetting.bind(settingsService),
    setSetting: settingsService.setSetting.bind(settingsService),
    isFeatureEnabled: settingsService.isFeatureEnabled.bind(settingsService),
    enableFeature: settingsService.enableFeature.bind(settingsService),
    disableFeature: settingsService.disableFeature.bind(settingsService),
  };
}
