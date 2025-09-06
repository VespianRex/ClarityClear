'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { CreditCard, Lock, AlertCircle } from 'lucide-react';
import { useSettings } from '@/lib/settings-service';

interface StripePaymentProps {
  amount: number;
  description: string;
  bookingId?: string;
  onSuccess?: (_: string) => void;
  onError?: (_: string) => void;
}

export function StripePayment({
  amount,
  description,
  bookingId: _bookingId,
  onSuccess,
  onError,
}: StripePaymentProps) {
  const [isEnabled, setIsEnabled] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [cardDetails, setCardDetails] = useState({
    number: '',
    expiry: '',
    cvc: '',
    name: '',
  });

  const { getSetting } = useSettings();

  useEffect(() => {
    checkIfEnabled();
  }, []);

  const checkIfEnabled = async () => {
    const enabled = await getSetting('features.online_payments', false);
    setIsEnabled(enabled);
  };

  const processPayment = async () => {
    setIsProcessing(true);

    try {
      // In production, integrate with Stripe:
      // 1. Create payment intent on server
      // 2. Confirm payment with Stripe Elements
      // 3. Handle success/failure

      // Mock payment processing
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Simulate success (90% of the time)
      if (Math.random() > 0.1) {
        const mockPaymentId = `pi_${Date.now()}`;

        // Save payment record to PocketBase
        // await pb.collection('payments').create({
        //   booking_id: bookingId,
        //   amount,
        //   currency: 'GBP',
        //   status: 'completed',
        //   payment_method: 'card',
        //   stripe_payment_id: mockPaymentId,
        //   description
        // });

        onSuccess?.(mockPaymentId);
      } else {
        throw new Error('Payment failed - insufficient funds');
      }
    } catch (error: any) {
      onError?.(error.message);
    } finally {
      setIsProcessing(false);
    }
  };

  const formatCardNumber = (value: string) => {
    const v = value.replace(/\s+/g, '').replace(/[^0-9]/gi, '');
    const matches = v.match(/\d{4,16}/g);
    const match = (matches && matches[0]) || '';
    const parts = [];
    for (let i = 0, len = match.length; i < len; i += 4) {
      parts.push(match.substring(i, i + 4));
    }
    if (parts.length) {
      return parts.join(' ');
    } else {
      return v;
    }
  };

  const formatExpiry = (value: string) => {
    const v = value.replace(/\D/g, '');
    if (v.length >= 2) {
      return v.substring(0, 2) + '/' + v.substring(2, 4);
    }
    return v;
  };

  if (!isEnabled) {
    return (
      <Card className="border-dashed">
        <CardContent className="text-center py-8">
          <CreditCard className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
          <p className="text-muted-foreground">
            Online payments are not currently enabled.
          </p>
          <p className="text-sm text-muted-foreground mt-2">
            Please contact us to arrange payment.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <CreditCard className="h-5 w-5 text-accent" />
          Secure Payment
        </CardTitle>
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">{description}</p>
          <Badge variant="secondary" className="text-lg font-semibold">
            £{amount.toFixed(2)}
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Security Notice */}
        <div className="flex items-center gap-2 p-3 bg-green-50 rounded-lg border border-green-200">
          <Lock className="h-4 w-4 text-green-600" />
          <p className="text-sm text-green-800">
            Your payment is secured by 256-bit SSL encryption
          </p>
        </div>

        {/* Card Details Form */}
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="cardName">Cardholder Name</Label>
            <Input
              id="cardName"
              placeholder="John Smith"
              value={cardDetails.name}
              onChange={e =>
                setCardDetails(prev => ({ ...prev, name: e.target.value }))
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="cardNumber">Card Number</Label>
            <Input
              id="cardNumber"
              placeholder="1234 5678 9012 3456"
              value={cardDetails.number}
              onChange={e =>
                setCardDetails(prev => ({
                  ...prev,
                  number: formatCardNumber(e.target.value),
                }))
              }
              maxLength={19}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="expiry">Expiry Date</Label>
              <Input
                id="expiry"
                placeholder="MM/YY"
                value={cardDetails.expiry}
                onChange={e =>
                  setCardDetails(prev => ({
                    ...prev,
                    expiry: formatExpiry(e.target.value),
                  }))
                }
                maxLength={5}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="cvc">CVC</Label>
              <Input
                id="cvc"
                placeholder="123"
                value={cardDetails.cvc}
                onChange={e =>
                  setCardDetails(prev => ({
                    ...prev,
                    cvc: e.target.value.replace(/\D/g, '').substring(0, 4),
                  }))
                }
                maxLength={4}
              />
            </div>
          </div>
        </div>

        {/* Demo Notice */}
        <div className="flex items-start gap-2 p-3 bg-blue-50 rounded-lg border border-blue-200">
          <AlertCircle className="h-4 w-4 text-blue-600 mt-0.5 flex-shrink-0" />
          <div className="text-xs text-blue-800">
            <p className="font-semibold">Demo Mode</p>
            <p>
              This is a demonstration. No real payment will be processed. In
              production, this would integrate with Stripe for secure payments.
            </p>
          </div>
        </div>

        {/* Payment Button */}
        <Button
          onClick={processPayment}
          disabled={
            isProcessing ||
            !cardDetails.name ||
            !cardDetails.number ||
            !cardDetails.expiry ||
            !cardDetails.cvc
          }
          className="w-full"
          size="lg"
        >
          {isProcessing ? (
            <>Processing...</>
          ) : (
            <>
              <Lock className="mr-2 h-4 w-4" />
              Pay £{amount.toFixed(2)}
            </>
          )}
        </Button>

        <p className="text-xs text-muted-foreground text-center">
          By clicking "Pay", you agree to our terms and conditions
        </p>
      </CardContent>
    </Card>
  );
}
