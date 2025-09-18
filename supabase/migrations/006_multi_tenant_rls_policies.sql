-- =============================================================================
-- MULTI-TENANT RLS POLICIES
-- =============================================================================
-- This migration updates all RLS policies for complete tenant isolation

-- =============================================================================
-- DROP EXISTING POLICIES (TO RECREATE WITH TENANT ISOLATION)
-- =============================================================================

-- Drop existing policies on profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;

-- Drop existing policies on categories
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Teachers and admins can manage categories" ON public.categories;

-- Drop existing policies on courses
DROP POLICY IF EXISTS "Published courses are viewable by everyone" ON public.courses;
DROP POLICY IF EXISTS "Instructors can manage their own courses" ON public.courses;
DROP POLICY IF EXISTS "Teachers can create courses" ON public.courses;
DROP POLICY IF EXISTS "Admins can manage all courses" ON public.courses;

-- Drop existing policies on course_modules
DROP POLICY IF EXISTS "Course modules are viewable by enrolled students and course owners" ON public.course_modules;
DROP POLICY IF EXISTS "Course instructors can manage their course modules" ON public.course_modules;
DROP POLICY IF EXISTS "Admins can manage all course modules" ON public.course_modules;

-- Drop existing policies on lessons
DROP POLICY IF EXISTS "Lessons are viewable by enrolled students and course owners" ON public.lessons;
DROP POLICY IF EXISTS "Course instructors can manage their lessons" ON public.lessons;
DROP POLICY IF EXISTS "Admins can manage all lessons" ON public.lessons;

-- Drop existing policies on enrollments
DROP POLICY IF EXISTS "Students can view their own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Instructors can view enrollments for their courses" ON public.enrollments;
DROP POLICY IF EXISTS "Students can create their own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Students can update their own enrollments" ON public.enrollments;
DROP POLICY IF EXISTS "Instructors can update enrollments for their courses" ON public.enrollments;
DROP POLICY IF EXISTS "Admins can manage all enrollments" ON public.enrollments;

-- Drop existing policies on lesson_progress
DROP POLICY IF EXISTS "Students can view their own progress" ON public.lesson_progress;
DROP POLICY IF EXISTS "Instructors can view progress for their courses" ON public.lesson_progress;
DROP POLICY IF EXISTS "Students can manage their own progress" ON public.lesson_progress;
DROP POLICY IF EXISTS "Admins can manage all lesson progress" ON public.lesson_progress;

-- Drop existing policies on assignments
DROP POLICY IF EXISTS "Students can view their own assignments" ON public.assignments;
DROP POLICY IF EXISTS "Instructors can view assignments for their courses" ON public.assignments;
DROP POLICY IF EXISTS "Students can manage their own assignments" ON public.assignments;
DROP POLICY IF EXISTS "Instructors can manage assignments for their courses" ON public.assignments;
DROP POLICY IF EXISTS "Admins can manage all assignments" ON public.assignments;

-- Drop existing policies on notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can create notifications for any user" ON public.notifications;
DROP POLICY IF EXISTS "Admins can manage all notifications" ON public.notifications;

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - ORGANIZATIONS
-- =============================================================================

-- Users can view organizations they belong to
CREATE POLICY "Users can view their organizations" ON public.organizations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = id 
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Organization owners/admins can update their organization
CREATE POLICY "Organization owners can update organization" ON public.organizations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = id 
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- Anyone can create organizations (for signup)
CREATE POLICY "Anyone can create organizations" ON public.organizations
    FOR INSERT WITH CHECK (true);

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - ORGANIZATION USERS
-- =============================================================================

-- Users can view organization memberships for organizations they belong to
CREATE POLICY "Users can view org memberships in their organizations" ON public.organization_users
    FOR SELECT USING (
        -- User can see their own memberships
        user_id = auth.uid()
        OR
        -- User can see memberships in organizations they belong to (if they're admin/owner)
        EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = organization_users.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- Organization owners/admins can manage memberships
CREATE POLICY "Organization admins can manage memberships" ON public.organization_users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = organization_users.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- Users can accept invitations (insert their own membership)
CREATE POLICY "Users can accept organization invitations" ON public.organization_users
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - ORGANIZATION INVITATIONS
-- =============================================================================

-- Organization owners/admins can manage invitations
CREATE POLICY "Organization admins can manage invitations" ON public.organization_invitations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = organization_invitations.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- Users can view invitations sent to them
CREATE POLICY "Users can view their invitations" ON public.organization_invitations
    FOR SELECT USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - ORGANIZATION SETTINGS
-- =============================================================================

-- Organization owners/admins can view and update settings
CREATE POLICY "Organization admins can manage settings" ON public.organization_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = organization_settings.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - PROFILES
-- =============================================================================

-- Users can view profiles in their current organization
CREATE POLICY "Users can view profiles in their organization" ON public.profiles
    FOR SELECT USING (
        -- Users can view their own profile
        id = auth.uid()
        OR
        -- Users can view profiles of users in the same organization
        EXISTS (
            SELECT 1 FROM public.organization_users ou1
            JOIN public.organization_users ou2 ON ou1.organization_id = ou2.organization_id
            WHERE ou1.user_id = auth.uid()
            AND ou2.user_id = profiles.id
            AND ou1.status = 'active'
            AND ou2.status = 'active'
            AND ou1.organization_id = public.get_current_organization_id()
        )
    );

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid());

-- Organization admins can update profiles in their organization
CREATE POLICY "Organization admins can update member profiles" ON public.profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.organization_users ou1
            JOIN public.organization_users ou2 ON ou1.organization_id = ou2.organization_id
            WHERE ou1.user_id = auth.uid()
            AND ou2.user_id = profiles.id
            AND ou1.role IN ('owner', 'admin')
            AND ou1.status = 'active'
            AND ou2.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - CATEGORIES
-- =============================================================================

-- Users can view categories in their organization
CREATE POLICY "Users can view organization categories" ON public.categories
    FOR SELECT USING (
        organization_id = public.get_current_organization_id()
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = categories.organization_id
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Organization admins/instructors can manage categories
CREATE POLICY "Organization staff can manage categories" ON public.categories
    FOR ALL USING (
        organization_id = public.get_current_organization_id()
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = categories.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin', 'instructor')
            AND ou.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - COURSES
-- =============================================================================

-- Users can view courses in their organization
CREATE POLICY "Users can view organization courses" ON public.courses
    FOR SELECT USING (
        organization_id = public.get_current_organization_id()
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = courses.organization_id
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
        AND (
            -- Course is published, or user is instructor/admin, or user is enrolled
            status = 'published'
            OR instructor_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.organization_users ou
                WHERE ou.organization_id = courses.organization_id
                AND ou.user_id = auth.uid()
                AND ou.role IN ('owner', 'admin')
                AND ou.status = 'active'
            )
            OR EXISTS (
                SELECT 1 FROM public.enrollments e
                WHERE e.course_id = courses.id
                AND e.student_id = auth.uid()
            )
        )
    );

-- Instructors can create courses in their organization
CREATE POLICY "Instructors can create courses" ON public.courses
    FOR INSERT WITH CHECK (
        organization_id = public.get_current_organization_id()
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = courses.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin', 'instructor')
            AND ou.status = 'active'
        )
        AND instructor_id = auth.uid()
    );

-- Course instructors and organization admins can update courses
CREATE POLICY "Course owners can update courses" ON public.courses
    FOR UPDATE USING (
        organization_id = public.get_current_organization_id()
        AND (
            instructor_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.organization_users ou
                WHERE ou.organization_id = courses.organization_id
                AND ou.user_id = auth.uid()
                AND ou.role IN ('owner', 'admin')
                AND ou.status = 'active'
            )
        )
    );

-- Course instructors and organization admins can delete courses
CREATE POLICY "Course owners can delete courses" ON public.courses
    FOR DELETE USING (
        organization_id = public.get_current_organization_id()
        AND (
            instructor_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.organization_users ou
                WHERE ou.organization_id = courses.organization_id
                AND ou.user_id = auth.uid()
                AND ou.role IN ('owner', 'admin')
                AND ou.status = 'active'
            )
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - COURSE MODULES
-- =============================================================================

-- Users can view modules for courses they can access
CREATE POLICY "Users can view course modules they can access" ON public.course_modules
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = course_modules.course_id
            -- Apply the same logic as course access
            AND c.organization_id = public.get_current_organization_id()
            AND EXISTS (
                SELECT 1 FROM public.organization_users ou
                WHERE ou.organization_id = c.organization_id
                AND ou.user_id = auth.uid()
                AND ou.status = 'active'
            )
            AND (
                c.status = 'published'
                OR c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
                OR EXISTS (
                    SELECT 1 FROM public.enrollments e
                    WHERE e.course_id = c.id
                    AND e.student_id = auth.uid()
                )
            )
        )
    );

-- Course instructors and admins can manage modules
CREATE POLICY "Course instructors can manage modules" ON public.course_modules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = course_modules.course_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - LESSONS
-- =============================================================================

-- Users can view lessons they have access to
CREATE POLICY "Users can view accessible lessons" ON public.lessons
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = lessons.course_id
            AND c.organization_id = public.get_current_organization_id()
            AND EXISTS (
                SELECT 1 FROM public.organization_users ou
                WHERE ou.organization_id = c.organization_id
                AND ou.user_id = auth.uid()
                AND ou.status = 'active'
            )
            AND (
                -- Lesson is preview, or user has course access
                is_preview = true
                OR c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
                OR EXISTS (
                    SELECT 1 FROM public.enrollments e
                    WHERE e.course_id = c.id
                    AND e.student_id = auth.uid()
                    AND e.status = 'active'
                )
            )
        )
    );

-- Course instructors and admins can manage lessons
CREATE POLICY "Course instructors can manage lessons" ON public.lessons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = lessons.course_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - ENROLLMENTS
-- =============================================================================

-- Users can view enrollments in their organization
CREATE POLICY "Users can view relevant enrollments" ON public.enrollments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = enrollments.course_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                -- Student can see their own enrollments
                enrollments.student_id = auth.uid()
                OR
                -- Instructor can see enrollments in their courses
                c.instructor_id = auth.uid()
                OR
                -- Organization admins can see all enrollments
                EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- Students can create enrollments in their organization
CREATE POLICY "Students can enroll in organization courses" ON public.enrollments
    FOR INSERT WITH CHECK (
        student_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = enrollments.course_id
            AND c.organization_id = public.get_current_organization_id()
            AND c.status = 'published'
            AND EXISTS (
                SELECT 1 FROM public.organization_users ou
                WHERE ou.organization_id = c.organization_id
                AND ou.user_id = auth.uid()
                AND ou.status = 'active'
            )
        )
    );

-- Students and instructors can update enrollments
CREATE POLICY "Relevant users can update enrollments" ON public.enrollments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id = enrollments.course_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                enrollments.student_id = auth.uid()
                OR c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - LESSON PROGRESS
-- =============================================================================

-- Users can view relevant lesson progress
CREATE POLICY "Users can view relevant lesson progress" ON public.lesson_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.lessons l
            JOIN public.courses c ON c.id = l.course_id
            WHERE l.id = lesson_progress.lesson_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                lesson_progress.student_id = auth.uid()
                OR c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- Students can manage their own progress
CREATE POLICY "Students can manage their lesson progress" ON public.lesson_progress
    FOR ALL USING (
        student_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.lessons l
            JOIN public.courses c ON c.id = l.course_id
            WHERE l.id = lesson_progress.lesson_id
            AND c.organization_id = public.get_current_organization_id()
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - ASSIGNMENTS
-- =============================================================================

-- Users can view relevant assignments
CREATE POLICY "Users can view relevant assignments" ON public.assignments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.lessons l
            JOIN public.courses c ON c.id = l.course_id
            WHERE l.id = assignments.lesson_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                assignments.student_id = auth.uid()
                OR c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- Students and instructors can manage assignments
CREATE POLICY "Students and instructors can manage assignments" ON public.assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.lessons l
            JOIN public.courses c ON c.id = l.course_id
            WHERE l.id = assignments.lesson_id
            AND c.organization_id = public.get_current_organization_id()
            AND (
                assignments.student_id = auth.uid()
                OR c.instructor_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.organization_users ou
                    WHERE ou.organization_id = c.organization_id
                    AND ou.user_id = auth.uid()
                    AND ou.role IN ('owner', 'admin')
                    AND ou.status = 'active'
                )
            )
        )
    );

-- =============================================================================
-- MULTI-TENANT RLS POLICIES - NOTIFICATIONS
-- =============================================================================

-- Users can view their notifications in their organization
CREATE POLICY "Users can view their organization notifications" ON public.notifications
    FOR SELECT USING (
        user_id = auth.uid()
        AND (
            organization_id IS NULL  -- Global notifications
            OR organization_id = public.get_current_organization_id()
        )
    );

-- Users can update their own notifications
CREATE POLICY "Users can update their own notifications" ON public.notifications
    FOR UPDATE USING (
        user_id = auth.uid()
        AND (
            organization_id IS NULL
            OR organization_id = public.get_current_organization_id()
        )
    );

-- System can create notifications (handled by functions)
CREATE POLICY "System can create organization notifications" ON public.notifications
    FOR INSERT WITH CHECK (
        organization_id IS NULL
        OR organization_id = public.get_current_organization_id()
    );

-- Organization admins can manage all notifications in their org
CREATE POLICY "Organization admins can manage notifications" ON public.notifications
    FOR ALL USING (
        organization_id = public.get_current_organization_id()
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id = notifications.organization_id
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );