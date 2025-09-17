# Avodah Educa - Setup Guide

## 📚 Overview

Avodah Educa is a modern educational platform built with Next.js 15, Supabase, and TypeScript. The platform supports role-based access control with three user types: Students, Teachers, and Admins.

## 🏗️ Architecture

- **Frontend**: Next.js 15 with App Router, TypeScript, Tailwind CSS
- **Backend**: Supabase (PostgreSQL + Authentication)
- **UI Components**: shadcn/ui + Radix UI primitives
- **Styling**: Tailwind CSS with custom education theme
- **Authentication**: Supabase Auth with JWT
- **Database**: PostgreSQL with Row Level Security (RLS)

## 🚀 Quick Start

### 1. Environment Setup

Create your `.env.local` file based on the template:

```bash
cp .env.local.example .env.local
```

Update the variables with your VPS Supabase instance details:

```env
# Supabase Self-Hosted Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-supabase-domain.com
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anonymous_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
DATABASE_URL=postgresql://postgres:password@your-vps-ip:5432/avodah_educa
SUPABASE_JWT_SECRET=your_jwt_secret
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

### 2. Database Setup

Run the migrations on your VPS Supabase instance:

1. **Schema Migration**:
   ```sql
   -- Run: supabase/migrations/001_initial_schema.sql
   ```

2. **RLS Policies**:
   ```sql
   -- Run: supabase/migrations/002_rls_policies.sql
   ```

3. **Sample Data** (optional):
   ```sql
   -- Run: supabase/seed.sql
   ```

### 3. Install Dependencies

```bash
pnpm install
```

### 4. Run Development Server

```bash
pnpm dev
```

The application will be available at `http://localhost:3000`.

## 📊 Database Schema

### Core Tables

- **profiles**: User profiles extending Supabase auth.users
- **categories**: Course categories with hierarchical support
- **courses**: Main course entities with metadata
- **course_modules**: Course organization into modules
- **lessons**: Individual lessons with multiple types (video, text, quiz, etc.)
- **enrollments**: Student course enrollments with progress tracking
- **lesson_progress**: Detailed progress tracking per lesson
- **assignments**: Assignment submissions and grading
- **notifications**: User notification system

### Key Features

- **Automatic Profile Creation**: Triggered when user signs up
- **Progress Calculation**: Automatic course progress updates
- **Row Level Security**: Complete data isolation by user roles
- **Audit Trails**: Created/updated timestamps on all entities

## 🔐 Authentication & Authorization

### User Roles

- **Student**: Access enrolled courses, track progress, submit assignments
- **Teacher**: Create/manage courses, grade assignments, view student progress
- **Admin**: Full platform access, user management, system configuration

### Route Protection

- Middleware-based route protection
- Role-based access control
- Automatic redirects based on user role
- Session management with Supabase Auth

### Protected Routes

- `/dashboard` - All authenticated users
- `/student/*` - Students only
- `/teacher/*` - Teachers and Admins
- `/admin/*` - Admins only
- `/auth/*` - Unauthenticated users only

## 🎨 UI Components

### Design System

- **Colors**: Platform blue (#13a4ec) as primary
- **Typography**: Manrope font family
- **Components**: shadcn/ui components with educational theming
- **Responsive**: Mobile-first responsive design

### Key Components

- **Authentication Forms**: Login, Register, Forgot Password
- **Navigation**: Role-based navigation with responsive sidebar
- **Course Cards**: Interactive course display components
- **Progress Tracking**: Visual progress indicators
- **Toast Notifications**: User feedback system

## 📁 Project Structure

```
src/
├── app/                    # Next.js App Router
│   ├── auth/              # Authentication pages
│   ├── dashboard/         # Main dashboard
│   ├── student/           # Student-specific pages
│   ├── teacher/           # Teacher-specific pages
│   └── admin/             # Admin-specific pages
├── components/            # React components
│   ├── auth/              # Authentication components
│   ├── navigation/        # Navigation components
│   └── ui/                # shadcn/ui components
├── lib/                   # Utility libraries
│   ├── supabase/          # Supabase clients
│   └── auth/              # Authentication utilities
├── types/                 # TypeScript type definitions
└── styles/               # Global styles and Tailwind config

supabase/
├── migrations/           # Database migrations
└── seed.sql             # Sample data
```

## 🔧 Development Workflow

### Database Migrations

When making schema changes:

1. Create migration file in `supabase/migrations/`
2. Apply to your VPS Supabase instance
3. Update TypeScript types in `src/lib/supabase/client.ts`

### Adding New Features

1. Define types in `src/types/`
2. Create database operations
3. Build UI components
4. Update navigation if needed
5. Add route protection

### Testing Authentication

1. Navigate to `/auth/register`
2. Create accounts with different roles
3. Test role-based access
4. Verify middleware protection

## 🛠️ VPS Supabase Connection

### Required Environment Variables

Your VPS Supabase instance should provide:

- **SUPABASE_URL**: Your Supabase instance URL
- **SUPABASE_ANON_KEY**: Anonymous/public key for client-side
- **SUPABASE_SERVICE_ROLE_KEY**: Service role key for admin operations
- **JWT_SECRET**: For token verification

### Database Connection

The application uses two types of connections:

1. **Client-side**: Browser client for user operations
2. **Server-side**: Server client for SSR and API routes

### Security Configuration

Ensure your VPS Supabase has:

- RLS policies enabled
- Proper CORS settings
- JWT configuration matching your keys
- SSL/TLS certificates for production

## 📈 Next Steps

### Immediate Tasks

1. ✅ Connect to your VPS Supabase instance
2. ✅ Run database migrations
3. ✅ Test authentication flow
4. ⏳ Create your first admin user
5. ⏳ Upload sample course content

### Future Enhancements

- Video streaming integration
- Payment processing
- Advanced analytics
- Mobile app (React Native)
- API documentation
- Automated testing suite

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection**: Verify environment variables and network access
2. **Authentication Errors**: Check JWT secrets and Supabase configuration
3. **RLS Policies**: Ensure policies are correctly applied
4. **CORS Issues**: Configure allowed origins in Supabase settings

### Debug Mode

Enable debug logging by adding to `.env.local`:
```env
NODE_ENV=development
DEBUG=supabase:*
```

## 📞 Support

For issues or questions:

1. Check the troubleshooting section
2. Review Supabase logs on your VPS
3. Check browser console for client-side errors
4. Verify database connectivity

---

**🎓 Ready to start educating! Your Avodah Educa platform is configured and ready for content creation.**