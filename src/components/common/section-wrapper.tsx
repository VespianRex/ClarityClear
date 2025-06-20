import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

interface SectionWrapperProps {
  children: ReactNode;
  className?: string;
  as?: keyof JSX.IntrinsicElements;
  id?: string;
}

export function SectionWrapper({ children, className, as: Component = 'section', id }: SectionWrapperProps) {
  return (
    <Component id={id} className={cn('py-12 md:py-16 lg:py-20', className)}>
      <div className="container mx-auto max-w-screen-xl px-4 sm:px-6 lg:px-8">
        {children}
      </div>
    </Component>
  );
}
