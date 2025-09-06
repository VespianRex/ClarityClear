// Email service for ClarityClear notifications
// This can be extended with actual email providers like Resend, SendGrid, etc.

export interface EmailTemplate {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export interface BookingNotificationData {
  customerName: string;
  customerEmail: string;
  serviceType: string;
  propertyAddress: string;
  urgency: string;
  bookingId: string;
}

export interface ContactNotificationData {
  name: string;
  email: string;
  subject?: string;
  message: string;
  contactId: string;
}

// Email templates
export const emailTemplates = {
  bookingConfirmation: (data: BookingNotificationData): EmailTemplate => ({
    to: data.customerEmail,
    subject: `Booking Confirmation - ${data.serviceType} Service`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #001F3F; color: white; padding: 20px; text-align: center;">
          <h1>ClarityClear</h1>
          <h2>Booking Confirmation</h2>
        </div>
        
        <div style="padding: 20px; background: #f9f9f9;">
          <h3>Hello ${data.customerName},</h3>
          <p>Thank you for choosing ClarityClear! We've received your booking request and will contact you within 24 hours with a detailed quote.</p>
          
          <div style="background: white; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h4>Booking Details:</h4>
            <p><strong>Service:</strong> ${data.serviceType}</p>
            <p><strong>Property:</strong> ${data.propertyAddress}</p>
            <p><strong>Urgency:</strong> ${data.urgency}</p>
            <p><strong>Booking ID:</strong> ${data.bookingId}</p>
          </div>
          
          <p>Our team will assess your requirements and provide a competitive quote tailored to your needs.</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://wa.me/1234567890" style="background: #39CCCC; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px;">
              Contact Us on WhatsApp
            </a>
          </div>
          
          <p>Best regards,<br>The ClarityClear Team</p>
        </div>
        
        <div style="background: #001F3F; color: white; padding: 15px; text-align: center; font-size: 12px;">
          <p>ClarityClear - Professional Clearance Services</p>
          <p>Email: info@clarityclear.com | Phone: +1 (234) 567-890</p>
        </div>
      </div>
    `,
    text: `
      ClarityClear - Booking Confirmation
      
      Hello ${data.customerName},
      
      Thank you for choosing ClarityClear! We've received your booking request.
      
      Booking Details:
      - Service: ${data.serviceType}
      - Property: ${data.propertyAddress}
      - Urgency: ${data.urgency}
      - Booking ID: ${data.bookingId}
      
      We'll contact you within 24 hours with a detailed quote.
      
      Best regards,
      The ClarityClear Team
    `,
  }),

  adminBookingNotification: (data: BookingNotificationData): EmailTemplate => ({
    to: 'admin@clarityclear.com',
    subject: `New Booking Request - ${data.serviceType}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #001F3F; color: white; padding: 20px;">
          <h1>New Booking Request</h1>
        </div>
        
        <div style="padding: 20px;">
          <h3>New booking request received!</h3>
          
          <div style="background: #f9f9f9; padding: 15px; border-radius: 5px;">
            <h4>Customer Details:</h4>
            <p><strong>Name:</strong> ${data.customerName}</p>
            <p><strong>Email:</strong> ${data.customerEmail}</p>
            <p><strong>Service:</strong> ${data.serviceType}</p>
            <p><strong>Property:</strong> ${data.propertyAddress}</p>
            <p><strong>Urgency:</strong> ${data.urgency}</p>
            <p><strong>Booking ID:</strong> ${data.bookingId}</p>
          </div>
          
          <p>Please review and respond to this booking request promptly.</p>
          
          <div style="text-align: center; margin: 20px 0;">
            <a href="http://localhost:8090/_/" style="background: #39CCCC; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px;">
              View in Admin Panel
            </a>
          </div>
        </div>
      </div>
    `,
  }),

  contactConfirmation: (data: ContactNotificationData): EmailTemplate => ({
    to: data.email,
    subject: 'Thank you for contacting ClarityClear',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: #001F3F; color: white; padding: 20px; text-align: center;">
          <h1>ClarityClear</h1>
          <h2>Message Received</h2>
        </div>
        
        <div style="padding: 20px; background: #f9f9f9;">
          <h3>Hello ${data.name},</h3>
          <p>Thank you for contacting us! We've received your message and will get back to you within 24 hours.</p>
          
          <div style="background: white; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h4>Your Message:</h4>
            <p><strong>Subject:</strong> ${data.subject || 'General Inquiry'}</p>
            <p><strong>Message:</strong> ${data.message}</p>
            <p><strong>Reference ID:</strong> ${data.contactId}</p>
          </div>
          
          <p>If you need immediate assistance, feel free to contact us via WhatsApp.</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://wa.me/1234567890" style="background: #39CCCC; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px;">
              WhatsApp Us
            </a>
          </div>
          
          <p>Best regards,<br>The ClarityClear Team</p>
        </div>
      </div>
    `,
  }),
};

// Mock email service (replace with actual email provider)
export async function sendEmail(
  _template: EmailTemplate
): Promise<{ success: boolean; error?: string }> {
  try {
    // In production, integrate with:
    // - Resend: https://resend.com/
    // - SendGrid: https://sendgrid.com/
    // - Nodemailer with SMTP
    // - AWS SES

    // Email would be sent in production

    // Simulate email sending delay
    await new Promise(resolve => setTimeout(resolve, 500));

    return { success: true };
  } catch (error: any) {
    console.error('Email sending failed:', error);
    return { success: false, error: error.message };
  }
}

// Helper functions
export async function sendBookingConfirmation(data: BookingNotificationData) {
  const customerEmail = emailTemplates.bookingConfirmation(data);
  const adminEmail = emailTemplates.adminBookingNotification(data);

  const results = await Promise.all([
    sendEmail(customerEmail),
    sendEmail(adminEmail),
  ]);

  return {
    customerEmailSent: results[0].success,
    adminEmailSent: results[1].success,
    errors: results.filter(r => !r.success).map(r => r.error),
  };
}

export async function sendContactConfirmation(data: ContactNotificationData) {
  const template = emailTemplates.contactConfirmation(data);
  return await sendEmail(template);
}
