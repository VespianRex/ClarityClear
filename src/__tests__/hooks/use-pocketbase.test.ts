import { renderHook } from '@testing-library/react'
import { useServices, useTestimonials, useFAQs, useCreateBooking } from '@/hooks/use-pocketbase'

// Mock SWR
jest.mock('swr', () => ({
  __esModule: true,
  default: jest.fn(() => ({
    data: [],
    error: null,
    isLoading: false,
    mutate: jest.fn(),
  })),
}))

// Mock PocketBase helpers
jest.mock('@/lib/pocketbase', () => ({
  __esModule: true,
  default: {
    collection: jest.fn(() => ({
      create: jest.fn().mockResolvedValue({ id: 'test-id', success: true }),
    })),
  },
  pocketbaseHelpers: {
    getServices: jest.fn().mockResolvedValue([
      { id: '1', title: 'House Clearance', availability: true },
      { id: '2', title: 'Office Clearance', availability: true },
    ]),
    getTestimonials: jest.fn().mockResolvedValue([
      { id: '1', customer_name: 'John Doe', rating: 5, approved: true },
    ]),
    getFAQs: jest.fn().mockResolvedValue([
      { id: '1', question: 'Test question?', answer: 'Test answer', published: true },
    ]),
    createBooking: jest.fn().mockResolvedValue({ id: 'booking-123' }),
  },
}))

describe('PocketBase Hooks', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('useServices', () => {
    it('returns services data structure', () => {
      const { result } = renderHook(() => useServices())
      
      expect(result.current).toHaveProperty('services')
      expect(result.current).toHaveProperty('isLoading')
      expect(result.current).toHaveProperty('error')
      expect(Array.isArray(result.current.services)).toBe(true)
    })
  })

  describe('useTestimonials', () => {
    it('returns testimonials data structure', () => {
      const { result } = renderHook(() => useTestimonials(5))
      
      expect(result.current).toHaveProperty('testimonials')
      expect(result.current).toHaveProperty('isLoading')
      expect(result.current).toHaveProperty('error')
      expect(Array.isArray(result.current.testimonials)).toBe(true)
    })

    it('accepts limit parameter', () => {
      const { result } = renderHook(() => useTestimonials(10))
      
      expect(result.current.testimonials).toBeDefined()
    })
  })

  describe('useFAQs', () => {
    it('returns FAQs data structure', () => {
      const { result } = renderHook(() => useFAQs())
      
      expect(result.current).toHaveProperty('faqs')
      expect(result.current).toHaveProperty('isLoading')
      expect(result.current).toHaveProperty('error')
      expect(Array.isArray(result.current.faqs)).toBe(true)
    })

    it('accepts category filter', () => {
      const { result } = renderHook(() => useFAQs('general'))
      
      expect(result.current.faqs).toBeDefined()
    })
  })

  describe('useCreateBooking', () => {
    it('returns createBooking function', () => {
      const { result } = renderHook(() => useCreateBooking())
      
      expect(result.current).toHaveProperty('createBooking')
      expect(typeof result.current.createBooking).toBe('function')
    })

    it('createBooking handles successful creation', async () => {
      const { result } = renderHook(() => useCreateBooking())
      
      const bookingData = {
        customer_name: 'John Doe',
        customer_email: 'john@example.com',
        service_type: 'house-clearance',
      }

      const response = await result.current.createBooking(bookingData)
      
      expect(response).toHaveProperty('success')
      expect(response).toHaveProperty('booking')
    })
  })
})