
import { z } from 'zod';

export const PersonalDetailsSchema = z.object({
  fullName: z.string().min(2, { message: "Full name must be at least 2 characters." }),
  email: z.string().email({ message: "Invalid email address." }),
  phone: z.string().min(10, { message: "Phone number must be at least 10 digits." }).regex(/^\+?[0-9\s-()]*$/, { message: "Invalid phone number format." }),
  addressLine1: z.string().min(5, { message: "Address line 1 is required." }),
  addressLine2: z.string().optional(),
  city: z.string().min(2, { message: "City is required." }),
  postcode: z.string().min(5, { message: "Postcode is required." }).regex(/^[A-Z]{1,2}[0-9R][0-9A-Z]?\s?[0-9][A-Z]{2}$/i, { message: "Invalid UK postcode format." }),
});

export type PersonalDetailsFormData = z.infer<typeof PersonalDetailsSchema>;

export const CollectionDetailsSchema = z.object({
  serviceType: z.string().min(1, { message: "Please select a service type." }),
  itemDescription: z.string().min(10, { message: "Please describe the items (at least 10 characters)." }),
  estimatedVolume: z.string().min(1, { message: "Please estimate the volume." }),
  accessRestrictions: z.string().optional(),
  preferredDate: z.date({ required_error: "Preferred date is required." }),
  preferredTime: z.string().min(1, { message: "Preferred time slot is required." }),
  hasParking: z.enum(['yes', 'no', 'unsure'], { required_error: "Please specify parking availability." }),
});

export type CollectionDetailsFormData = z.infer<typeof CollectionDetailsSchema>;

export const BookingFormSchema = PersonalDetailsSchema.merge(CollectionDetailsSchema);
export type BookingFormData = z.infer<typeof BookingFormSchema>;

export const ContactFormSchema = z.object({
  fullName: z.string().min(2, { message: "Full name must be at least 2 characters." }),
  email: z.string().email({ message: "Invalid email address." }),
  subject: z.string().min(3, { message: "Subject must be at least 3 characters." }).optional(),
  message: z.string().min(10, { message: "Message must be at least 10 characters." }),
});
export type ContactFormData = z.infer<typeof ContactFormSchema>;
