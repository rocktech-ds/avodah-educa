-- Enable Row Level Security on all tables
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.courses enable row level security;
alter table public.course_modules enable row level security;
alter table public.lessons enable row level security;
alter table public.enrollments enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.assignments enable row level security;
alter table public.notifications enable row level security;

-- Profiles policies
create policy "Public profiles are viewable by everyone" on public.profiles
    for select using (true);

create policy "Users can insert their own profile" on public.profiles
    for insert with check (auth.uid() = id);

create policy "Users can update their own profile" on public.profiles
    for update using (auth.uid() = id);

create policy "Admins can update any profile" on public.profiles
    for update using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Categories policies
create policy "Categories are viewable by everyone" on public.categories
    for select using (is_active = true or exists (
        select 1 from public.profiles
        where id = auth.uid() and role in ('teacher', 'admin')
    ));

create policy "Teachers and admins can manage categories" on public.categories
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role in ('teacher', 'admin')
        )
    );

-- Courses policies
create policy "Published courses are viewable by everyone" on public.courses
    for select using (
        status = 'published' or 
        instructor_id = auth.uid() or
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

create policy "Instructors can manage their own courses" on public.courses
    for all using (instructor_id = auth.uid());

create policy "Teachers can create courses" on public.courses
    for insert with check (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role in ('teacher', 'admin')
        ) and instructor_id = auth.uid()
    );

create policy "Admins can manage all courses" on public.courses
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Course modules policies
create policy "Course modules are viewable by enrolled students and course owners" on public.course_modules
    for select using (
        exists (
            select 1 from public.courses c
            where c.id = course_id and (
                c.status = 'published' or
                c.instructor_id = auth.uid() or
                exists (
                    select 1 from public.profiles
                    where id = auth.uid() and role = 'admin'
                )
            )
        )
    );

create policy "Course instructors can manage their course modules" on public.course_modules
    for all using (
        exists (
            select 1 from public.courses c
            where c.id = course_id and c.instructor_id = auth.uid()
        )
    );

create policy "Admins can manage all course modules" on public.course_modules
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Lessons policies
create policy "Lessons are viewable by enrolled students and course owners" on public.lessons
    for select using (
        exists (
            select 1 from public.courses c
            where c.id = course_id and (
                (c.status = 'published' and (
                    is_preview = true or
                    exists (
                        select 1 from public.enrollments e
                        where e.course_id = c.id and e.student_id = auth.uid() and e.status = 'active'
                    )
                )) or
                c.instructor_id = auth.uid() or
                exists (
                    select 1 from public.profiles
                    where id = auth.uid() and role = 'admin'
                )
            )
        )
    );

create policy "Course instructors can manage their lessons" on public.lessons
    for all using (
        exists (
            select 1 from public.courses c
            where c.id = course_id and c.instructor_id = auth.uid()
        )
    );

create policy "Admins can manage all lessons" on public.lessons
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Enrollments policies
create policy "Students can view their own enrollments" on public.enrollments
    for select using (student_id = auth.uid());

create policy "Instructors can view enrollments for their courses" on public.enrollments
    for select using (
        exists (
            select 1 from public.courses c
            where c.id = course_id and c.instructor_id = auth.uid()
        )
    );

create policy "Students can create their own enrollments" on public.enrollments
    for insert with check (
        student_id = auth.uid() and
        exists (
            select 1 from public.courses c
            where c.id = course_id and c.status = 'published'
        )
    );

create policy "Students can update their own enrollments" on public.enrollments
    for update using (student_id = auth.uid());

create policy "Instructors can update enrollments for their courses" on public.enrollments
    for update using (
        exists (
            select 1 from public.courses c
            where c.id = course_id and c.instructor_id = auth.uid()
        )
    );

create policy "Admins can manage all enrollments" on public.enrollments
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Lesson progress policies
create policy "Students can view their own progress" on public.lesson_progress
    for select using (student_id = auth.uid());

create policy "Instructors can view progress for their courses" on public.lesson_progress
    for select using (
        exists (
            select 1 from public.lessons l
            join public.courses c on c.id = l.course_id
            where l.id = lesson_id and c.instructor_id = auth.uid()
        )
    );

create policy "Students can manage their own progress" on public.lesson_progress
    for all using (student_id = auth.uid());

create policy "Admins can manage all lesson progress" on public.lesson_progress
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Assignments policies
create policy "Students can view their own assignments" on public.assignments
    for select using (student_id = auth.uid());

create policy "Instructors can view assignments for their courses" on public.assignments
    for select using (
        exists (
            select 1 from public.lessons l
            join public.courses c on c.id = l.course_id
            where l.id = lesson_id and c.instructor_id = auth.uid()
        )
    );

create policy "Students can manage their own assignments" on public.assignments
    for all using (student_id = auth.uid());

create policy "Instructors can manage assignments for their courses" on public.assignments
    for all using (
        exists (
            select 1 from public.lessons l
            join public.courses c on c.id = l.course_id
            where l.id = lesson_id and c.instructor_id = auth.uid()
        )
    );

create policy "Admins can manage all assignments" on public.assignments
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Notifications policies
create policy "Users can view their own notifications" on public.notifications
    for select using (user_id = auth.uid());

create policy "Users can update their own notifications" on public.notifications
    for update using (user_id = auth.uid());

create policy "System can create notifications for any user" on public.notifications
    for insert with check (true);

create policy "Admins can manage all notifications" on public.notifications
    for all using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );