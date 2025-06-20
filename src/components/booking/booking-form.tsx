"use client";

import * as React from 'react';
import { useForm, FormProvider, Controller, useFormContext } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { BookingFormSchema, type BookingFormData, PersonalDetailsSchema, CollectionDetailsSchema } from '@/lib/schemas';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { cn } from "@/lib/utils";
import { CalendarIcon, CheckCircle, User, Package, CalendarDays } from "lucide-react";
import { format } from "date-fns";
import { useToast } from "@/hooks/use-toast";

const steps = [
  { id: 'personalDetails', name: 'Personal Details', icon: User, fields: ['fullName', 'email', 'phone', 'addressLine1', 'addressLine2', 'city', 'postcode'] as const, schema: PersonalDetailsSchema },
  { id: 'collectionDetails', name: 'Collection Details', icon: Package, fields: ['serviceType', 'itemDescription', 'estimatedVolume', 'accessRestrictions', 'preferredDate', 'preferredTime', 'hasParking'] as const, schema: CollectionDetailsSchema },
  { id: 'review', name: 'Review & Confirm', icon: CheckCircle },
];

const serviceTypes = ["House Clearance", "Office Clearance", "Garden Waste", "Builders Waste", "Partial Clearance", "Recycling/WEEE", "Hoarding Clearance"];
const volumeEstimates = ["Single Item", "Small Van Load (e.g., 1-2 rooms)", "Medium Van Load (e.g., small flat)", "Large Van Load (e.g., 2-3 bed house)", "Luton Van Load (e.g., 3+ bed house)", "Unsure / Other"];
const timeSlots = ["Morning (8am - 12pm)", "Afternoon (12pm - 4pm)", "Evening (4pm - 7pm)", "Flexible"];

export function BookingForm() {
  const [currentStep, setCurrentStep] = React.useState(0);
  const [formData, setFormData] = React.useState<Partial<BookingFormData>>({});
  const { toast } = useToast();

  const methods = useForm<BookingFormData>({
    resolver: zodResolver(BookingFormSchema),
    defaultValues: { // Initialize all fields to avoid uncontrolled to controlled input warnings
      fullName: '',
      email: '',
      phone: '',
      addressLine1: '',
      addressLine2: '',
      city: '',
      postcode: '',
      serviceType: '',
      itemDescription: '',
      estimatedVolume: '',
      accessRestrictions: '',
      preferredDate: undefined,
      preferredTime: '',
      hasParking: undefined,
    },
  });

  const { trigger, handleSubmit, getValues, formState: { errors } } = methods;

  const handleNext = async () => {
    const currentStepSchema = steps[currentStep].schema;
    let isValid = false;
    if (currentStepSchema) {
        isValid = await trigger(steps[currentStep].fields, { shouldFocus: true });
    } else { // For review step
        isValid = true;
    }

    if (isValid) {
      setFormData(prev => ({ ...prev, ...getValues() }));
      if (currentStep < steps.length - 1) {
        setCurrentStep(prev => prev + 1);
      } else {
        // Handle final submission
        console.log("Form Submitted:", getValues());
        toast({
          title: "Booking Request Sent!",
          description: "Thank you for your request. We will be in touch shortly.",
          variant: "default", // Changed to default as toast is for errors only, but example uses success
        });
        // Reset form or redirect
        methods.reset();
        setCurrentStep(0);
        setFormData({});
      }
    } else {
       toast({
          title: "Validation Error",
          description: "Please correct the errors in the form.",
          variant: "destructive",
        });
    }
  };

  const handlePrevious = () => {
    if (currentStep > 0) {
      setCurrentStep(prev => prev - 1);
    }
  };

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(handleNext)} className="space-y-8">
        <div className="mb-8 p-4 border rounded-lg shadow-sm">
          <ol className="flex items-center w-full text-sm font-medium text-center text-gray-500 dark:text-gray-400 sm:text-base">
            {steps.map((step, index) => (
              <li
                key={step.id}
                className={cn(
                  "flex md:w-full items-center",
                  index <= currentStep ? "text-accent dark:text-blue-500" : "",
                  index < steps.length -1 ? "sm:after:content-[''] after:w-full after:h-1 after:border-b after:border-gray-200 after:border-1 after:hidden sm:after:inline-block after:mx-6 xl:after:mx-10 dark:after:border-gray-700" : ""
                )}
              >
                <span className={cn(
                    "flex items-center after:content-['/'] sm:after:hidden after:mx-2 after:text-gray-200 dark:after:text-gray-500",
                     index < steps.length -1 ? "" : "after:hidden"
                )}>
                  {index < currentStep ? (
                     <CheckCircle className="w-4 h-4 mr-2 sm:w-5 sm:h-5 shrink-0" />
                  ) : (
                    <step.icon className="w-4 h-4 mr-2 sm:w-5 sm:h-5 shrink-0" />
                  )}
                  {step.name}
                </span>
              </li>
            ))}
          </ol>
        </div>

        {currentStep === 0 && <PersonalDetailsForm />}
        {currentStep === 1 && <CollectionDetailsForm />}
        {currentStep === 2 && <ReviewForm formData={getValues()} />}

        <div className="flex justify-between pt-4">
          <Button type="button" variant="outline" onClick={handlePrevious} disabled={currentStep === 0}>
            Previous
          </Button>
          <Button type="submit" variant="default" className="bg-accent hover:bg-accent/90 text-accent-foreground">
            {currentStep === steps.length - 1 ? 'Submit Request' : 'Next'}
          </Button>
        </div>
      </form>
    </FormProvider>
  );
}

function PersonalDetailsForm() {
  const { control } = useFormContext<BookingFormData>();
  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-headline font-semibold text-primary">Your Details</h2>
      <div className="grid md:grid-cols-2 gap-6">
        <FormField
          control={control}
          name="fullName"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Full Name</FormLabel>
              <FormControl><Input placeholder="e.g. John Doe" {...field} /></FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email Address</FormLabel>
              <FormControl><Input type="email" placeholder="e.g. john.doe@example.com" {...field} /></FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </div>
      <FormField
        control={control}
        name="phone"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Phone Number</FormLabel>
            <FormControl><Input type="tel" placeholder="e.g. 07123456789" {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      <h3 className="text-xl font-headline font-semibold text-primary pt-4">Collection Address</h3>
      <FormField
        control={control}
        name="addressLine1"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Address Line 1</FormLabel>
            <FormControl><Input placeholder="e.g. 123 Main Street" {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="addressLine2"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Address Line 2 (Optional)</FormLabel>
            <FormControl><Input placeholder="e.g. Apartment 4B" {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      <div className="grid md:grid-cols-2 gap-6">
        <FormField
          control={control}
          name="city"
          render={({ field }) => (
            <FormItem>
              <FormLabel>City / Town</FormLabel>
              <FormControl><Input placeholder="e.g. London" {...field} /></FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={control}
          name="postcode"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Postcode</FormLabel>
              <FormControl><Input placeholder="e.g. SW1A 1AA" {...field} /></FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </div>
    </div>
  );
}

function CollectionDetailsForm() {
  const { control } = useFormContext<BookingFormData>();
  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-headline font-semibold text-primary">Collection Details</h2>
      <FormField
        control={control}
        name="serviceType"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Type of Service Required</FormLabel>
            <Select onValueChange={field.onChange} defaultValue={field.value}>
              <FormControl>
                <SelectTrigger><SelectValue placeholder="Select a service type" /></SelectTrigger>
              </FormControl>
              <SelectContent>
                {serviceTypes.map(type => <SelectItem key={type} value={type}>{type}</SelectItem>)}
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="itemDescription"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Brief Description of Items for Collection</FormLabel>
            <FormControl><Textarea placeholder="e.g. Old sofa, fridge, approx 10 bags of mixed household waste, garden cuttings" {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="estimatedVolume"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Estimated Volume of Waste</FormLabel>
             <Select onValueChange={field.onChange} defaultValue={field.value}>
              <FormControl>
                <SelectTrigger><SelectValue placeholder="Select an estimated volume" /></SelectTrigger>
              </FormControl>
              <SelectContent>
                {volumeEstimates.map(volume => <SelectItem key={volume} value={volume}>{volume}</SelectItem>)}
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )}
      />
       <FormField
        control={control}
        name="preferredDate"
        render={({ field }) => (
          <FormItem className="flex flex-col">
            <FormLabel>Preferred Collection Date</FormLabel>
            <Popover>
              <PopoverTrigger asChild>
                <FormControl>
                  <Button
                    variant={"outline"}
                    className={cn(
                      "w-full pl-3 text-left font-normal",
                      !field.value && "text-muted-foreground"
                    )}
                  >
                    {field.value ? (
                      format(field.value, "PPP")
                    ) : (
                      <span>Pick a date</span>
                    )}
                    <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                  </Button>
                </FormControl>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0" align="start">
                <Calendar
                  mode="single"
                  selected={field.value}
                  onSelect={field.onChange}
                  disabled={(date) => date < new Date() || date < new Date("1900-01-01") } // Disable past dates
                  initialFocus
                />
              </PopoverContent>
            </Popover>
            <FormMessage />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="preferredTime"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Preferred Time Slot</FormLabel>
            <Select onValueChange={field.onChange} defaultValue={field.value}>
              <FormControl>
                <SelectTrigger><SelectValue placeholder="Select a time slot" /></SelectTrigger>
              </FormControl>
              <SelectContent>
                {timeSlots.map(slot => <SelectItem key={slot} value={slot}>{slot}</SelectItem>)}
              </SelectContent>
            </Select>
            <FormMessage />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="accessRestrictions"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Access Restrictions / Parking Information (Optional)</FormLabel>
            <FormControl><Textarea placeholder="e.g. Narrow street, permit parking required, items on 3rd floor no lift." {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="hasParking"
        render={({ field }) => (
          <FormItem className="space-y-3">
            <FormLabel>Is there available parking for a van at the property?</FormLabel>
            <FormControl>
              <RadioGroup
                onValueChange={field.onChange}
                defaultValue={field.value}
                className="flex flex-col space-y-1 sm:flex-row sm:space-y-0 sm:space-x-4"
              >
                <FormItem className="flex items-center space-x-3 space-y-0">
                  <FormControl><RadioGroupItem value="yes" /></FormControl>
                  <FormLabel className="font-normal">Yes</FormLabel>
                </FormItem>
                <FormItem className="flex items-center space-x-3 space-y-0">
                  <FormControl><RadioGroupItem value="no" /></FormControl>
                  <FormLabel className="font-normal">No</FormLabel>
                </FormItem>
                 <FormItem className="flex items-center space-x-3 space-y-0">
                  <FormControl><RadioGroupItem value="unsure" /></FormControl>
                  <FormLabel className="font-normal">Unsure</FormLabel>
                </FormItem>
              </RadioGroup>
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
    </div>
  );
}

function ReviewForm({ formData }: { formData: Partial<BookingFormData> }) {
  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-headline font-semibold text-primary">Review Your Request</h2>
      <div className="space-y-4 rounded-lg border p-6 shadow-sm">
        <div>
          <h3 className="text-lg font-semibold text-primary">Personal Details</h3>
          <p><strong>Full Name:</strong> {formData.fullName}</p>
          <p><strong>Email:</strong> {formData.email}</p>
          <p><strong>Phone:</strong> {formData.phone}</p>
          <p><strong>Address:</strong> {formData.addressLine1}{formData.addressLine2 ? `, ${formData.addressLine2}` : ''}, {formData.city}, {formData.postcode}</p>
        </div>
        <hr/>
        <div>
          <h3 className="text-lg font-semibold text-primary">Collection Details</h3>
          <p><strong>Service Type:</strong> {formData.serviceType}</p>
          <p><strong>Item Description:</strong> {formData.itemDescription}</p>
          <p><strong>Estimated Volume:</strong> {formData.estimatedVolume}</p>
          <p><strong>Preferred Date:</strong> {formData.preferredDate ? format(new Date(formData.preferredDate), "PPP") : 'Not specified'}</p>
          <p><strong>Preferred Time:</strong> {formData.preferredTime}</p>
          <p><strong>Parking Available:</strong> {formData.hasParking ? formData.hasParking.charAt(0).toUpperCase() + formData.hasParking.slice(1) : 'Not specified'}</p>
          {formData.accessRestrictions && <p><strong>Access Info:</strong> {formData.accessRestrictions}</p>}
        </div>
      </div>
      <p className="text-sm text-muted-foreground">
        Please review your information carefully. By submitting, you agree to our terms and conditions.
        We will contact you to confirm the booking and provide a final quote.
      </p>
    </div>
  );
}
