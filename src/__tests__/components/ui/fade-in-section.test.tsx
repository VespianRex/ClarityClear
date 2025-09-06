import { render, screen } from '@testing-library/react'
import { FadeInSection } from '@/components/ui/fade-in-section'

// Mock framer-motion
jest.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
  },
  useInView: () => true,
}))

describe('FadeInSection Component', () => {
  it('renders children correctly', () => {
    render(
      <FadeInSection>
        <div>Test content</div>
      </FadeInSection>
    )
    
    expect(screen.getByText('Test content')).toBeInTheDocument()
  })

  it('applies custom className', () => {
    render(
      <FadeInSection className="test-class">
        <div>Test content</div>
      </FadeInSection>
    )
    
    const section = screen.getByText('Test content').parentElement
    expect(section).toHaveClass('test-class')
  })

  it('handles different directions', () => {
    render(
      <FadeInSection direction="left">
        <div>Left animation</div>
      </FadeInSection>
    )
    
    expect(screen.getByText('Left animation')).toBeInTheDocument()
  })

  it('handles delay prop', () => {
    render(
      <FadeInSection delay={0.5}>
        <div>Delayed content</div>
      </FadeInSection>
    )
    
    expect(screen.getByText('Delayed content')).toBeInTheDocument()
  })

  it('handles custom duration', () => {
    render(
      <FadeInSection duration={1.2}>
        <div>Custom duration</div>
      </FadeInSection>
    )
    
    expect(screen.getByText('Custom duration')).toBeInTheDocument()
  })
})