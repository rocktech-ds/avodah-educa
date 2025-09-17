# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
- `pnpm dev` - Start Next.js development server on localhost:3000
- `pnpm build` - Create production build
- `pnpm start` - Run production server
- `pnpm lint` - Run ESLint for code quality checks
- `pnpm typecheck` - Run TypeScript type checking (tsc --noEmit)

### Testing
- `pnpm test` - Run Jest tests
- `pnpm test:watch` - Run Jest in watch mode for development

### Git
- `pnpm commit` - Use Commitizen for conventional commits

## Architecture Overview

### Tech Stack
- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript with strict type safety
- **Database**: PostgreSQL via Supabase (self-hosted)
- **Auth**: Supabase Auth with JWT tokens
- **UI**: shadcn/ui components + Radix UI primitives
- **Styling**: Tailwind CSS with custom education theme
- **PWA**: Progressive Web App with offline support

### Authentication Flow
1. **Middleware** (`src/middleware.ts`) protects routes based on authentication state and user roles
2. **Auth Utilities** (`src/lib/auth/utils.ts`) provide `AuthClient` (browser) and `AuthServer` (SSR) classes
3. **Role System**: Three roles - Student, Teacher, Admin - with different dashboards and permissions
4. **Protected Routes**:
   - `/student/*` - Student dashboard
   - `/teacher/*` - Teacher dashboard
   - `/admin/*` - Admin dashboard
   - `/profile` - User profile (all roles)

### Database Architecture
The app uses Supabase with Row Level Security (RLS) policies. Key tables:
- `profiles` - Extended user data linked to auth.users
- `courses`, `course_modules`, `lessons` - Hierarchical course content
- `enrollments`, `lesson_progress` - Student progress tracking
- `assignments`, `assignment_submissions` - Assignment workflow

Types are fully defined in `src/lib/supabase/client.ts` with proper TypeScript interfaces.

### Component Structure
- **UI Components** (`src/components/ui/`): Reusable shadcn/ui components
- **Feature Components** (`src/components/[feature]/`): Domain-specific components (auth, courses, profile)
- **Layout Components** (`src/components/layout/`): Sidebar and navigation
- All components follow consistent prop typing and styling patterns

### Key Patterns
1. **Server Components by Default**: Use client components only when needed (marked with "use client")
2. **Data Fetching**: Use React Query for server state management
3. **Error Handling**: Toast notifications for user feedback
4. **Type Safety**: Database types exported from `src/lib/supabase/client.ts`
5. **File Uploads**: Handled through Supabase Storage for assignments

## Environment Variables
Required in `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
DATABASE_URL
SUPABASE_JWT_SECRET
NEXT_PUBLIC_SITE_URL
```

## Development Notes
- The project uses pnpm as the package manager
- Tailwind config includes custom colors with Platform Blue (#13a4ec) as primary
- Font: Manrope (Google Fonts)
- PWA manifest configured for mobile app experience
- Standalone output mode enabled for containerization
- to access the VPS use the: ssh rocktech