'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Calculator } from 'lucide-react';
import { useSettings } from '@/lib/settings-service';
import { useServices } from '@/hooks/use-pocketbase';
import Link from 'next/link';

interface PricingCalculatorProps {
  className?: string;
  showTitle?: boolean;
}

interface PricingResult {
  basePrice: number;
  additionalFees: number;
  total: number;
  breakdown: string[];
  serviceType: string;
  propertySize: string;
}

const propertyMultipliers = {
  '1-bed': 1.0,
  '2-bed': 1.3,
  '3-bed': 1.6,
  '4-bed': 2.0,
  '5-bed': 2.5,
  'commercial-small': 1.8,
  'commercial-large': 3.0,
  'garden-small': 0.8,
  'garden-large': 1.5,
};

const urgencyMultipliers = {
  flexible: 1.0,
  week: 1.1,
  asap: 1.3,
};

export function PriceCalculator({
  className,
  showTitle = true,
}: PricingCalculatorProps) {
  const [isEnabled, setIsEnabled] = useState(false);
  const [selectedService, setSelectedService] = useState('');
  const [propertySize, setPropertySize] = useState('');
  const [urgency, setUrgency] = useState('');
  const [result, setResult] = useState<PricingResult | null>(null);

  const { getSetting } = useSettings();
  const { services } = useServices();

  useEffect(() => {
    checkIfEnabled();
  }, []);

  const checkIfEnabled = async () => {
    const enabled = await getSetting('features.pricing_calculator', true);
    setIsEnabled(enabled);
  };

  const calculatePrice = () => {
    if (!selectedService || !propertySize || !urgency) return;

    const service = services.find(s => s.id === selectedService);
    if (!service) return;

    const basePrice = service.price_from || 150;
    const propertyMultiplier =
      propertyMultipliers[propertySize as keyof typeof propertyMultipliers] ||
      1.0;
    const urgencyMultiplier =
      urgencyMultipliers[urgency as keyof typeof urgencyMultipliers] || 1.0;

    const adjustedPrice = basePrice * propertyMultiplier;
    const urgencyFee = adjustedPrice * (urgencyMultiplier - 1);
    const total = adjustedPrice + urgencyFee;

    const breakdown = [
      `Base ${service.title}: £${basePrice}`,
      `Property size adjustment: ${propertyMultiplier}x`,
      ...(urgencyFee > 0 ? [`Urgency fee: £${urgencyFee.toFixed(0)}`] : []),
    ];

    setResult({
      basePrice: adjustedPrice,
      additionalFees: urgencyFee,
      total,
      breakdown,
      serviceType: service.title,
      propertySize: propertySize.replace('-', ' ').toUpperCase(),
    });
  };

  if (!isEnabled) {
    return null;
  }

  return (
    <Card className={className}>
      <CardHeader>
        {showTitle && (
          <CardTitle className="flex items-center gap-2">
            <Calculator className="h-5 w-5 text-accent" />
            Instant Price Calculator
          </CardTitle>
        )}
      </CardHeader>
      <CardContent className="space-y-4">
        {!result ? (
          <>
            <div className="space-y-2">
              <Label>Service Type</Label>
              <Select
                value={selectedService}
                onValueChange={setSelectedService}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a service" />
                </SelectTrigger>
                <SelectContent>
                  {services.map(service => (
                    <SelectItem key={service.id} value={service.id}>
                      {service.title} (from £{service.price_from || 150})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Property Size</Label>
              <Select value={propertySize} onValueChange={setPropertySize}>
                <SelectTrigger>
                  <SelectValue placeholder="Select property size" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1-bed">1 Bedroom</SelectItem>
                  <SelectItem value="2-bed">2 Bedroom</SelectItem>
                  <SelectItem value="3-bed">3 Bedroom</SelectItem>
                  <SelectItem value="4-bed">4+ Bedroom</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Urgency</Label>
              <Select value={urgency} onValueChange={setUrgency}>
                <SelectTrigger>
                  <SelectValue placeholder="Select urgency" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="flexible">Flexible</SelectItem>
                  <SelectItem value="week">Within a week</SelectItem>
                  <SelectItem value="asap">ASAP</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <Button
              onClick={calculatePrice}
              className="w-full"
              disabled={!selectedService || !propertySize || !urgency}
            >
              Calculate Price
            </Button>
          </>
        ) : (
          <div className="space-y-4">
            <div className="text-center p-4 bg-accent/10 rounded-lg">
              <div className="text-2xl font-bold text-accent">
                £{result.total.toFixed(0)}
              </div>
              <p className="text-sm text-muted-foreground">Estimated price</p>
            </div>

            <Button asChild className="w-full">
              <Link href="/booking">Book Now</Link>
            </Button>

            <Button
              variant="outline"
              onClick={() => setResult(null)}
              className="w-full"
            >
              Recalculate
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
