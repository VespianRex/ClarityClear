'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Users,
  MessageSquare,
  Calendar,
  Settings,
  TrendingUp,
  Star,
  DollarSign,
  Eye,
  Plus,
} from 'lucide-react';
import { useServices, useTestimonials } from '@/hooks/use-pocketbase';
import { LoadingSpinner } from '@/components/ui/loading-spinner';

interface DashboardStats {
  totalBookings: number;
  pendingBookings: number;
  totalContacts: number;
  averageRating: number;
  monthlyRevenue: number;
}

export function ClientDashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    totalBookings: 0,
    pendingBookings: 0,
    totalContacts: 0,
    averageRating: 0,
    monthlyRevenue: 0,
  });
  const [loading, setLoading] = useState(true);

  const { services } = useServices();
  const { testimonials } = useTestimonials();

  useEffect(() => {
    loadDashboardStats();
  }, []);

  const loadDashboardStats = async () => {
    try {
      // In a real implementation, these would be actual database queries
      // For now, we'll simulate with some data
      setStats({
        totalBookings: 47,
        pendingBookings: 8,
        totalContacts: 23,
        averageRating: 4.8,
        monthlyRevenue: 12450,
      });
    } catch (error) {
      console.error('Failed to load stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="bg-gradient-to-r from-primary to-accent text-white p-6 rounded-lg">
        <h1 className="text-2xl font-bold mb-2">
          Welcome to Your ClarityClear Dashboard
        </h1>
        <p className="opacity-90">
          Manage your clearance business with ease. Everything you need in one
          place.
        </p>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Calendar className="h-8 w-8 text-accent" />
              <div>
                <p className="text-2xl font-bold">{stats.totalBookings}</p>
                <p className="text-sm text-muted-foreground">Total Bookings</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Users className="h-8 w-8 text-orange-500" />
              <div>
                <p className="text-2xl font-bold">{stats.pendingBookings}</p>
                <p className="text-sm text-muted-foreground">Pending</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <MessageSquare className="h-8 w-8 text-blue-500" />
              <div>
                <p className="text-2xl font-bold">{stats.totalContacts}</p>
                <p className="text-sm text-muted-foreground">New Messages</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <Star className="h-8 w-8 text-yellow-500" />
              <div>
                <p className="text-2xl font-bold">{stats.averageRating}</p>
                <p className="text-sm text-muted-foreground">Avg Rating</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <DollarSign className="h-8 w-8 text-green-500" />
              <div>
                <p className="text-2xl font-bold">
                  £{stats.monthlyRevenue.toLocaleString()}
                </p>
                <p className="text-sm text-muted-foreground">This Month</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Tabs */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="bookings">Bookings</TabsTrigger>
          <TabsTrigger value="content">Content</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
          <TabsTrigger value="help">Help</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid md:grid-cols-2 gap-6">
            {/* Recent Activity */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5" />
                  Recent Activity
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <Calendar className="h-4 w-4 text-green-600" />
                    <span className="text-sm">New booking from Sarah M.</span>
                  </div>
                  <Badge variant="secondary">2 hours ago</Badge>
                </div>
                <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <MessageSquare className="h-4 w-4 text-blue-600" />
                    <span className="text-sm">Contact form submission</span>
                  </div>
                  <Badge variant="secondary">4 hours ago</Badge>
                </div>
                <div className="flex items-center justify-between p-3 bg-yellow-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <Star className="h-4 w-4 text-yellow-600" />
                    <span className="text-sm">New 5-star review received</span>
                  </div>
                  <Badge variant="secondary">1 day ago</Badge>
                </div>
              </CardContent>
            </Card>

            {/* Quick Actions */}
            <Card>
              <CardHeader>
                <CardTitle>Quick Actions</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <Button className="w-full justify-start" variant="outline">
                  <Plus className="mr-2 h-4 w-4" />
                  Add New Service
                </Button>
                <Button className="w-full justify-start" variant="outline">
                  <Star className="mr-2 h-4 w-4" />
                  Manage Testimonials
                </Button>
                <Button className="w-full justify-start" variant="outline">
                  <Users className="mr-2 h-4 w-4" />
                  Update Team Info
                </Button>
                <Button className="w-full justify-start" variant="outline">
                  <Eye className="mr-2 h-4 w-4" />
                  View Website
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Bookings Tab */}
        <TabsContent value="bookings">
          <Card>
            <CardHeader>
              <CardTitle>Recent Bookings</CardTitle>
              <p className="text-sm text-muted-foreground">
                Manage your customer bookings and requests
              </p>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8">
                <Calendar className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <p className="text-muted-foreground">
                  Booking management interface would go here
                </p>
                <Button className="mt-4" variant="outline">
                  View All Bookings in Admin Panel
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Content Tab */}
        <TabsContent value="content" className="space-y-4">
          <div className="grid md:grid-cols-2 gap-6">
            {/* Services */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  Your Services
                  <Badge variant="secondary">{services.length}</Badge>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {services.slice(0, 3).map(service => (
                    <div
                      key={service.id}
                      className="flex items-center justify-between p-2 border rounded"
                    >
                      <span className="text-sm">{service.title}</span>
                      <Badge variant="outline">Active</Badge>
                    </div>
                  ))}
                </div>
                <Button className="w-full mt-4" variant="outline">
                  Manage Services
                </Button>
              </CardContent>
            </Card>

            {/* Testimonials */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  Customer Reviews
                  <Badge variant="secondary">{testimonials.length}</Badge>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {testimonials.slice(0, 3).map(testimonial => (
                    <div
                      key={testimonial.id}
                      className="flex items-center justify-between p-2 border rounded"
                    >
                      <span className="text-sm">
                        {testimonial.customer_name}
                      </span>
                      <div className="flex items-center gap-1">
                        <Star className="h-3 w-3 text-yellow-500 fill-current" />
                        <span className="text-xs">{testimonial.rating}</span>
                      </div>
                    </div>
                  ))}
                </div>
                <Button className="w-full mt-4" variant="outline">
                  Manage Reviews
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings">
          <Card>
            <CardHeader>
              <CardTitle>Website Settings</CardTitle>
              <p className="text-sm text-muted-foreground">
                Control what features are enabled on your website
              </p>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8">
                <Settings className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                <p className="text-muted-foreground mb-4">
                  Feature toggles and settings would go here
                </p>
                <Button variant="outline">Access Advanced Settings</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Help Tab */}
        <TabsContent value="help">
          <Card>
            <CardHeader>
              <CardTitle>Need Help?</CardTitle>
              <p className="text-sm text-muted-foreground">
                Get support and learn how to use your website
              </p>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid md:grid-cols-2 gap-4">
                <div className="p-4 border rounded-lg">
                  <h3 className="font-semibold mb-2">📞 Phone Support</h3>
                  <p className="text-sm text-muted-foreground mb-2">
                    Call your web designer for immediate help
                  </p>
                  <Button variant="outline" size="sm">
                    Call Now
                  </Button>
                </div>
                <div className="p-4 border rounded-lg">
                  <h3 className="font-semibold mb-2">📧 Email Support</h3>
                  <p className="text-sm text-muted-foreground mb-2">
                    Send a message for non-urgent questions
                  </p>
                  <Button variant="outline" size="sm">
                    Send Email
                  </Button>
                </div>
                <div className="p-4 border rounded-lg">
                  <h3 className="font-semibold mb-2">📖 User Guide</h3>
                  <p className="text-sm text-muted-foreground mb-2">
                    Step-by-step instructions for common tasks
                  </p>
                  <Button variant="outline" size="sm">
                    View Guide
                  </Button>
                </div>
                <div className="p-4 border rounded-lg">
                  <h3 className="font-semibold mb-2">🎥 Video Tutorials</h3>
                  <p className="text-sm text-muted-foreground mb-2">
                    Watch how to manage your website
                  </p>
                  <Button variant="outline" size="sm">
                    Watch Videos
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
