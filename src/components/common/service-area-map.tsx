'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { MapPin, Search, CheckCircle, XCircle } from 'lucide-react';
import { useServiceAreas } from '@/hooks/use-service-areas';
import { LoadingSpinner } from '@/components/ui/loading-spinner';

interface ServiceAreaMapProps {
  className?: string;
}

export function ServiceAreaMap({ className }: ServiceAreaMapProps) {
  const [searchPostcode, setSearchPostcode] = useState('');
  const [searchResult, setSearchResult] = useState<{
    covered: boolean;
    area?: any;
    additionalFee?: number;
  } | null>(null);

  const { serviceAreas, isLoading } = useServiceAreas();

  const checkPostcode = () => {
    if (!searchPostcode.trim()) return;

    const postcode = searchPostcode.trim().toUpperCase();

    // Check if postcode is covered
    const coveredArea = serviceAreas.find(area =>
      area.postcodes.some((pc: string) => postcode.startsWith(pc.toUpperCase()))
    );

    if (coveredArea) {
      setSearchResult({
        covered: true,
        area: coveredArea,
        additionalFee: coveredArea.additional_fee || 0,
      });
    } else {
      setSearchResult({
        covered: false,
      });
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      checkPostcode();
    }
  };

  return (
    <div className={className}>
      <Card className="shadow-lg">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-accent" />
            Service Area Coverage
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Postcode Checker */}
          <div className="space-y-4">
            <h3 className="font-semibold text-primary">Check Your Postcode</h3>
            <div className="flex gap-2">
              <Input
                placeholder="Enter your postcode (e.g., M1 1AA)"
                value={searchPostcode}
                onChange={e => setSearchPostcode(e.target.value)}
                onKeyPress={handleKeyPress}
                className="flex-1"
              />
              <Button onClick={checkPostcode} size="icon">
                <Search className="h-4 w-4" />
              </Button>
            </div>

            {/* Search Result */}
            {searchResult && (
              <div
                className={`p-4 rounded-lg border ${
                  searchResult.covered
                    ? 'bg-green-50 border-green-200'
                    : 'bg-red-50 border-red-200'
                }`}
              >
                <div className="flex items-center gap-2 mb-2">
                  {searchResult.covered ? (
                    <>
                      <CheckCircle className="h-5 w-5 text-green-600" />
                      <span className="font-semibold text-green-800">
                        We cover your area!
                      </span>
                    </>
                  ) : (
                    <>
                      <XCircle className="h-5 w-5 text-red-600" />
                      <span className="font-semibold text-red-800">
                        Area not currently covered
                      </span>
                    </>
                  )}
                </div>

                {searchResult.covered && searchResult.area && (
                  <div className="text-sm text-muted-foreground">
                    <p>
                      <strong>Area:</strong> {searchResult.area.area_name}
                    </p>
                    {(searchResult.additionalFee ?? 0) > 0 && (
                      <p>
                        <strong>Additional fee:</strong> £
                        {searchResult.additionalFee}
                      </p>
                    )}
                    <p className="mt-2">{searchResult.area.description}</p>
                  </div>
                )}

                {!searchResult.covered && (
                  <p className="text-sm text-red-700">
                    Don't worry! Contact us anyway - we may be able to arrange
                    special coverage for your area.
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Service Areas List */}
          <div className="space-y-4">
            <h3 className="font-semibold text-primary">Our Service Areas</h3>

            {isLoading ? (
              <div className="flex justify-center py-4">
                <LoadingSpinner size="md" />
              </div>
            ) : serviceAreas.length > 0 ? (
              <div className="grid gap-4">
                {serviceAreas.map(area => (
                  <Card key={area.id} className="border-l-4 border-l-accent">
                    <CardContent className="pt-4">
                      <div className="flex justify-between items-start mb-2">
                        <h4 className="font-semibold text-primary">
                          {area.area_name}
                        </h4>
                        {area.additional_fee > 0 && (
                          <Badge variant="secondary">
                            +£{area.additional_fee}
                          </Badge>
                        )}
                      </div>

                      <p className="text-sm text-muted-foreground mb-3">
                        {area.description}
                      </p>

                      <div className="flex flex-wrap gap-1">
                        {area.postcodes.map(
                          (postcode: string, index: number) => (
                            <Badge
                              key={index}
                              variant="outline"
                              className="text-xs"
                            >
                              {postcode}
                            </Badge>
                          )
                        )}
                      </div>

                      {area.coverage_radius && (
                        <p className="text-xs text-muted-foreground mt-2">
                          Coverage radius: {area.coverage_radius} miles
                        </p>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                <MapPin className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>Service area information will be available soon.</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
