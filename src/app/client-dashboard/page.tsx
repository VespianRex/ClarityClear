import { Metadata } from 'next';
import { ClientDashboard } from '@/components/client-dashboard/client-dashboard';

export const metadata: Metadata = {
  title: 'Client Dashboard - BestClear',
  description: 'Manage your BestClear website and business',
};

export default function ClientDashboardPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <ClientDashboard />
    </div>
  );
}
