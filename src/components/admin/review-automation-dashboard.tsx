'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import { 
  Star, 
  Mail, 
  TrendingUp, 
  Users, 
  ExternalLink,
  Play,
  CheckCircle,
  Clock,
  AlertCircle
} from 'lucide-react';
import { useReviewCampaigns, useReviewStats, useReviewAutomation } from '@/hooks/use-review-automation';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { FadeInSection } from '@/components/ui/fade-in-section';
import { AnimatedCounter } from '@/components/ui/animated-counter';

export function ReviewAutomationDashboard() {
  const [isRunningAutomation, setIsRunningAutomation] = useState(false);
  const { campaigns, isLoading: campaignsLoading, refresh } = useReviewCampaigns();
  const { stats, isLoading: statsLoading } = useReviewStats();
  const { runAutomation } = useReviewAutomation();

  const handleRunAutomation = async () => {
    setIsRunningAutomation(true);
    try {
      const result = await runAutomation();
      if (result.success) {
        refresh(); // Refresh the campaigns data
      }
    } catch (error) {
      console.error('Automation failed:', error);
    } finally {
      setIsRunningAutomation(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'sent': return 'bg-blue-100 text-blue-800';
      case 'responded': return 'bg-green-100 text-green-800';
      case 'completed': return 'bg-green-100 text-green-800';
      case 'opted_out': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending': return <Clock className="h-4 w-4" />;
      case 'sent': return <Mail className="h-4 w-4" />;
      case 'responded': return <CheckCircle className="h-4 w-4" />;
      case 'completed': return <CheckCircle className="h-4 w-4" />;
      case 'opted_out': return <AlertCircle className="h-4 w-4" />;
      default: return <Clock className="h-4 w-4" />;
    }
  };

  if (campaignsLoading || statsLoading) {
    return (
      <div className="flex justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <FadeInSection>
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold text-primary mb-2">Review Automation</h1>
            <p className="text-muted-foreground">
              Automatically collect customer reviews to boost your online reputation
            </p>
          </div>
          <Button 
            onClick={handleRunAutomation}
            disabled={isRunningAutomation}
            className="bg-accent hover:bg-accent/90"
          >
            {isRunningAutomation ? (
              <>
                <LoadingSpinner size="sm" className="mr-2" />
                Running...
              </>
            ) : (
              <>
                <Play className="h-4 w-4 mr-2" />
                Run Automation
              </>
            )}
          </Button>
        </div>
      </FadeInSection>

      {/* Stats Overview */}
      <FadeInSection delay={0.1}>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <Users className="h-8 w-8 text-blue-500" />
                <div>
                  <AnimatedCounter 
                    end={stats.totalCampaigns} 
                    className="text-2xl font-bold text-primary"
                  />
                  <p className="text-sm text-muted-foreground">Total Campaigns</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <Mail className="h-8 w-8 text-green-500" />
                <div>
                  <AnimatedCounter 
                    end={stats.reviewRequestsSent} 
                    className="text-2xl font-bold text-primary"
                  />
                  <p className="text-sm text-muted-foreground">Emails Sent</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <Star className="h-8 w-8 text-yellow-500" />
                <div>
                  <AnimatedCounter 
                    end={stats.reviewsReceived} 
                    className="text-2xl font-bold text-primary"
                  />
                  <p className="text-sm text-muted-foreground">Reviews Received</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <TrendingUp className="h-8 w-8 text-accent" />
                <div>
                  <AnimatedCounter 
                    end={stats.responseRate} 
                    suffix="%" 
                    className="text-2xl font-bold text-primary"
                  />
                  <p className="text-sm text-muted-foreground">Response Rate</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </FadeInSection>

      {/* Performance Metrics */}
      <FadeInSection delay={0.2}>
        <div className="grid md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Star className="h-5 w-5 text-yellow-500" />
                Review Performance
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium">Average Rating</span>
                <div className="flex items-center gap-2">
                  <span className="text-2xl font-bold text-primary">
                    {stats.averageRating.toFixed(1)}
                  </span>
                  <div className="flex">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <Star
                        key={star}
                        className={`h-4 w-4 ${
                          star <= Math.round(stats.averageRating)
                            ? 'text-yellow-400 fill-current'
                            : 'text-gray-300'
                        }`}
                      />
                    ))}
                  </div>
                </div>
              </div>
              
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Response Rate</span>
                  <span>{stats.responseRate.toFixed(1)}%</span>
                </div>
                <Progress value={stats.responseRate} className="h-2" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Platform Breakdown</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {Object.entries(stats.platformBreakdown).map(([platform, count]) => (
                <div key={platform} className="flex justify-between items-center">
                  <span className="text-sm font-medium capitalize">{platform}</span>
                  <Badge variant="secondary">{count} reviews</Badge>
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </FadeInSection>

      {/* Campaign Management */}
      <FadeInSection delay={0.3}>
        <Card>
          <CardHeader>
            <CardTitle>Campaign Management</CardTitle>
            <p className="text-sm text-muted-foreground">
              Monitor and manage your review automation campaigns
            </p>
          </CardHeader>
          <CardContent>
            <Tabs defaultValue="active" className="w-full">
              <TabsList className="grid w-full grid-cols-4">
                <TabsTrigger value="active">Active</TabsTrigger>
                <TabsTrigger value="pending">Pending</TabsTrigger>
                <TabsTrigger value="completed">Completed</TabsTrigger>
                <TabsTrigger value="all">All Campaigns</TabsTrigger>
              </TabsList>

              <TabsContent value="active" className="space-y-4">
                <div className="space-y-3">
                  {campaigns
                    .filter(c => c.status === 'sent')
                    .slice(0, 10)
                    .map((campaign) => (
                      <div
                        key={campaign.id}
                        className="flex items-center justify-between p-4 border rounded-lg"
                      >
                        <div className="flex items-center gap-3">
                          {getStatusIcon(campaign.status)}
                          <div>
                            <p className="font-medium">{campaign.customer_name}</p>
                            <p className="text-sm text-muted-foreground">
                              {campaign.service_type} • {new Date(campaign.completion_date).toLocaleDateString()}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Badge className={getStatusColor(campaign.status)}>
                            {campaign.status}
                          </Badge>
                          {campaign.review_url && (
                            <Button variant="outline" size="sm" asChild>
                              <a href={campaign.review_url} target="_blank" rel="noopener noreferrer">
                                <ExternalLink className="h-3 w-3" />
                              </a>
                            </Button>
                          )}
                        </div>
                      </div>
                    ))}
                </div>
              </TabsContent>

              <TabsContent value="pending" className="space-y-4">
                <div className="space-y-3">
                  {campaigns
                    .filter(c => c.status === 'pending')
                    .slice(0, 10)
                    .map((campaign) => (
                      <div
                        key={campaign.id}
                        className="flex items-center justify-between p-4 border rounded-lg"
                      >
                        <div className="flex items-center gap-3">
                          {getStatusIcon(campaign.status)}
                          <div>
                            <p className="font-medium">{campaign.customer_name}</p>
                            <p className="text-sm text-muted-foreground">
                              {campaign.service_type} • {new Date(campaign.completion_date).toLocaleDateString()}
                            </p>
                          </div>
                        </div>
                        <Badge className={getStatusColor(campaign.status)}>
                          {campaign.status}
                        </Badge>
                      </div>
                    ))}
                </div>
              </TabsContent>

              <TabsContent value="completed" className="space-y-4">
                <div className="space-y-3">
                  {campaigns
                    .filter(c => c.status === 'completed')
                    .slice(0, 10)
                    .map((campaign) => (
                      <div
                        key={campaign.id}
                        className="flex items-center justify-between p-4 border rounded-lg"
                      >
                        <div className="flex items-center gap-3">
                          {getStatusIcon(campaign.status)}
                          <div>
                            <p className="font-medium">{campaign.customer_name}</p>
                            <p className="text-sm text-muted-foreground">
                              {campaign.service_type} • {new Date(campaign.completion_date).toLocaleDateString()}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          {campaign.review_rating && (
                            <div className="flex items-center gap-1">
                              <Star className="h-4 w-4 text-yellow-400 fill-current" />
                              <span className="text-sm font-medium">{campaign.review_rating}</span>
                            </div>
                          )}
                          <Badge className={getStatusColor(campaign.status)}>
                            {campaign.status}
                          </Badge>
                        </div>
                      </div>
                    ))}
                </div>
              </TabsContent>

              <TabsContent value="all" className="space-y-4">
                <div className="space-y-3">
                  {campaigns.slice(0, 20).map((campaign) => (
                    <div
                      key={campaign.id}
                      className="flex items-center justify-between p-4 border rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        {getStatusIcon(campaign.status)}
                        <div>
                          <p className="font-medium">{campaign.customer_name}</p>
                          <p className="text-sm text-muted-foreground">
                            {campaign.service_type} • {new Date(campaign.completion_date).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {campaign.review_rating && (
                          <div className="flex items-center gap-1">
                            <Star className="h-4 w-4 text-yellow-400 fill-current" />
                            <span className="text-sm font-medium">{campaign.review_rating}</span>
                          </div>
                        )}
                        <Badge className={getStatusColor(campaign.status)}>
                          {campaign.status}
                        </Badge>
                      </div>
                    </div>
                  ))}
                </div>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>
      </FadeInSection>
    </div>
  );
}