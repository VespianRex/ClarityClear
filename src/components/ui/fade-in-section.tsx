'use client';

import { motion, useInView } from 'framer-motion';
import { useRef, ReactNode, forwardRef } from 'react';

interface FadeInSectionProps {
  children: ReactNode;
  className?: string;
  delay?: number;
  direction?: 'up' | 'down' | 'left' | 'right';
  duration?: number;
}

export const FadeInSection = forwardRef<HTMLDivElement, FadeInSectionProps>(
  function FadeInSection({
    children,
    className = '',
    delay = 0,
    direction = 'up',
    duration = 0.6,
  }, forwardedRef) {
    const internalRef = useRef<HTMLDivElement>(null);
    // Use the forwarded ref if provided, otherwise use internal ref
    const ref = (forwardedRef as React.RefObject<HTMLDivElement>) || internalRef;
    const isInView = useInView(ref, { once: true, margin: '-100px' });

    const directionOffset = {
      up: { y: 40, x: 0 },
      down: { y: -40, x: 0 },
      left: { y: 0, x: 40 },
      right: { y: 0, x: -40 },
    };

    return (
      <motion.div
        ref={ref}
        className={className}
        initial={{
          opacity: 0,
          ...directionOffset[direction],
        }}
        animate={
          isInView
            ? {
                opacity: 1,
                y: 0,
                x: 0,
              }
            : {
                opacity: 0,
                ...directionOffset[direction],
              }
        }
        transition={{
          duration,
          delay,
          ease: [0.25, 0.25, 0, 1],
        }}
      >
        {children}
      </motion.div>
    );
  }
);
