import { render, screen, waitFor } from '@testing-library/react'
import { AnimatedCounter } from '@/components/ui/animated-counter'

// Mock framer-motion
jest.mock('framer-motion', () => ({
  motion: {
    span: ({ children, ...props }: any) => <span {...props}>{children}</span>,
  },
  useInView: () => true,
}))

describe('AnimatedCounter Component', () => {
  it('renders with basic props', async () => {
    render(<AnimatedCounter end={100} />)
    
    // Should start at 0 and animate to 100
    expect(screen.getByText('0')).toBeInTheDocument()
    
    // Wait for animation to complete
    await waitFor(() => {
      expect(screen.getByText('100')).toBeInTheDocument()
    }, { timeout: 3000 })
  })

  it('renders with prefix and suffix', async () => {
    render(<AnimatedCounter end={50} prefix="£" suffix="%" />)
    
    // Should show prefix and suffix immediately
    expect(screen.getByText(/£/)).toBeInTheDocument()
    expect(screen.getByText(/%/)).toBeInTheDocument()
    
    // Wait for final value
    await waitFor(() => {
      expect(screen.getByText('£50%')).toBeInTheDocument()
    }, { timeout: 3000 })
  })

  it('applies custom className', () => {
    render(<AnimatedCounter end={25} className="test-class" />)
    
    const counter = screen.getByText('0')
    expect(counter).toHaveClass('test-class')
  })

  it('handles large numbers correctly', async () => {
    render(<AnimatedCounter end={1000} />)
    
    // Wait for final formatted value
    await waitFor(() => {
      expect(screen.getByText('1,000')).toBeInTheDocument()
    }, { timeout: 3000 })
  })

  it('handles decimal numbers', async () => {
    render(<AnimatedCounter end={4.9} suffix="/5" />)
    
    // Should show suffix immediately
    expect(screen.getByText(/\/5/)).toBeInTheDocument()
    
    // Wait for final value (component uses Math.floor during animation, then sets final value)
    await waitFor(() => {
      expect(screen.getByText('4.9/5')).toBeInTheDocument()
    }, { timeout: 3000 })
  })
})