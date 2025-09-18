-- =============================================================================
-- ADDITIONAL FUNCTIONS AND REALTIME CONFIGURATION
-- =============================================================================

-- =============================================================================
-- NOTIFICATION FUNCTIONS
-- =============================================================================

-- Function to create notification
CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT DEFAULT 'info',
    p_action_url TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO public.notifications (user_id, title, message, type, action_url, metadata)
    VALUES (p_user_id, p_title, p_message, p_type, p_action_url, p_metadata)
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_read(notification_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = true, read_at = NOW()
    WHERE id = notification_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for user
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = true, read_at = NOW()
    WHERE user_id = auth.uid() AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- COURSE MANAGEMENT FUNCTIONS
-- =============================================================================

-- Function to enroll student in course
CREATE OR REPLACE FUNCTION public.enroll_in_course(course_id UUID)
RETURNS UUID AS $$
DECLARE
    enrollment_id UUID;
    course_title TEXT;
BEGIN
    -- Check if course exists and is published
    SELECT title INTO course_title
    FROM public.courses
    WHERE id = course_id AND status = 'published';
    
    IF course_title IS NULL THEN
        RAISE EXCEPTION 'Course not found or not published';
    END IF;
    
    -- Check if already enrolled
    IF EXISTS (
        SELECT 1 FROM public.enrollments
        WHERE student_id = auth.uid() AND course_id = enroll_in_course.course_id
    ) THEN
        RAISE EXCEPTION 'Already enrolled in this course';
    END IF;
    
    -- Create enrollment
    INSERT INTO public.enrollments (student_id, course_id, status)
    VALUES (auth.uid(), course_id, 'active')
    RETURNING id INTO enrollment_id;
    
    -- Create notification
    PERFORM public.create_notification(
        auth.uid(),
        'Course Enrollment Successful',
        'You have successfully enrolled in ' || course_title,
        'course_enrollment',
        '/courses/' || course_id
    );
    
    RETURN enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get course progress for a student
CREATE OR REPLACE FUNCTION public.get_course_progress(course_id UUID, student_id UUID DEFAULT auth.uid())
RETURNS JSONB AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
    progress_percentage DECIMAL(5,2);
    result JSONB;
BEGIN
    -- Count total required lessons
    SELECT COUNT(*) INTO total_lessons
    FROM public.lessons
    WHERE course_id = get_course_progress.course_id AND is_required = true;
    
    -- Count completed required lessons
    SELECT COUNT(*) INTO completed_lessons
    FROM public.lesson_progress lp
    JOIN public.lessons l ON l.id = lp.lesson_id
    WHERE lp.student_id = get_course_progress.student_id
    AND l.course_id = get_course_progress.course_id
    AND l.is_required = true
    AND lp.is_completed = true;
    
    -- Calculate progress
    IF total_lessons > 0 THEN
        progress_percentage = (completed_lessons::decimal / total_lessons::decimal) * 100;
    ELSE
        progress_percentage = 0;
    END IF;
    
    -- Build result
    result = jsonb_build_object(
        'course_id', course_id,
        'student_id', student_id,
        'total_lessons', total_lessons,
        'completed_lessons', completed_lessons,
        'progress_percentage', progress_percentage,
        'is_completed', progress_percentage >= 100
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete a lesson
CREATE OR REPLACE FUNCTION public.complete_lesson(lesson_id UUID)
RETURNS VOID AS $$
DECLARE
    enrollment_id UUID;
    lesson_title TEXT;
    course_id UUID;
BEGIN
    -- Get enrollment and lesson info
    SELECT e.id, l.title, l.course_id
    INTO enrollment_id, lesson_title, course_id
    FROM public.lessons l
    JOIN public.courses c ON c.id = l.course_id
    JOIN public.enrollments e ON e.course_id = c.id
    WHERE l.id = complete_lesson.lesson_id AND e.student_id = auth.uid();
    
    IF enrollment_id IS NULL THEN
        RAISE EXCEPTION 'Lesson not found or not enrolled in course';
    END IF;
    
    -- Update lesson progress
    INSERT INTO public.lesson_progress (student_id, lesson_id, enrollment_id, is_completed, completion_percentage, completed_at)
    VALUES (auth.uid(), lesson_id, enrollment_id, true, 100, NOW())
    ON CONFLICT (student_id, lesson_id)
    DO UPDATE SET
        is_completed = true,
        completion_percentage = 100,
        completed_at = NOW(),
        updated_at = NOW();
    
    -- Create notification
    PERFORM public.create_notification(
        auth.uid(),
        'Lesson Completed',
        'You have completed: ' || lesson_title,
        'lesson_completed',
        '/courses/' || course_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- ANALYTICS FUNCTIONS
-- =============================================================================

-- Function to get course enrollment stats
CREATE OR REPLACE FUNCTION public.get_course_stats(course_id UUID)
RETURNS JSONB AS $$
DECLARE
    stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'course_id', course_id,
        'total_enrollments', COUNT(*),
        'active_enrollments', COUNT(*) FILTER (WHERE status = 'active'),
        'completed_enrollments', COUNT(*) FILTER (WHERE status = 'completed'),
        'average_progress', COALESCE(AVG(progress_percentage), 0),
        'average_rating', COALESCE(AVG(rating), 0),
        'total_reviews', COUNT(*) FILTER (WHERE rating IS NOT NULL)
    )
    INTO stats
    FROM public.enrollments
    WHERE course_id = get_course_stats.course_id;
    
    RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user learning stats
CREATE OR REPLACE FUNCTION public.get_user_stats(user_id UUID DEFAULT auth.uid())
RETURNS JSONB AS $$
DECLARE
    stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'user_id', user_id,
        'total_enrollments', COUNT(*),
        'active_courses', COUNT(*) FILTER (WHERE status = 'active'),
        'completed_courses', COUNT(*) FILTER (WHERE status = 'completed'),
        'average_progress', COALESCE(AVG(progress_percentage), 0),
        'total_time_spent', COALESCE(SUM(
            SELECT SUM(time_spent_minutes)
            FROM public.lesson_progress lp
            WHERE lp.student_id = e.student_id
        ), 0)
    )
    INTO stats
    FROM public.enrollments e
    WHERE student_id = get_user_stats.user_id;
    
    RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- SEARCH FUNCTIONS
-- =============================================================================

-- Function to search courses
CREATE OR REPLACE FUNCTION public.search_courses(
    search_query TEXT DEFAULT '',
    category_filter TEXT DEFAULT NULL,
    level_filter TEXT DEFAULT NULL,
    instructor_filter TEXT DEFAULT NULL,
    sort_by TEXT DEFAULT 'title',
    sort_order TEXT DEFAULT 'ASC',
    page_limit INTEGER DEFAULT 20,
    page_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    slug TEXT,
    short_description TEXT,
    thumbnail_url TEXT,
    instructor_name TEXT,
    category_name TEXT,
    level TEXT,
    duration_minutes INTEGER,
    price DECIMAL(10,2),
    is_free BOOLEAN,
    is_featured BOOLEAN,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c.slug,
        c.short_description,
        c.thumbnail_url,
        p.full_name as instructor_name,
        cat.name as category_name,
        c.level,
        c.duration_minutes,
        c.price,
        c.is_free,
        c.is_featured,
        c.created_at
    FROM public.courses c
    LEFT JOIN public.profiles p ON p.id = c.instructor_id
    LEFT JOIN public.categories cat ON cat.id = c.category_id
    WHERE 
        c.status = 'published'
        AND (search_query = '' OR c.title ILIKE '%' || search_query || '%' OR c.short_description ILIKE '%' || search_query || '%')
        AND (category_filter IS NULL OR cat.slug = category_filter)
        AND (level_filter IS NULL OR c.level = level_filter)
        AND (instructor_filter IS NULL OR p.id::text = instructor_filter)
    ORDER BY
        CASE WHEN sort_by = 'title' AND sort_order = 'ASC' THEN c.title END ASC,
        CASE WHEN sort_by = 'title' AND sort_order = 'DESC' THEN c.title END DESC,
        CASE WHEN sort_by = 'created_at' AND sort_order = 'ASC' THEN c.created_at END ASC,
        CASE WHEN sort_by = 'created_at' AND sort_order = 'DESC' THEN c.created_at END DESC,
        CASE WHEN sort_by = 'price' AND sort_order = 'ASC' THEN c.price END ASC,
        CASE WHEN sort_by = 'price' AND sort_order = 'DESC' THEN c.price END DESC
    LIMIT page_limit
    OFFSET page_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC NOTIFICATIONS
-- =============================================================================

-- Trigger function to notify when course is completed
CREATE OR REPLACE FUNCTION public.notify_course_completion()
RETURNS trigger AS $$
DECLARE
    course_title TEXT;
BEGIN
    -- Only trigger when status changes to completed
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        SELECT title INTO course_title
        FROM public.courses
        WHERE id = NEW.course_id;
        
        PERFORM public.create_notification(
            NEW.student_id,
            'Course Completed!',
            'Congratulations! You have completed: ' || course_title,
            'course_completed',
            '/courses/' || NEW.course_id::text
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply the trigger
CREATE TRIGGER notify_course_completion_trigger
    AFTER UPDATE ON public.enrollments
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_course_completion();

-- Trigger function to notify instructor when assignment is submitted
CREATE OR REPLACE FUNCTION public.notify_assignment_submission()
RETURNS trigger AS $$
DECLARE
    instructor_id UUID;
    student_name TEXT;
    lesson_title TEXT;
BEGIN
    -- Only trigger when is_submitted changes to true
    IF NEW.is_submitted = true AND (OLD.is_submitted IS NULL OR OLD.is_submitted = false) THEN
        -- Get instructor and student info
        SELECT c.instructor_id, p.full_name, l.title
        INTO instructor_id, student_name, lesson_title
        FROM public.lessons l
        JOIN public.courses c ON c.id = l.course_id
        JOIN public.profiles p ON p.id = NEW.student_id
        WHERE l.id = NEW.lesson_id;
        
        PERFORM public.create_notification(
            instructor_id,
            'New Assignment Submission',
            student_name || ' has submitted an assignment for: ' || lesson_title,
            'assignment_submitted',
            '/assignments/' || NEW.id::text
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply the trigger
CREATE TRIGGER notify_assignment_submission_trigger
    AFTER UPDATE ON public.assignments
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_assignment_submission();

-- =============================================================================
-- REALTIME CONFIGURATION
-- =============================================================================

-- Enable realtime for key tables
ALTER publication supabase_realtime ADD TABLE public.notifications;
ALTER publication supabase_realtime ADD TABLE public.lesson_progress;
ALTER publication supabase_realtime ADD TABLE public.enrollments;
ALTER publication supabase_realtime ADD TABLE public.assignments;

-- =============================================================================
-- VIEWS FOR COMMON QUERIES
-- =============================================================================

-- View for dashboard course stats
CREATE OR REPLACE VIEW public.dashboard_course_stats AS
SELECT 
    c.id,
    c.title,
    c.slug,
    c.status,
    c.instructor_id,
    p.full_name as instructor_name,
    COUNT(DISTINCT e.id) as total_enrollments,
    COUNT(DISTINCT CASE WHEN e.status = 'active' THEN e.id END) as active_enrollments,
    COUNT(DISTINCT CASE WHEN e.status = 'completed' THEN e.id END) as completed_enrollments,
    COALESCE(AVG(e.progress_percentage), 0) as average_progress,
    COALESCE(AVG(e.rating), 0) as average_rating,
    COUNT(DISTINCT CASE WHEN e.rating IS NOT NULL THEN e.id END) as total_reviews,
    c.created_at,
    c.updated_at
FROM public.courses c
LEFT JOIN public.profiles p ON p.id = c.instructor_id
LEFT JOIN public.enrollments e ON e.course_id = c.id
GROUP BY c.id, c.title, c.slug, c.status, c.instructor_id, p.full_name, c.created_at, c.updated_at;

-- View for student dashboard
CREATE OR REPLACE VIEW public.student_dashboard AS
SELECT 
    e.id as enrollment_id,
    e.student_id,
    c.id as course_id,
    c.title,
    c.slug,
    c.thumbnail_url,
    p.full_name as instructor_name,
    cat.name as category_name,
    e.status,
    e.progress_percentage,
    e.started_at,
    e.completed_at,
    COUNT(l.id) as total_lessons,
    COUNT(lp.id) as lessons_accessed,
    COUNT(CASE WHEN lp.is_completed THEN 1 END) as lessons_completed
FROM public.enrollments e
JOIN public.courses c ON c.id = e.course_id
LEFT JOIN public.profiles p ON p.id = c.instructor_id
LEFT JOIN public.categories cat ON cat.id = c.category_id
LEFT JOIN public.lessons l ON l.course_id = c.id AND l.is_required = true
LEFT JOIN public.lesson_progress lp ON lp.lesson_id = l.id AND lp.student_id = e.student_id
WHERE e.student_id = auth.uid()
GROUP BY e.id, e.student_id, c.id, c.title, c.slug, c.thumbnail_url, p.full_name, cat.name, e.status, e.progress_percentage, e.started_at, e.completed_at;

-- View for instructor dashboard
CREATE OR REPLACE VIEW public.instructor_dashboard AS
SELECT 
    c.id as course_id,
    c.title,
    c.slug,
    c.status,
    c.created_at,
    COUNT(DISTINCT e.id) as total_students,
    COUNT(DISTINCT CASE WHEN e.status = 'active' THEN e.id END) as active_students,
    COUNT(DISTINCT CASE WHEN e.status = 'completed' THEN e.id END) as completed_students,
    COUNT(DISTINCT l.id) as total_lessons,
    COUNT(DISTINCT a.id) as pending_assignments,
    COALESCE(AVG(e.progress_percentage), 0) as average_progress
FROM public.courses c
LEFT JOIN public.enrollments e ON e.course_id = c.id
LEFT JOIN public.lessons l ON l.course_id = c.id
LEFT JOIN public.assignments a ON a.lesson_id = l.id AND a.is_submitted = true AND a.is_graded = false
WHERE c.instructor_id = auth.uid()
GROUP BY c.id, c.title, c.slug, c.status, c.created_at;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION public.create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.enroll_in_course TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_course_progress TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_lesson TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_course_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_courses TO authenticated;

-- Grant select permissions on views
GRANT SELECT ON public.dashboard_course_stats TO authenticated;
GRANT SELECT ON public.student_dashboard TO authenticated;
GRANT SELECT ON public.instructor_dashboard TO authenticated;