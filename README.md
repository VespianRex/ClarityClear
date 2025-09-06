# ClarityClear

ClarityClear is a professional house clearance and waste removal service website built with Next.js, TypeScript, and PocketBase. This is a complete business solution featuring booking management, customer testimonials, payment processing, and automated review systems.

## 🌟 Features

- **Multi-step Booking System**: Streamlined booking process for clearance services
- **Service Management**: Comprehensive service listings and descriptions
- **Customer Testimonials**: Display and manage customer feedback
- **Before/After Gallery**: Visual showcase of completed work
- **Admin Dashboard**: Manage bookings, reviews, and content
- **Review Automation**: Automated review request system
- **Payment Integration**: Stripe payment processing (configurable)
- **WhatsApp Integration**: Direct customer communication
- **Email Notifications**: Automated booking confirmations and updates
- **Responsive Design**: Mobile-first, fully responsive interface
- **SEO Optimized**: Built-in SEO features and meta management

## 🛠️ Tech Stack

- **Frontend**: Next.js 15.3.3, React 18, TypeScript
- **Styling**: Tailwind CSS, Radix UI Components
- **Backend**: PocketBase (local database)
- **Authentication**: PocketBase Auth
- **Payments**: Stripe Integration
- **AI Integration**: Google AI (Genkit) for enhanced features
- **Testing**: Jest, Playwright, Testing Library
- **Animation**: Framer Motion
- **Email**: SMTP support for notifications

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Git

### 1. Clone and Install

```bash
git clone <repository-url>
cd ClarityClear
npm install
```

### 2. Environment Setup

Create a `.env.local` file in the root directory:

```env
# PocketBase Configuration
NEXT_PUBLIC_POCKETBASE_URL=http://localhost:8090
POCKETBASE_ADMIN_EMAIL=admin@clarityclear.com
POCKETBASE_ADMIN_PASSWORD=your_secure_password_here

# Site Configuration
NEXT_PUBLIC_SITE_URL=http://localhost:9002
NEXT_PUBLIC_SITE_NAME=ClarityClear

# WhatsApp Integration
NEXT_PUBLIC_WHATSAPP_PHONE_NUMBER=1234567890
NEXT_PUBLIC_WHATSAPP_BUSINESS_HOURS_START=09:00
NEXT_PUBLIC_WHATSAPP_BUSINESS_HOURS_END=17:00

# Email Configuration (for contact forms)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# Google AI (optional - for enhanced features)
GOOGLE_AI_API_KEY=your_google_ai_key_here

# Analytics (optional)
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX

# Security
NEXTAUTH_SECRET=your_nextauth_secret_here
NEXTAUTH_URL=http://localhost:9002
```

### 3. Database Setup

Set up PocketBase with sample data:

```bash
npm run setup:pocketbase
```

### 4. Start Development

Open two terminals:

**Terminal 1 - Start PocketBase:**
```bash
npm run pocketbase
```

**Terminal 2 - Start Next.js:**
```bash
npm run dev
```

### 5. Access the Application

- **Website**: http://localhost:9002
- **PocketBase Admin**: http://localhost:8090/_/
- **Admin Credentials**: admin@clarityclear.com / your_secure_password_here

## 📦 Available Scripts

### Development
- `npm run dev` - Start development server with Turbopack
- `npm run pocketbase` - Start PocketBase database server
- `npm run setup:pocketbase` - Initialize PocketBase with sample data

### Building & Production
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run check-all` - Run all checks (TypeScript + ESLint)

### Testing
- `npm run test` - Run Jest unit tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Run tests with coverage report
- `npm run test:e2e` - Run Playwright E2E tests
- `npm run test:e2e:ui` - Run E2E tests with UI
- `npm run test:all` - Run all tests (unit + E2E)

### Code Quality
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues automatically
- `npm run lint:strict` - Run ESLint with zero warnings tolerance
- `npm run typecheck` - Run TypeScript compiler check
- `npm run format` - Format code with Prettier
- `npm run format:check` - Check code formatting

### AI Features
- `npm run genkit:dev` - Start Genkit development server
- `npm run genkit:watch` - Start Genkit in watch mode

## 🏗️ Project Structure

```
ClarityClear/
├── src/
│   ├── app/                 # Next.js App Router pages
│   │   ├── (routes)/        # Main website routes
│   │   ├── admin/           # Admin dashboard pages
│   │   ├── api/             # API routes
│   │   └── globals.css      # Global styles
│   ├── components/          # Reusable React components
│   │   ├── ui/             # Base UI components (Radix UI)
│   │   ├── common/         # Shared components
│   │   ├── booking/        # Booking system components
│   │   ├── admin/          # Admin dashboard components
│   │   ├── payments/       # Payment processing components
│   │   └── reviews/        # Review management components
│   ├── hooks/              # Custom React hooks
│   ├── lib/                # Utility libraries and services
│   │   ├── pocketbase.ts   # Database client
│   │   ├── email-service.ts # Email handling
│   │   └── utils.ts        # Utility functions
│   ├── ai/                 # AI/Genkit integration
│   └── __tests__/          # Jest test files
├── e2e/                    # Playwright E2E tests
├── pb_data/                # PocketBase database files
├── pb_migrations/          # Database migrations
├── scripts/                # Setup and utility scripts
├── public/                 # Static assets
└── docs/                   # Documentation
```

## 🚀 Deployment Guide

### Production Environment Setup

1. **Environment Variables for Production:**

```env
# Production PocketBase (hosted or self-hosted)
NEXT_PUBLIC_POCKETBASE_URL=https://your-pocketbase-domain.com
POCKETBASE_ADMIN_EMAIL=admin@yourdomain.com
POCKETBASE_ADMIN_PASSWORD=your_secure_production_password

# Production Site Configuration
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
NEXT_PUBLIC_SITE_NAME=ClarityClear

# WhatsApp Business Number
NEXT_PUBLIC_WHATSAPP_PHONE_NUMBER=447123456789

# Production Email (using Gmail, SendGrid, or other SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_business_email@gmail.com
SMTP_PASS=your_app_specific_password

# Google AI for enhanced features
GOOGLE_AI_API_KEY=your_production_google_ai_key

# Google Analytics
NEXT_PUBLIC_GA_ID=G-YOURGAID

# Security (generate strong secrets)
NEXTAUTH_SECRET=your_very_long_random_secret_here
NEXTAUTH_URL=https://yourdomain.com
```

### Deployment Options

#### Option 1: Vercel (Recommended for Frontend)

1. **Deploy to Vercel:**
   ```bash
   npm i -g vercel
   vercel --prod
   ```

2. **Set Environment Variables in Vercel Dashboard:**
   - Go to your project settings
   - Add all production environment variables
   - Redeploy

3. **PocketBase Hosting:**
   - Use PocketBase Cloud, Railway, or self-host on VPS
   - Update `NEXT_PUBLIC_POCKETBASE_URL` to your hosted instance

#### Option 2: Self-Hosted (VPS/Dedicated Server)

1. **Server Requirements:**
   - Ubuntu 20.04+ or similar
   - Node.js 18+
   - Nginx (reverse proxy)
   - SSL certificate

2. **Server Setup:**
   ```bash
   # Clone repository
   git clone <your-repo> /var/www/clarityclear
   cd /var/www/clarityclear
   
   # Install dependencies
   npm ci --production
   
   # Build application
   npm run build
   
   # Set up environment
   cp .env.example .env.local
   # Edit .env.local with production values
   
   # Start PocketBase (consider using PM2 or systemd)
   ./pocketbase serve --http=127.0.0.1:8090
   
   # Start Next.js (use PM2 for production)
   npm start
   ```

3. **Nginx Configuration:**
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com;
       return 301 https://$server_name$request_uri;
   }
   
   server {
       listen 443 ssl;
       server_name yourdomain.com;
       
       ssl_certificate /path/to/certificate.crt;
       ssl_certificate_key /path/to/private.key;
       
       # Next.js frontend
       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
       
       # PocketBase API
       location /api/ {
           proxy_pass http://127.0.0.1:8090;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

#### Option 3: Docker Deployment

1. **Create Dockerfile:**
   ```dockerfile
   FROM node:18-alpine
   
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --production
   
   COPY . .
   RUN npm run build
   
   EXPOSE 3000
   CMD ["npm", "start"]
   ```

2. **Docker Compose (with PocketBase):**
   ```yaml
   version: '3.8'
   services:
     app:
       build: .
       ports:
         - "3000:3000"
       environment:
         - NEXT_PUBLIC_POCKETBASE_URL=http://pocketbase:8090
       depends_on:
         - pocketbase
     
     pocketbase:
       image: ghcr.io/muchobien/pocketbase:latest
       ports:
         - "8090:8090"
       volumes:
         - pocketbase_data:/pb_data
   
   volumes:
     pocketbase_data:
   ```

### Database Migration

1. **Export from Development:**
   ```bash
   # Backup development data
   cp -r pb_data pb_data_backup
   ```

2. **Import to Production:**
   ```bash
   # Copy data to production server
   scp -r pb_data user@server:/path/to/production/
   
   # Or use PocketBase export/import features
   ```

### Post-Deployment Checklist

- [ ] Verify all environment variables are set
- [ ] Test booking system functionality
- [ ] Verify email notifications work
- [ ] Test payment processing (if enabled)
- [ ] Check WhatsApp integration
- [ ] Verify admin dashboard access
- [ ] Test responsive design on mobile
- [ ] Set up monitoring and backups
- [ ] Configure SSL certificate
- [ ] Set up domain and DNS
- [ ] Test contact forms
- [ ] Verify SEO meta tags

## 🔧 Configuration

### Email Setup

For production email functionality:

1. **Gmail SMTP:**
   - Enable 2FA on your Google account
   - Generate an App Password
   - Use the App Password in `SMTP_PASS`

2. **SendGrid (Alternative):**
   ```env
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USER=apikey
   SMTP_PASS=your_sendgrid_api_key
   ```

### WhatsApp Integration

Update your business WhatsApp number:
```env
NEXT_PUBLIC_WHATSAPP_PHONE_NUMBER=447123456789  # Include country code
```

### Payment Processing

To enable Stripe payments:
1. Create a Stripe account
2. Add API keys to environment variables
3. Configure webhooks for payment confirmations

## 🧪 Testing

### Running Tests

```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# All tests with coverage
npm run test:all
```

### Test Coverage

The project includes comprehensive tests for:
- Component rendering and interactions
- API endpoints and data handling
- Booking system workflow
- Payment processing
- Email functionality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `npm run test:all`
5. Run linting: `npm run lint:strict`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Development Guidelines

- Follow TypeScript best practices
- Write tests for new features
- Ensure responsive design
- Follow the existing code style
- Update documentation as needed

## 📝 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🆘 Support

For support and questions:

1. Check the [FAQ section](src/app/faq/page.tsx)
2. Review existing [GitHub Issues](../../issues)
3. Create a new issue with detailed information
4. For urgent matters, contact the development team

## 🔗 Links

- **Live Demo**: [Your deployed URL]
- **PocketBase Documentation**: https://pocketbase.io/docs/
- **Next.js Documentation**: https://nextjs.org/docs
- **Tailwind CSS**: https://tailwindcss.com/docs