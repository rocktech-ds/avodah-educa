-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create custom types
create type user_role as enum ('student', 'teacher', 'admin');
create type enrollment_status as enum ('active', 'completed', 'dropped', 'pending');
create type course_status as enum ('draft', 'published', 'archived');
create type lesson_type as enum ('video', 'text', 'quiz', 'assignment', 'interactive');

-- Profiles table (extends auth.users)
create table public.profiles (
    id uuid references auth.users(id) on delete cascade primary key,
    email text unique not null,
    full_name text not null,
    avatar_url text,
    role user_role not null default 'student',
    bio text,
    date_of_birth date,
    phone text,
    address jsonb,
    preferences jsonb default '{}',
    is_verified boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Categories table
create table public.categories (
    id uuid default uuid_generate_v4() primary key,
    name text not null unique,
    slug text not null unique,
    description text,
    color text default '#13a4ec',
    icon text,
    parent_id uuid references public.categories(id) on delete set null,
    sort_order integer default 0,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Courses table
create table public.courses (
    id uuid default uuid_generate_v4() primary key,
    title text not null,
    slug text not null unique,
    description text,
    short_description text,
    thumbnail_url text,
    cover_image_url text,
    instructor_id uuid references public.profiles(id) on delete set null not null,
    category_id uuid references public.categories(id) on delete set null,
    status course_status default 'draft',
    level text check (level in ('beginner', 'intermediate', 'advanced')),
    duration_minutes integer default 0,
    price decimal(10,2) default 0,
    is_free boolean default true,
    max_students integer,
    prerequisites text[],
    learning_objectives text[],
    tags text[],
    language text default 'pt',
    certificate_template text,
    sort_order integer default 0,
    is_featured boolean default false,
    published_at timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Course modules table
create table public.course_modules (
    id uuid default uuid_generate_v4() primary key,
    course_id uuid references public.courses(id) on delete cascade not null,
    title text not null,
    description text,
    sort_order integer default 0,
    is_required boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Lessons table
create table public.lessons (
    id uuid default uuid_generate_v4() primary key,
    course_id uuid references public.courses(id) on delete cascade not null,
    module_id uuid references public.course_modules(id) on delete cascade,
    title text not null,
    slug text not null,
    description text,
    content text,
    type lesson_type default 'text',
    video_url text,
    video_duration integer,
    attachments jsonb default '[]',
    quiz_data jsonb,
    assignment_data jsonb,
    sort_order integer default 0,
    is_preview boolean default false,
    is_required boolean default true,
    estimated_minutes integer default 15,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(course_id, slug)
);

-- Enrollments table
create table public.enrollments (
    id uuid default uuid_generate_v4() primary key,
    student_id uuid references public.profiles(id) on delete cascade not null,
    course_id uuid references public.courses(id) on delete cascade not null,
    status enrollment_status default 'active',
    progress_percentage decimal(5,2) default 0,
    started_at timestamp with time zone default timezone('utc'::text, now()) not null,
    completed_at timestamp with time zone,
    certificate_url text,
    notes text,
    rating integer check (rating >= 1 and rating <= 5),
    review text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(student_id, course_id)
);

-- Lesson progress table
create table public.lesson_progress (
    id uuid default uuid_generate_v4() primary key,
    student_id uuid references public.profiles(id) on delete cascade not null,
    lesson_id uuid references public.lessons(id) on delete cascade not null,
    enrollment_id uuid references public.enrollments(id) on delete cascade not null,
    is_completed boolean default false,
    completion_percentage decimal(5,2) default 0,
    time_spent_minutes integer default 0,
    quiz_score integer,
    quiz_attempts integer default 0,
    assignment_submitted boolean default false,
    assignment_score integer,
    notes text,
    completed_at timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(student_id, lesson_id)
);

-- Assignments table
create table public.assignments (
    id uuid default uuid_generate_v4() primary key,
    lesson_id uuid references public.lessons(id) on delete cascade not null,
    student_id uuid references public.profiles(id) on delete cascade not null,
    title text not null,
    description text,
    submission_text text,
    submission_files jsonb default '[]',
    instructor_feedback text,
    grade integer check (grade >= 0 and grade <= 100),
    is_submitted boolean default false,
    is_graded boolean default false,
    submitted_at timestamp with time zone,
    graded_at timestamp with time zone,
    due_date timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Notifications table
create table public.notifications (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    title text not null,
    message text not null,
    type text default 'info',
    action_url text,
    is_read boolean default false,
    is_email_sent boolean default false,
    metadata jsonb default '{}',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    read_at timestamp with time zone
);

-- Create indexes for better performance
create index idx_profiles_role on public.profiles(role);
create index idx_profiles_email on public.profiles(email);
create index idx_courses_instructor on public.courses(instructor_id);
create index idx_courses_category on public.courses(category_id);
create index idx_courses_status on public.courses(status);
create index idx_courses_published_at on public.courses(published_at desc);
create index idx_lessons_course on public.lessons(course_id);
create index idx_lessons_module on public.lessons(module_id);
create index idx_enrollments_student on public.enrollments(student_id);
create index idx_enrollments_course on public.enrollments(course_id);
create index idx_enrollments_status on public.enrollments(status);
create index idx_lesson_progress_student on public.lesson_progress(student_id);
create index idx_lesson_progress_lesson on public.lesson_progress(lesson_id);
create index idx_assignments_lesson on public.assignments(lesson_id);
create index idx_assignments_student on public.assignments(student_id);
create index idx_notifications_user on public.notifications(user_id);
create index idx_notifications_unread on public.notifications(user_id, is_read) where not is_read;

-- Create updated_at trigger function
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = timezone('utc'::text, now());
    return new;
end;
$$ language plpgsql security definer;

-- Apply updated_at triggers
create trigger handle_updated_at before update on public.profiles for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.categories for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.courses for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.course_modules for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.lessons for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.enrollments for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.lesson_progress for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.assignments for each row execute procedure public.handle_updated_at();

-- Function to create user profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, full_name, role)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        coalesce((new.raw_user_meta_data->>'role')::user_role, 'student')
    );
    return new;
end;
$$ language plpgsql security definer;

-- Trigger to create profile on user signup
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Function to update course progress
create or replace function public.update_course_progress()
returns trigger as $$
declare
    total_lessons integer;
    completed_lessons integer;
    new_progress decimal(5,2);
begin
    -- Count total required lessons in the course
    select count(*) into total_lessons
    from public.lessons l
    where l.course_id = (
        select l2.course_id 
        from public.lessons l2 
        where l2.id = new.lesson_id
    ) and l.is_required = true;
    
    -- Count completed required lessons for this student
    select count(*) into completed_lessons
    from public.lesson_progress lp
    join public.lessons l on l.id = lp.lesson_id
    where lp.student_id = new.student_id 
    and l.course_id = (
        select l2.course_id 
        from public.lessons l2 
        where l2.id = new.lesson_id
    )
    and l.is_required = true
    and lp.is_completed = true;
    
    -- Calculate new progress percentage
    if total_lessons > 0 then
        new_progress = (completed_lessons::decimal / total_lessons::decimal) * 100;
        
        -- Update enrollment progress
        update public.enrollments
        set 
            progress_percentage = new_progress,
            completed_at = case 
                when new_progress >= 100 then timezone('utc'::text, now())
                else null
            end,
            status = case 
                when new_progress >= 100 then 'completed'::enrollment_status
                else status
            end
        where student_id = new.student_id 
        and course_id = (
            select l.course_id 
            from public.lessons l 
            where l.id = new.lesson_id
        );
    end if;
    
    return new;
end;
$$ language plpgsql security definer;

-- Trigger to update course progress when lesson is completed
create trigger update_course_progress_trigger
    after update of is_completed on public.lesson_progress
    for each row
    when (old.is_completed = false and new.is_completed = true)
    execute procedure public.update_course_progress();