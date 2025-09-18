-- =============================================================================
-- SUPABASE STORAGE CONFIGURATION
-- =============================================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    (
        'profiles', 
        'profiles', 
        true, 
        5242880, -- 5MB limit
        '{"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}'
    ),
    (
        'courses', 
        'courses', 
        true, 
        10485760, -- 10MB limit
        '{"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif", "video/mp4", "video/mpeg", "video/quicktime", "application/pdf"}'
    ),
    (
        'assignments', 
        'assignments', 
        false, 
        20971520, -- 20MB limit
        '{"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif", "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "text/plain", "application/zip", "application/x-zip-compressed"}'
    ),
    (
        'certificates', 
        'certificates', 
        true, 
        2097152, -- 2MB limit
        '{"application/pdf", "image/jpeg", "image/jpg", "image/png"}'
    );

-- =============================================================================
-- PROFILES BUCKET POLICIES
-- =============================================================================

-- Allow users to upload their own avatar
CREATE POLICY "Users can upload their own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'avatars'
    );

-- Allow users to update their own avatar
CREATE POLICY "Users can update their own avatar"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'avatars'
    );

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete their own avatar"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'profiles' 
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'avatars'
    );

-- Allow public access to view avatars
CREATE POLICY "Public can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'profiles');

-- =============================================================================
-- COURSES BUCKET POLICIES
-- =============================================================================

-- Allow instructors to upload course materials for their courses
CREATE POLICY "Instructors can upload course materials"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'courses' 
        AND EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
        )
    );

-- Allow instructors to update their course materials
CREATE POLICY "Instructors can update their course materials"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'courses' 
        AND EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
        )
    );

-- Allow instructors to delete their course materials
CREATE POLICY "Instructors can delete their course materials"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'courses' 
        AND EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
        )
    );

-- Allow public access to view published course materials
CREATE POLICY "Public can view course materials"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1 FROM public.courses c
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.status = 'published'
        )
    );

-- Allow enrolled students to view course materials
CREATE POLICY "Enrolled students can view course materials"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1 FROM public.courses c
            JOIN public.enrollments e ON e.course_id = c.id
            WHERE c.id::text = (storage.foldername(name))[1]
            AND e.student_id = auth.uid()
            AND e.status = 'active'
        )
    );

-- Allow admins to manage all course materials
CREATE POLICY "Admins can manage all course materials"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =============================================================================
-- ASSIGNMENTS BUCKET POLICIES
-- =============================================================================

-- Allow students to upload their assignment submissions
CREATE POLICY "Students can upload assignment submissions"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'assignments' 
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'submissions'
    );

-- Allow students to update their assignment submissions
CREATE POLICY "Students can update their assignment submissions"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'assignments' 
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'submissions'
    );

-- Allow students to delete their assignment submissions
CREATE POLICY "Students can delete their assignment submissions"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'assignments' 
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'submissions'
    );

-- Allow instructors to view assignment submissions for their courses
CREATE POLICY "Instructors can view assignment submissions"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'assignments'
        AND (storage.foldername(name))[2] = 'submissions'
        AND EXISTS (
            SELECT 1 FROM public.assignments a
            JOIN public.lessons l ON l.id = a.lesson_id
            JOIN public.courses c ON c.id = l.course_id
            WHERE a.student_id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
        )
    );

-- Allow students to view their own assignment submissions
CREATE POLICY "Students can view their own assignment submissions"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'assignments'
        AND auth.uid()::text = (storage.foldername(name))[1]
        AND (storage.foldername(name))[2] = 'submissions'
    );

-- Allow admins to manage all assignment files
CREATE POLICY "Admins can manage all assignment files"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'assignments'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =============================================================================
-- CERTIFICATES BUCKET POLICIES
-- =============================================================================

-- Allow system to create certificates (handled by functions)
CREATE POLICY "System can create certificates"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'certificates');

-- Allow users to view their own certificates
CREATE POLICY "Users can view their own certificates"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'certificates'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow public access to certificates (for verification)
CREATE POLICY "Public can view certificates"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'certificates');

-- Allow admins to manage all certificates
CREATE POLICY "Admins can manage all certificates"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'certificates'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =============================================================================
-- HELPER FUNCTIONS FOR STORAGE
-- =============================================================================

-- Function to get file extension
CREATE OR REPLACE FUNCTION public.get_file_extension(filename text)
RETURNS text AS $$
BEGIN
    RETURN lower(substring(filename from '\.([^.]*)$'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to generate unique filename
CREATE OR REPLACE FUNCTION public.generate_unique_filename(original_filename text, user_id uuid DEFAULT auth.uid())
RETURNS text AS $$
DECLARE
    file_ext text;
    unique_name text;
BEGIN
    file_ext := public.get_file_extension(original_filename);
    unique_name := user_id::text || '-' || extract(epoch from now())::bigint || '.' || file_ext;
    RETURN unique_name;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old avatar when new one is uploaded
CREATE OR REPLACE FUNCTION public.cleanup_old_avatar()
RETURNS trigger AS $$
BEGIN
    -- Delete old avatar file if it exists and is different from new one
    IF OLD.avatar_url IS NOT NULL AND OLD.avatar_url != NEW.avatar_url THEN
        -- This would require a custom function or edge function to actually delete the file
        -- For now, we'll just log it
        RAISE NOTICE 'Old avatar should be deleted: %', OLD.avatar_url;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to cleanup old avatars
CREATE TRIGGER cleanup_avatar_trigger
    AFTER UPDATE OF avatar_url ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.cleanup_old_avatar();