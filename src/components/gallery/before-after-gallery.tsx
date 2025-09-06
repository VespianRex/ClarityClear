'use client';

import { useState } from 'react';
import Image from 'next/image';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  ChevronLeft,
  ChevronRight,
  Eye,
  Calendar,
  MapPin,
  Tag,
} from 'lucide-react';
import { useGallery } from '@/hooks/use-gallery';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { motion, AnimatePresence } from 'framer-motion';

interface BeforeAfterGalleryProps {
  className?: string;
  showTitle?: boolean;
  limit?: number;
  serviceFilter?: string;
}

export function BeforeAfterGallery({
  className,
  showTitle = true,
  limit,
  serviceFilter,
}: BeforeAfterGalleryProps) {
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [imageComparison, setImageComparison] = useState(50); // Slider position for before/after

  const { galleryItems, isLoading } = useGallery(limit, serviceFilter);

  const openDialog = (item: any) => {
    setSelectedItem(item);
    setIsDialogOpen(true);
    setImageComparison(50);
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-12">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (galleryItems.length === 0) {
    return (
      <div className="text-center py-12">
        <Eye className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
        <p className="text-muted-foreground">
          Gallery items will appear here once added.
        </p>
      </div>
    );
  }

  return (
    <div className={className}>
      {showTitle && (
        <div className="text-center mb-8">
          <h2 className="font-headline text-3xl sm:text-4xl font-bold text-primary mb-4">
            See Our Work in Action
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Real transformations from our professional clearance services. See
            the difference we make for our customers.
          </p>
        </div>
      )}

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence>
          {galleryItems.map((item, index) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.3, delay: index * 0.1 }}
            >
              <Card className="group cursor-pointer overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1">
                <div className="relative aspect-video overflow-hidden">
                  {/* Before/After Slider Preview */}
                  <div className="relative w-full h-full">
                    <Image
                      src={item.after_image_url}
                      alt={`${item.title} - After`}
                      fill
                      className="object-cover"
                    />
                    <div
                      className="absolute top-0 left-0 h-full overflow-hidden transition-all duration-300 group-hover:w-1/2"
                      style={{ width: '50%' }}
                    >
                      <Image
                        src={item.before_image_url}
                        alt={`${item.title} - Before`}
                        fill
                        className="object-cover"
                      />
                    </div>

                    {/* Divider Line */}
                    <div className="absolute top-0 left-1/2 w-0.5 h-full bg-white shadow-lg group-hover:opacity-100 opacity-70 transition-opacity duration-300" />

                    {/* Before/After Labels */}
                    <div className="absolute top-4 left-4">
                      <Badge
                        variant="secondary"
                        className="bg-black/70 text-white"
                      >
                        Before
                      </Badge>
                    </div>
                    <div className="absolute top-4 right-4">
                      <Badge
                        variant="secondary"
                        className="bg-accent text-accent-foreground"
                      >
                        After
                      </Badge>
                    </div>

                    {/* Overlay */}
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-all duration-300 flex items-center justify-center">
                      <Button
                        variant="secondary"
                        size="sm"
                        className="opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                        onClick={() => openDialog(item)}
                      >
                        <Eye className="h-4 w-4 mr-2" />
                        View Details
                      </Button>
                    </div>
                  </div>

                  <CardContent className="p-4">
                    <h3 className="font-semibold text-primary mb-2 line-clamp-1">
                      {item.title}
                    </h3>
                    <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
                      {item.description}
                    </p>

                    <div className="flex items-center justify-between text-xs text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <MapPin className="h-3 w-3" />
                        <span>{item.location}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        <span>
                          {new Date(item.completion_date).toLocaleDateString()}
                        </span>
                      </div>
                    </div>

                    {item.tags && item.tags.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-2">
                        {item.tags
                          .slice(0, 2)
                          .map((tag: string, tagIndex: number) => (
                            <Badge
                              key={tagIndex}
                              variant="outline"
                              className="text-xs"
                            >
                              {tag}
                            </Badge>
                          ))}
                      </div>
                    )}
                  </CardContent>
                </div>
              </Card>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Detailed View Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          {selectedItem && (
            <>
              <DialogHeader>
                <DialogTitle className="text-xl font-bold">
                  {selectedItem.title}
                </DialogTitle>
              </DialogHeader>

              <div className="space-y-6">
                {/* Interactive Before/After Slider */}
                <div className="relative aspect-video overflow-hidden rounded-lg bg-gray-100">
                  <div className="relative w-full h-full">
                    {/* After Image (Background) */}
                    <Image
                      src={selectedItem.after_image_url}
                      alt={`${selectedItem.title} - After`}
                      fill
                      className="object-cover"
                    />

                    {/* Before Image (Overlay with clip) */}
                    <div
                      className="absolute top-0 left-0 h-full overflow-hidden"
                      style={{ width: `${imageComparison}%` }}
                    >
                      <Image
                        src={selectedItem.before_image_url}
                        alt={`${selectedItem.title} - Before`}
                        fill
                        className="object-cover"
                      />
                    </div>

                    {/* Slider Handle */}
                    <div
                      className="absolute top-0 h-full w-1 bg-white shadow-lg cursor-ew-resize flex items-center justify-center"
                      style={{ left: `${imageComparison}%` }}
                    >
                      <div className="w-8 h-8 bg-white rounded-full shadow-lg flex items-center justify-center">
                        <ChevronLeft className="h-3 w-3 text-gray-600" />
                        <ChevronRight className="h-3 w-3 text-gray-600" />
                      </div>
                    </div>

                    {/* Labels */}
                    <div className="absolute top-4 left-4">
                      <Badge className="bg-black/70 text-white">Before</Badge>
                    </div>
                    <div className="absolute top-4 right-4">
                      <Badge className="bg-accent text-accent-foreground">
                        After
                      </Badge>
                    </div>
                  </div>

                  {/* Slider Input */}
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={imageComparison}
                    onChange={e => setImageComparison(Number(e.target.value))}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-ew-resize"
                  />
                </div>

                {/* Project Details */}
                <div className="grid md:grid-cols-2 gap-6">
                  <div>
                    <h3 className="font-semibold mb-2">Project Details</h3>
                    <div className="space-y-2 text-sm">
                      <div className="flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-muted-foreground" />
                        <span>{selectedItem.location}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-muted-foreground" />
                        <span>
                          Completed:{' '}
                          {new Date(
                            selectedItem.completion_date
                          ).toLocaleDateString()}
                        </span>
                      </div>
                      {selectedItem.service_type && (
                        <div className="flex items-center gap-2">
                          <Tag className="h-4 w-4 text-muted-foreground" />
                          <span>Service: {selectedItem.service_type}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  <div>
                    <h3 className="font-semibold mb-2">Description</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {selectedItem.description}
                    </p>

                    {selectedItem.tags && selectedItem.tags.length > 0 && (
                      <div className="mt-4">
                        <h4 className="font-medium mb-2 text-sm">Tags</h4>
                        <div className="flex flex-wrap gap-1">
                          {selectedItem.tags.map(
                            (tag: string, tagIndex: number) => (
                              <Badge
                                key={tagIndex}
                                variant="outline"
                                className="text-xs"
                              >
                                {tag}
                              </Badge>
                            )
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
