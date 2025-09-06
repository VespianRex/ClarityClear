'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Home, Building, Trees } from 'lucide-react';

const step1Schema = z.object({
  serviceType: z.enum(['house', 'office', 'garden'], {
    required_error: 'Please select a service type',
  }),
  propertySize: z.string().min(1, 'Please select property size'),
  urgency: z.enum(['asap', 'week', 'flexible'], {
    required_error: 'Please select urgency level',
  }),
});

type Step1Data = z.infer<typeof step1Schema>;

interface BookingFormStep1Props {
  onNext: (_: Step1Data) => void;
  initialData?: Partial<Step1Data>;
}

export function BookingFormStep1({
  onNext,
  initialData,
}: BookingFormStep1Props) {
  const {
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
  } = useForm<Step1Data>({
    resolver: zodResolver(step1Schema),
    defaultValues: initialData,
  });

  const serviceType = watch('serviceType');
  const urgency = watch('urgency');

  const serviceOptions = [
    {
      value: 'house',
      label: 'House Clearance',
      description: 'Full or partial house clearance',
      icon: Home,
    },
    {
      value: 'office',
      label: 'Office Clearance',
      description: 'Commercial and office spaces',
      icon: Building,
    },
    {
      value: 'garden',
      label: 'Garden Clearance',
      description: 'Garden waste and outdoor areas',
      icon: Trees,
    },
  ];

  const urgencyOptions = [
    { value: 'asap', label: 'ASAP', description: 'Within 24-48 hours' },
    { value: 'week', label: 'Within a week', description: 'Next 7 days' },
    {
      value: 'flexible',
      label: 'Flexible',
      description: 'No rush, best price',
    },
  ];

  const propertySizeOptions = {
    house: [
      '1 bedroom',
      '2 bedrooms',
      '3 bedrooms',
      '4+ bedrooms',
      'Entire house',
    ],
    office: ['Small office', 'Medium office', 'Large office', 'Warehouse'],
    garden: ['Small garden', 'Medium garden', 'Large garden', 'Multiple areas'],
  };

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="text-2xl font-headline text-primary">
          Step 1: Service Details
        </CardTitle>
        <p className="text-muted-foreground">
          Tell us what type of clearance you need
        </p>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onNext)} className="space-y-6">
          {/* Service Type Selection */}
          <div className="space-y-3">
            <Label className="text-base font-medium">
              What service do you need?
            </Label>
            <RadioGroup
              value={serviceType}
              onValueChange={value => setValue('serviceType', value as any)}
              className="grid grid-cols-1 gap-3"
            >
              {serviceOptions.map(option => {
                const Icon = option.icon;
                return (
                  <div
                    key={option.value}
                    className="flex items-center space-x-3"
                  >
                    <RadioGroupItem value={option.value} id={option.value} />
                    <Label
                      htmlFor={option.value}
                      className="flex items-center space-x-3 cursor-pointer flex-1 p-3 rounded-lg border hover:bg-accent/5"
                    >
                      <Icon className="h-5 w-5 text-accent" />
                      <div>
                        <div className="font-medium">{option.label}</div>
                        <div className="text-sm text-muted-foreground">
                          {option.description}
                        </div>
                      </div>
                    </Label>
                  </div>
                );
              })}
            </RadioGroup>
            {errors.serviceType && (
              <p className="text-sm text-red-500">
                {errors.serviceType.message}
              </p>
            )}
          </div>

          {/* Property Size */}
          {serviceType && (
            <div className="space-y-3">
              <Label className="text-base font-medium">Property size</Label>
              <Select onValueChange={value => setValue('propertySize', value)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select size" />
                </SelectTrigger>
                <SelectContent>
                  {propertySizeOptions[
                    serviceType as keyof typeof propertySizeOptions
                  ]?.map(size => (
                    <SelectItem key={size} value={size}>
                      {size}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.propertySize && (
                <p className="text-sm text-red-500">
                  {errors.propertySize.message}
                </p>
              )}
            </div>
          )}

          {/* Urgency */}
          <div className="space-y-3">
            <Label className="text-base font-medium">How urgent is this?</Label>
            <RadioGroup
              value={urgency}
              onValueChange={value => setValue('urgency', value as any)}
              className="grid grid-cols-1 gap-2"
            >
              {urgencyOptions.map(option => (
                <div key={option.value} className="flex items-center space-x-3">
                  <RadioGroupItem
                    value={option.value}
                    id={`urgency-${option.value}`}
                  />
                  <Label
                    htmlFor={`urgency-${option.value}`}
                    className="cursor-pointer flex-1 p-2 rounded border hover:bg-accent/5"
                  >
                    <div className="font-medium">{option.label}</div>
                    <div className="text-sm text-muted-foreground">
                      {option.description}
                    </div>
                  </Label>
                </div>
              ))}
            </RadioGroup>
            {errors.urgency && (
              <p className="text-sm text-red-500">{errors.urgency.message}</p>
            )}
          </div>

          <Button type="submit" className="w-full" size="lg">
            Continue to Property Details
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
