'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Settings, DollarSign, Mail, MapPin, Star } from 'lucide-react';
import { useSettings, settingsService } from '@/lib/settings-service';
import { LoadingSpinner } from '@/components/ui/loading-spinner';

interface FeatureToggle {
  key: string;
  label: string;
  description: string;
  category: string;
  icon: React.ComponentType<any>;
  requiresSetup?: boolean;
}

const featureToggles: FeatureToggle[] = [
  // Revenue Features (Phase C)
  {
    key: 'pricing_calculator',
    label: 'Dynamic Pricing Calculator',
    description:
      'Show instant price estimates based on property size and service type',
    category: 'Revenue Features',
    icon: DollarSign,
    requiresSetup: false,
  },
  {
    key: 'online_payments',
    label: 'Online Payments',
    description: 'Accept deposits and payments through Stripe integration',
    category: 'Revenue Features',
    icon: DollarSign,
    requiresSetup: true,
  },
  {
    key: 'review_automation',
    label: 'Review Automation',
    description:
      'Automatically collect customer reviews after service completion',
    category: 'Revenue Features',
    icon: Star,
    requiresSetup: false,
  },

  // Business Operations
  {
    key: 'email.notifications_enabled',
    label: 'Email Notifications',
    description: 'Send booking confirmations and admin notifications',
    category: 'Business Operations',
    icon: Mail,
    requiresSetup: false,
  },
  {
    key: 'contact.whatsapp_enabled',
    label: 'WhatsApp Integration',
    description: 'Enable WhatsApp contact buttons throughout the site',
    category: 'Business Operations',
    icon: MapPin,
    requiresSetup: false,
  },

  // UI/UX Features
  {
    key: 'ui.show_testimonials',
    label: 'Customer Testimonials',
    description: 'Display customer reviews and ratings on the homepage',
    category: 'User Experience',
    icon: Star,
    requiresSetup: false,
  },
  {
    key: 'ui.show_service_areas',
    label: 'Service Area Display',
    description: 'Show service coverage areas and postcode checker',
    category: 'User Experience',
    icon: MapPin,
    requiresSetup: false,
  },
  {
    key: 'services.show_pricing',
    label: 'Service Pricing Display',
    description: 'Show price ranges on service pages',
    category: 'User Experience',
    icon: DollarSign,
    requiresSetup: false,
  },
];

export function FeatureToggles() {
  const [features, setFeatures] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const { getSetting, setSetting } = useSettings();

  useEffect(() => {
    loadFeatures();
  }, []);

  const loadFeatures = async () => {
    setLoading(true);
    try {
      await settingsService.initialize();

      const featureStates: Record<string, boolean> = {};
      for (const toggle of featureToggles) {
        const value = await getSetting(
          toggle.key.startsWith('features.')
            ? toggle.key
            : `features.${toggle.key}`,
          false
        );
        featureStates[toggle.key] = value;
      }
      setFeatures(featureStates);
    } catch (error) {
      console.error('Failed to load features:', error);
    } finally {
      setLoading(false);
    }
  };

  const toggleFeature = async (key: string) => {
    const newValue = !features[key];
    const settingKey = key.startsWith('features.') ? key : `features.${key}`;

    const success = await setSetting(settingKey, newValue);
    if (success) {
      setFeatures(prev => ({ ...prev, [key]: newValue }));
    }
  };

  const groupedFeatures = featureToggles.reduce(
    (acc, toggle) => {
      if (!acc[toggle.category]) {
        acc[toggle.category] = [];
      }
      acc[toggle.category].push(toggle);
      return acc;
    },
    {} as Record<string, FeatureToggle[]>
  );

  if (loading) {
    return (
      <Card>
        <CardContent className="flex justify-center py-12">
          <LoadingSpinner size="lg" />
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Feature Management
          </CardTitle>
          <p className="text-sm text-muted-foreground">
            Control which features are enabled on your ClarityClear website.
            Revenue features can be disabled if not needed.
          </p>
        </CardHeader>
      </Card>

      {Object.entries(groupedFeatures).map(([category, toggles]) => (
        <Card key={category}>
          <CardHeader>
            <CardTitle className="text-lg">{category}</CardTitle>
            {category === 'Revenue Features' && (
              <Badge variant="secondary" className="w-fit">
                Can be disabled for clients
              </Badge>
            )}
          </CardHeader>
          <CardContent className="space-y-4">
            {toggles.map((toggle, index) => (
              <div key={toggle.key}>
                <div className="flex items-center justify-between">
                  <div className="flex items-start gap-3 flex-1">
                    <toggle.icon className="h-5 w-5 text-accent mt-1" />
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <Label htmlFor={toggle.key} className="font-medium">
                          {toggle.label}
                        </Label>
                        {toggle.requiresSetup && (
                          <Badge variant="outline" className="text-xs">
                            Setup Required
                          </Badge>
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground mt-1">
                        {toggle.description}
                      </p>
                    </div>
                  </div>
                  <Switch
                    id={toggle.key}
                    checked={features[toggle.key] || false}
                    onCheckedChange={() => toggleFeature(toggle.key)}
                  />
                </div>
                {index < toggles.length - 1 && <Separator className="mt-4" />}
              </div>
            ))}
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
