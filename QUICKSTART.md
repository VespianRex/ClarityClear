# 🚀 ClarityClear Quick Start Guide

Get ClarityClear running locally in 5 minutes!

## Prerequisites

- Node.js 18+ and npm
- Git

## 1. Clone & Install

```bash
git clone <repository-url>
cd ClarityClear
npm install
```

## 2. Environment Setup

Copy the environment template:
```bash
cp .env.example .env.local
```

Edit `.env.local` with your settings (minimum required):
```env
NEXT_PUBLIC_POCKETBASE_URL=http://localhost:8090
POCKETBASE_ADMIN_EMAIL=admin@clarityclear.com
POCKETBASE_ADMIN_PASSWORD=your_secure_password
NEXT_PUBLIC_SITE_URL=http://localhost:9002
NEXT_PUBLIC_WHATSAPP_PHONE_NUMBER=1234567890
SMTP_HOST=smtp.gmail.com
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
NEXTAUTH_SECRET=your_random_secret_here
```

## 3. Database Setup

Initialize PocketBase with sample data:
```bash
npm run setup:pocketbase
```

## 4. Start Development

**Terminal 1 - Database:**
```bash
npm run pocketbase
```

**Terminal 2 - Frontend:**
```bash
npm run dev
```

## 5. Access Your Application

- **Website**: http://localhost:9002
- **Admin Panel**: http://localhost:8090/_/
- **Login**: admin@clarityclear.com / your_secure_password

## What's Included

✅ **Complete Booking System** - Multi-step booking with validation  
✅ **Admin Dashboard** - Manage bookings, reviews, and content  
✅ **Customer Reviews** - Automated review collection and display  
✅ **WhatsApp Integration** - Direct customer communication  
✅ **Email Notifications** - Automated booking confirmations  
✅ **Payment Ready** - Stripe integration (configurable)  
✅ **Mobile Responsive** - Works perfectly on all devices  
✅ **SEO Optimized** - Built-in SEO features  

## Key Features to Test

1. **Booking Flow**: Visit `/booking` and complete a test booking
2. **Admin Dashboard**: Access admin panel to manage bookings
3. **Contact Forms**: Test contact form submissions
4. **Reviews**: Submit and manage customer reviews
5. **WhatsApp**: Click WhatsApp buttons to test integration

## Development Commands

```bash
# Development
npm run dev              # Start development server
npm run pocketbase       # Start database

# Testing
npm run test             # Unit tests
npm run test:e2e         # End-to-end tests
npm run test:all         # All tests

# Code Quality
npm run lint             # Check code quality
npm run typecheck        # Check TypeScript
npm run format           # Format code

# Production
npm run build            # Build for production
npm run start            # Start production server
```

## Need Help?

- 📖 **Full Documentation**: See [README.md](README.md)
- 🚀 **Deployment Guide**: See [DEPLOYMENT.md](DEPLOYMENT.md)
- 🐛 **Issues**: Check existing GitHub issues
- 💬 **Questions**: Create a new issue with the question label

## Next Steps

1. **Customize Content**: Update services, testimonials, and FAQ content
2. **Configure Email**: Set up proper SMTP for email notifications
3. **Add Your Branding**: Update colors, fonts, and images
4. **Test Everything**: Run through all user flows
5. **Deploy**: Follow the deployment guide for production

Happy coding! 🎉