'use client';

import { useEffect, useState, forwardRef } from 'react';
import { motion, useInView } from 'framer-motion';
import { useRef } from 'react';

interface AnimatedCounterProps {
  end: number;
  duration?: number;
  prefix?: string;
  suffix?: string;
  className?: string;
}

export const AnimatedCounter = forwardRef<HTMLSpanElement, AnimatedCounterProps>(
  function AnimatedCounter({
    end,
    duration = 2,
    prefix = '',
    suffix = '',
    className = '',
  }, forwardedRef) {
    const [count, setCount] = useState(0);
    const internalRef = useRef<HTMLSpanElement>(null);
    // Use the forwarded ref if provided, otherwise use internal ref
    const ref = (forwardedRef as React.RefObject<HTMLSpanElement>) || internalRef;
    const isInView = useInView(ref, { once: true });

    useEffect(() => {
      if (!isInView) return;

      const startTime = Date.now();

      const updateCount = () => {
        const now = Date.now();
        const progress = Math.min((now - startTime) / (duration * 1000), 1);

        // Easing function for smooth animation
        const easeOutQuart = 1 - Math.pow(1 - progress, 4);
        const currentCount = Math.floor(easeOutQuart * end);

        setCount(currentCount);

        if (progress < 1) {
          requestAnimationFrame(updateCount);
        } else {
          setCount(end);
        }
      };

      requestAnimationFrame(updateCount);
    }, [end, duration, isInView]);

    return (
      <motion.span
        ref={ref}
        className={className}
        initial={{ opacity: 0, y: 20 }}
        animate={isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 20 }}
        transition={{ duration: 0.5 }}
      >
        {prefix}
        {count.toLocaleString()}
        {suffix}
      </motion.span>
    );
  }
);
