# Supabase Setup Guide - Avodah Educa

This guide provides complete instructions for setting up and deploying the Supabase backend for the Avodah Educa educational platform.

## 📋 Overview

The Avodah Educa platform includes:
- **Authentication**: Email/password with role-based access (student, teacher, admin)
- **Database**: Complete educational platform schema with courses, lessons, progress tracking
- **Storage**: File uploads for avatars, course materials, assignments, certificates
- **Real-time**: Live notifications, progress updates, collaborative features
- **Functions**: Server-side logic for business operations

## 🚀 Quick Setup

### 1. Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- [Docker](https://www.docker.com/) installed (for local development)
- Supabase account (for production deployment)

### 2. Environment Variables

Create `.env.local` file in project root:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 3. Local Development Setup

```bash
# Initialize Supabase locally
supabase start

# Check status
supabase status

# Apply migrations
supabase db reset

# Seed with sample data
supabase db seed
```

### 4. Production Deployment

```bash
# Link to your Supabase project
supabase link --project-ref YOUR_PROJECT_ID

# Push database changes
supabase db push

# Apply seed data (optional)
supabase db seed --remote
```

## 📊 Database Schema

### Core Tables

1. **profiles** - User profiles extending auth.users
2. **categories** - Course categories
3. **courses** - Main courses with metadata
4. **course_modules** - Course organization
5. **lessons** - Individual lesson content
6. **enrollments** - Student course enrollments
7. **lesson_progress** - Individual lesson completion tracking
8. **assignments** - Student assignments and submissions
9. **notifications** - System notifications

### Key Features

- **Automatic Timestamps**: All tables have created_at/updated_at
- **Soft Deletes**: Important records are preserved
- **Progress Tracking**: Automatic course progress calculation
- **Role-Based Access**: Student, teacher, admin permissions
- **Search & Analytics**: Built-in search and statistics functions

## 🔐 Authentication & Authorization

### User Roles

- **Student**: Can enroll in courses, track progress, submit assignments
- **Teacher**: Can create courses, manage content, grade assignments
- **Admin**: Full system access, user management, analytics

### Row Level Security (RLS)

All tables have comprehensive RLS policies:
- Users can only access their own data
- Teachers can manage their course content
- Admins have full access
- Public content is visible to all

## 📁 Storage Configuration

### Buckets

1. **profiles** (5MB, public)
   - User avatars
   - Profile images

2. **courses** (10MB, public)
   - Course thumbnails
   - Course cover images
   - Video content
   - PDF materials

3. **assignments** (20MB, private)
   - Student submissions
   - Assignment files
   - Instructor feedback files

4. **certificates** (2MB, public)
   - Generated certificates
   - Templates

### Storage Policies

- Users can upload/manage their own profile images
- Instructors can manage their course materials
- Students can upload assignment submissions
- Public access for published course materials
- Admin access to all buckets

## ⚡ Real-time Features

### Enabled Tables

- `notifications` - Live notifications
- `lesson_progress` - Real-time progress updates
- `enrollments` - Course enrollment updates
- `assignments` - Assignment submission updates

### Usage Example

```typescript
// Subscribe to notifications
const { data, error } = await supabase
  .from('notifications')
  .select('*')
  .eq('user_id', user.id)
  .order('created_at', { ascending: false });

// Real-time subscription
const subscription = supabase
  .channel('notifications')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${user.id}`
  }, (payload) => {
    console.log('New notification:', payload.new);
  })
  .subscribe();
```

## 🔧 Functions & Procedures

### Core Functions

1. **create_notification()** - Create system notifications
2. **enroll_in_course()** - Handle course enrollment
3. **complete_lesson()** - Mark lesson as completed
4. **get_course_progress()** - Calculate course progress
5. **search_courses()** - Advanced course search

### Usage Examples

```sql
-- Enroll in a course
SELECT public.enroll_in_course('course-uuid-here');

-- Complete a lesson
SELECT public.complete_lesson('lesson-uuid-here');

-- Get course progress
SELECT public.get_course_progress('course-uuid-here', 'student-uuid-here');

-- Search courses
SELECT * FROM public.search_courses('React', 'tecnologia', 'beginner');
```

## 🎯 Key Features Implementation

### 1. Course Progress Tracking

Automatic progress calculation based on required lessons:
- Updates on lesson completion
- Triggers course completion when 100%
- Generates completion certificates
- Sends notifications

### 2. Role-Based Routing

Middleware checks user roles for protected routes:
```typescript
// In middleware.ts - already implemented
const hasRequiredRole = await supabase
  .from('profiles')
  .select('role')
  .eq('id', user.id)
  .single();
```

### 3. File Upload Handling

```typescript
// Avatar upload example - already implemented in avatar-upload.tsx
const { data, error } = await supabase.storage
  .from('profiles')
  .upload(`avatars/${uniqueFileName}`, file);
```

### 4. Real-time Notifications

```typescript
// Create notification
await supabase.rpc('create_notification', {
  p_user_id: userId,
  p_title: 'Course Completed!',
  p_message: 'Congratulations on completing the course!',
  p_type: 'course_completed'
});
```

## 🔍 Analytics & Reporting

### Available Views

1. **dashboard_course_stats** - Course enrollment and completion statistics
2. **student_dashboard** - Student progress overview
3. **instructor_dashboard** - Instructor course management data

### Usage

```sql
-- Get course statistics
SELECT * FROM public.dashboard_course_stats WHERE instructor_id = 'uuid';

-- Get student progress
SELECT * FROM public.student_dashboard;

-- Get instructor overview
SELECT * FROM public.instructor_dashboard;
```

## 🛠 Development Tools

### Useful Queries

```sql
-- Check database setup
SELECT 'Database setup complete!' as message;

-- List all tables
SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public';

-- Check RLS policies
SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- View storage buckets
SELECT * FROM storage.buckets;
```

### Testing Data

```sql
-- Promote user to teacher
UPDATE public.profiles SET role = 'teacher' WHERE email = 'teacher@example.com';

-- Promote user to admin  
UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@example.com';

-- Create sample course (after instructor signup)
INSERT INTO public.courses (title, slug, instructor_id, category_id, status, level, duration_minutes, price, is_free)
VALUES ('Sample Course', 'sample-course', 'instructor-uuid', 'category-uuid', 'published', 'beginner', 120, 0, true);
```

## 🔄 Migrations

### File Structure

```
supabase/
├── migrations/
│   ├── 001_initial_schema.sql      # Core database schema
│   ├── 002_rls_policies.sql        # Row Level Security policies
│   ├── 003_storage_setup.sql       # Storage buckets and policies
│   └── 004_functions_and_realtime.sql # Functions and real-time config
├── config.toml                     # Supabase configuration
└── seed.sql                        # Sample data
```

### Running Migrations

```bash
# Local development
supabase db reset  # Runs all migrations + seed

# Production (careful!)
supabase db push   # Pushes migrations only
```

## 🚨 Important Notes

### Security
- All tables have RLS enabled
- Service role key should be kept secure
- Storage policies prevent unauthorized access
- Input validation on all functions

### Performance
- Indexes on frequently queried columns
- Views for complex queries
- Pagination in search functions
- Optimized triggers

### Backup Strategy
- Automatic backups on Supabase Cloud
- Regular database dumps for local development
- Migration files in version control

## 🔧 Troubleshooting

### Common Issues

1. **Migration Errors**
   ```bash
   supabase db reset  # Reset local database
   ```

2. **RLS Policy Issues**
   ```sql
   -- Check if RLS is enabled
   SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
   ```

3. **Storage Policy Issues**
   ```sql
   -- List storage policies
   SELECT * FROM storage.policies;
   ```

### Logs and Monitoring

```bash
# View Supabase logs
supabase logs

# Database logs
supabase logs db

# Storage logs  
supabase logs storage
```

## 📞 Support

For issues specific to Avodah Educa implementation:
1. Check migration files for schema details
2. Review RLS policies for permission issues
3. Test storage policies with sample uploads
4. Verify function signatures match frontend usage

---

**Status**: ✅ Complete Supabase backend ready for deployment