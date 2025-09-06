import { Metadata } from 'next';
import { ReviewAutomationDashboard } from '@/components/admin/review-automation-dashboard';

export const metadata: Metadata = {
  title: 'Review Automation - ClarityClear Admin',
  description: 'Manage automated review collection campaigns',
};

export default function ReviewAutomationPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <ReviewAutomationDashboard />
    </div>
  );
}