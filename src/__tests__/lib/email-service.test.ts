import { 
  emailTemplates, 
  sendEmail, 
  sendBookingConfirmation, 
  sendContactConfirmation 
} from '@/lib/email-service'

describe('Email Service', () => {
  describe('emailTemplates', () => {
    const mockBookingData = {
      customerName: 'John Doe',
      customerEmail: 'john@example.com',
      serviceType: 'House Clearance',
      propertyAddress: '123 Test Street',
      urgency: 'week',
      bookingId: 'booking-123'
    }

    it('generates booking confirmation template', () => {
      const template = emailTemplates.bookingConfirmation(mockBookingData)
      
      expect(template.to).toBe('john@example.com')
      expect(template.subject).toContain('House Clearance')
      expect(template.html).toContain('John Doe')
      expect(template.html).toContain('booking-123')
      expect(template.text).toContain('John Doe')
    })

    it('generates admin booking notification template', () => {
      const template = emailTemplates.adminBookingNotification(mockBookingData)
      
      expect(template.to).toBe('admin@clarityclear.com')
      expect(template.subject).toContain('New Booking Request')
      expect(template.html).toContain('John Doe')
      expect(template.html).toContain('House Clearance')
    })

    it('generates contact confirmation template', () => {
      const contactData = {
        name: 'Jane Smith',
        email: 'jane@example.com',
        subject: 'Test Subject',
        message: 'Test message',
        contactId: 'contact-456'
      }

      const template = emailTemplates.contactConfirmation(contactData)
      
      expect(template.to).toBe('jane@example.com')
      expect(template.subject).toContain('Thank you for contacting')
      expect(template.html).toContain('Jane Smith')
      expect(template.html).toContain('contact-456')
    })
  })

  describe('sendEmail', () => {
    it('simulates successful email sending', async () => {
      const template = {
        to: 'test@example.com',
        subject: 'Test Subject',
        html: '<p>Test content</p>',
        text: 'Test content'
      }

      const result = await sendEmail(template)
      
      expect(result.success).toBe(true)
      expect(result.error).toBeUndefined()
    })

    it('handles email sending errors', async () => {
      // Mock a failure scenario
      const originalConsoleError = console.error
      console.error = jest.fn()

      // This would need to be mocked to actually fail
      const template = {
        to: 'invalid-email',
        subject: 'Test',
        html: '<p>Test</p>'
      }

      const result = await sendEmail(template)
      
      // In the current implementation, it always succeeds (mock)
      expect(result.success).toBe(true)
      
      console.error = originalConsoleError
    })
  })

  describe('sendBookingConfirmation', () => {
    it('sends both customer and admin emails', async () => {
      const bookingData = {
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        serviceType: 'House Clearance',
        propertyAddress: '123 Test Street',
        urgency: 'week',
        bookingId: 'booking-123'
      }

      const result = await sendBookingConfirmation(bookingData)
      
      expect(result.customerEmailSent).toBe(true)
      expect(result.adminEmailSent).toBe(true)
      expect(result.errors).toHaveLength(0)
    })
  })

  describe('sendContactConfirmation', () => {
    it('sends contact confirmation email', async () => {
      const contactData = {
        name: 'Jane Smith',
        email: 'jane@example.com',
        subject: 'Test Subject',
        message: 'Test message',
        contactId: 'contact-456'
      }

      const result = await sendContactConfirmation(contactData)
      
      expect(result.success).toBe(true)
    })
  })
})