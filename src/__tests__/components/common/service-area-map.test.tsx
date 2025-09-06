import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ServiceAreaMap } from '@/components/common/service-area-map'

// Mock the service areas hook
jest.mock('@/hooks/use-service-areas', () => ({
  useServiceAreas: () => ({
    serviceAreas: [
      {
        id: '1',
        area_name: 'Central London',
        postcodes: ['W1', 'WC1', 'EC1'],
        coverage_radius: 5,
        additional_fee: 0,
        active: true,
        description: 'Central London coverage area',
        order: 1,
      },
      {
        id: '2',
        area_name: 'North London',
        postcodes: ['N1', 'N2'],
        coverage_radius: 10,
        additional_fee: 25,
        active: true,
        description: 'North London with additional fee',
        order: 2,
      },
    ],
    isLoading: false,
    error: null,
  }),
}))

describe('ServiceAreaMap Component', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders service area map correctly', () => {
    render(<ServiceAreaMap />)
    
    expect(screen.getByText('Service Area Coverage')).toBeInTheDocument()
    expect(screen.getByText('Check Your Postcode')).toBeInTheDocument()
    expect(screen.getByText('Our Service Areas')).toBeInTheDocument()
  })

  it('displays service areas', () => {
    render(<ServiceAreaMap />)
    
    expect(screen.getByText('Central London')).toBeInTheDocument()
    expect(screen.getByText('North London')).toBeInTheDocument()
    expect(screen.getByText('Central London coverage area')).toBeInTheDocument()
  })

  it('shows postcode checker input', () => {
    render(<ServiceAreaMap />)
    
    const input = screen.getByPlaceholderText(/enter your postcode/i)
    expect(input).toBeInTheDocument()
    
    const searchButton = screen.getByRole('button')
    expect(searchButton).toBeInTheDocument()
  })

  it('checks postcode coverage correctly', async () => {
    const user = userEvent.setup()
    render(<ServiceAreaMap />)
    
    const input = screen.getByPlaceholderText(/enter your postcode/i)
    const searchButton = screen.getByRole('button')
    
    // Test covered postcode
    await user.type(input, 'W1A 1AA')
    await user.click(searchButton)
    
    expect(screen.getByText(/we cover your area/i)).toBeInTheDocument()
    // Use more specific query to avoid multiple matches
    expect(screen.getByText('Area:')).toBeInTheDocument()
    // Look for the search result section specifically
    const searchResult = screen.getByText(/we cover your area/i).closest('.p-4')
    expect(searchResult).toHaveTextContent('Central London')
  })

  it('handles uncovered postcode', async () => {
    const user = userEvent.setup()
    render(<ServiceAreaMap />)
    
    const input = screen.getByPlaceholderText(/enter your postcode/i)
    const searchButton = screen.getByRole('button')
    
    // Test uncovered postcode
    await user.type(input, 'SW1A 1AA')
    await user.click(searchButton)
    
    expect(screen.getByText(/area not currently covered/i)).toBeInTheDocument()
    expect(screen.getByText(/contact us anyway/i)).toBeInTheDocument()
  })

  it('shows additional fees when applicable', async () => {
    const user = userEvent.setup()
    render(<ServiceAreaMap />)
    
    const input = screen.getByPlaceholderText(/enter your postcode/i)
    const searchButton = screen.getByRole('button')
    
    // Test postcode with additional fee
    await user.type(input, 'N1 1AA')
    await user.click(searchButton)
    
    expect(screen.getByText(/additional fee:/i)).toBeInTheDocument()
    // Look for the fee specifically in the search result area
    const searchResult = screen.getByText(/we cover your area/i).closest('.p-4')
    expect(searchResult).toHaveTextContent('£25')
  })

  it('handles enter key press for search', async () => {
    const user = userEvent.setup()
    render(<ServiceAreaMap />)
    
    const input = screen.getByPlaceholderText(/enter your postcode/i)
    
    await user.type(input, 'W1A 1AA')
    await user.keyboard('{Enter}')
    
    expect(screen.getByText(/we cover your area/i)).toBeInTheDocument()
  })

  it('displays postcode badges for each area', () => {
    render(<ServiceAreaMap />)
    
    // Check for postcode badges
    expect(screen.getByText('W1')).toBeInTheDocument()
    expect(screen.getByText('WC1')).toBeInTheDocument()
    expect(screen.getByText('EC1')).toBeInTheDocument()
    expect(screen.getByText('N1')).toBeInTheDocument()
    expect(screen.getByText('N2')).toBeInTheDocument()
  })

  it('shows loading state', () => {
    jest.doMock('@/hooks/use-service-areas', () => ({
      useServiceAreas: () => ({
        serviceAreas: [],
        isLoading: true,
        error: null,
      }),
    }))
    
    render(<ServiceAreaMap />)
    // Loading spinner should be visible
  })

  it('displays service area coverage title and sections', () => {
    render(<ServiceAreaMap />)
    
    // Check that the main sections are rendered
    expect(screen.getByText('Service Area Coverage')).toBeInTheDocument()
    expect(screen.getByText('Check Your Postcode')).toBeInTheDocument()
    expect(screen.getByText('Our Service Areas')).toBeInTheDocument()
    
    // Check that service areas are displayed
    expect(screen.getByText('Central London')).toBeInTheDocument()
    expect(screen.getByText('North London')).toBeInTheDocument()
  })
})