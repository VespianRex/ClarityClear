"use client";

import { Button } from "@/components/ui/button";
import { WHATSAPP_PHONE_NUMBER, WHATSAPP_PREFILL_MESSAGE, SOCIAL_LINKS } from "@/lib/constants";
import { MessageSquareText } from "lucide-react";

interface WhatsAppButtonProps {
  className?: string;
  variant?: "icon" | "button";
  size?: "default" | "sm" | "lg" | "icon";
  text?: string;
}

export function WhatsAppButton({ className, variant = "button", size="default", text = "Chat on WhatsApp" }: WhatsAppButtonProps) {
  const whatsAppLink = SOCIAL_LINKS.find(link => link.name === "WhatsApp")?.href;

  if (!whatsAppLink) return null;

  return (
    <Button
      asChild
      variant={variant === "icon" ? "outline" : "default"}
      size={size}
      className={className}
      aria-label="Chat on WhatsApp"
    >
      <a href={whatsAppLink} target="_blank" rel="noopener noreferrer">
        <MessageSquareText className={variant === "button" && size !== "icon" ? "mr-2 h-5 w-5" : "h-5 w-5"} />
        {variant === "button" && size !== "icon" && text}
      </a>
    </Button>
  );
}
