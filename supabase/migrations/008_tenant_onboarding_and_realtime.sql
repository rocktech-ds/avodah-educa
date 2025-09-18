-- =============================================================================
-- TENANT ONBOARDING AND REAL-TIME CONFIGURATION
-- =============================================================================

-- =============================================================================
-- TENANT ONBOARDING FUNCTIONS
-- =============================================================================

-- Function for organization signup (public signup process)
CREATE OR REPLACE FUNCTION public.signup_organization(
    p_organization_name TEXT,
    p_organization_slug TEXT,
    p_owner_full_name TEXT,
    p_owner_email TEXT,
    p_owner_password TEXT,
    p_plan organization_plan DEFAULT 'starter'
)
RETURNS JSONB AS $$
DECLARE
    new_org_id UUID;
    new_user_id UUID;
    result JSONB;
BEGIN
    -- Validate organization slug is unique
    IF EXISTS (SELECT 1 FROM public.organizations WHERE slug = p_organization_slug) THEN
        RAISE EXCEPTION 'Organization slug already exists: %', p_organization_slug;
    END IF;
    
    -- Create the organization
    INSERT INTO public.organizations (
        name,
        slug,
        contact_email,
        plan,
        status,
        trial_ends_at,
        max_users,
        max_courses,
        max_storage_gb
    )
    VALUES (
        p_organization_name,
        p_organization_slug,
        p_owner_email,
        p_plan,
        'trial',
        NOW() + INTERVAL '14 days',
        CASE p_plan 
            WHEN 'starter' THEN 25
            WHEN 'professional' THEN 100
            WHEN 'enterprise' THEN 500
            ELSE 1000
        END,
        CASE p_plan 
            WHEN 'starter' THEN 10
            WHEN 'professional' THEN 50
            WHEN 'enterprise' THEN 200
            ELSE 1000
        END,
        CASE p_plan 
            WHEN 'starter' THEN 5
            WHEN 'professional' THEN 25
            WHEN 'enterprise' THEN 100
            ELSE 500
        END
    )
    RETURNING id INTO new_org_id;
    
    -- Create default organization settings
    INSERT INTO public.organization_settings (organization_id)
    VALUES (new_org_id);
    
    -- Return result for frontend to create user
    result := jsonb_build_object(
        'organization_id', new_org_id,
        'organization_slug', p_organization_slug,
        'owner_email', p_owner_email,
        'owner_name', p_owner_full_name,
        'plan', p_plan,
        'trial_ends_at', (NOW() + INTERVAL '14 days')::text
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete organization setup after user creation
CREATE OR REPLACE FUNCTION public.complete_organization_setup(
    p_organization_id UUID,
    p_setup_data JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
DECLARE
    current_user_email TEXT;
    org_contact_email TEXT;
BEGIN
    -- Get current user email
    SELECT email INTO current_user_email FROM auth.users WHERE id = auth.uid();
    
    -- Get organization contact email
    SELECT contact_email INTO org_contact_email 
    FROM public.organizations 
    WHERE id = p_organization_id;
    
    -- Verify user is the intended owner
    IF current_user_email != org_contact_email THEN
        RAISE EXCEPTION 'User email does not match organization contact email';
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM public.organization_users
        WHERE organization_id = p_organization_id AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'User is already a member of this organization';
    END IF;
    
    -- Add user as organization owner
    INSERT INTO public.organization_users (
        organization_id,
        user_id,
        role,
        status
    )
    VALUES (
        p_organization_id,
        auth.uid(),
        'owner',
        'active'
    );
    
    -- Set as user's current organization
    UPDATE public.profiles
    SET current_organization_id = p_organization_id
    WHERE id = auth.uid();
    
    -- Create default categories for the organization
    INSERT INTO public.categories (organization_id, name, slug, description, color, sort_order)
    VALUES 
        (p_organization_id, 'Tecnologia', 'tecnologia', 'Cursos de programação e tecnologia', '#3B82F6', 1),
        (p_organization_id, 'Design', 'design', 'Cursos de design e criatividade', '#8B5CF6', 2),
        (p_organization_id, 'Negócios', 'negocios', 'Cursos de empreendedorismo e gestão', '#10B981', 3),
        (p_organization_id, 'Idiomas', 'idiomas', 'Cursos de idiomas', '#EF4444', 4);
    
    -- Create welcome notification
    PERFORM public.create_notification(
        auth.uid(),
        'Bem-vindo ao Avodah Educa!',
        'Sua organização foi configurada com sucesso. Comece criando seus primeiros cursos.',
        'welcome',
        '/dashboard',
        jsonb_build_object('organization_id', p_organization_id)
    );
    
    -- Update organization setup completion
    UPDATE public.organizations
    SET metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
        'setup_completed', true,
        'setup_completed_at', NOW()
    )
    WHERE id = p_organization_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check organization limits
CREATE OR REPLACE FUNCTION public.check_organization_limits(
    limit_type TEXT,
    org_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    target_org_id UUID;
    org_limits RECORD;
    current_usage RECORD;
    result JSONB;
BEGIN
    target_org_id := COALESCE(org_id, public.get_current_organization_id());
    
    IF target_org_id IS NULL THEN
        RAISE EXCEPTION 'Organization context required';
    END IF;
    
    -- Get organization limits
    SELECT max_users, max_courses, max_storage_gb
    INTO org_limits
    FROM public.organizations
    WHERE id = target_org_id;
    
    -- Get current usage
    SELECT
        COUNT(DISTINCT ou.user_id) as users_count,
        COUNT(DISTINCT c.id) as courses_count,
        COALESCE(SUM(CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END), 0) as storage_usage_gb
    INTO current_usage
    FROM public.organization_users ou
    LEFT JOIN public.courses c ON c.organization_id = ou.organization_id
    WHERE ou.organization_id = target_org_id
    AND ou.status = 'active';
    
    -- Build result based on requested limit type
    IF limit_type = 'users' THEN
        result := jsonb_build_object(
            'limit', org_limits.max_users,
            'current', current_usage.users_count,
            'remaining', org_limits.max_users - current_usage.users_count,
            'percentage', (current_usage.users_count * 100.0 / org_limits.max_users),
            'exceeded', current_usage.users_count >= org_limits.max_users
        );
    ELSIF limit_type = 'courses' THEN
        result := jsonb_build_object(
            'limit', org_limits.max_courses,
            'current', current_usage.courses_count,
            'remaining', org_limits.max_courses - current_usage.courses_count,
            'percentage', (current_usage.courses_count * 100.0 / org_limits.max_courses),
            'exceeded', current_usage.courses_count >= org_limits.max_courses
        );
    ELSIF limit_type = 'storage' THEN
        result := jsonb_build_object(
            'limit', org_limits.max_storage_gb,
            'current', current_usage.storage_usage_gb,
            'remaining', org_limits.max_storage_gb - current_usage.storage_usage_gb,
            'percentage', (current_usage.storage_usage_gb * 100.0 / org_limits.max_storage_gb),
            'exceeded', current_usage.storage_usage_gb >= org_limits.max_storage_gb
        );
    ELSE
        result := jsonb_build_object(
            'users', jsonb_build_object(
                'limit', org_limits.max_users,
                'current', current_usage.users_count,
                'remaining', org_limits.max_users - current_usage.users_count,
                'percentage', (current_usage.users_count * 100.0 / org_limits.max_users),
                'exceeded', current_usage.users_count >= org_limits.max_users
            ),
            'courses', jsonb_build_object(
                'limit', org_limits.max_courses,
                'current', current_usage.courses_count,
                'remaining', org_limits.max_courses - current_usage.courses_count,
                'percentage', (current_usage.courses_count * 100.0 / org_limits.max_courses),
                'exceeded', current_usage.courses_count >= org_limits.max_courses
            ),
            'storage', jsonb_build_object(
                'limit', org_limits.max_storage_gb,
                'current', current_usage.storage_usage_gb,
                'remaining', org_limits.max_storage_gb - current_usage.storage_usage_gb,
                'percentage', (current_usage.storage_usage_gb * 100.0 / org_limits.max_storage_gb),
                'exceeded', current_usage.storage_usage_gb >= org_limits.max_storage_gb
            )
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- TENANT-AWARE REAL-TIME CONFIGURATION
-- =============================================================================

-- Enable real-time for multi-tenant tables
ALTER publication supabase_realtime ADD TABLE public.organizations;
ALTER publication supabase_realtime ADD TABLE public.organization_users;
ALTER publication supabase_realtime ADD TABLE public.organization_invitations;

-- =============================================================================
-- MULTI-TENANT DASHBOARD VIEWS
-- =============================================================================

-- Enhanced organization dashboard with limits and usage
CREATE OR REPLACE VIEW public.organization_dashboard AS
SELECT 
    o.id,
    o.name,
    o.slug,
    o.plan,
    o.status,
    o.trial_ends_at,
    o.subscription_ends_at,
    o.max_users,
    o.max_courses,
    o.max_storage_gb,
    o.features,
    
    -- User statistics
    COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.status = 'active') as active_users,
    COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'owner') as owners,
    COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'admin') as admins,
    COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'instructor') as instructors,
    COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'student') as students,
    
    -- Course statistics
    COUNT(DISTINCT c.id) as total_courses,
    COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'published') as published_courses,
    COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'draft') as draft_courses,
    
    -- Enrollment statistics
    COUNT(DISTINCT e.id) as total_enrollments,
    COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'active') as active_enrollments,
    COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'completed') as completed_enrollments,
    
    -- Usage percentages
    CASE WHEN o.max_users > 0 THEN 
        ROUND((COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.status = 'active') * 100.0) / o.max_users, 2)
    ELSE 0 END as users_usage_percentage,
    
    CASE WHEN o.max_courses > 0 THEN 
        ROUND((COUNT(DISTINCT c.id) * 100.0) / o.max_courses, 2)
    ELSE 0 END as courses_usage_percentage,
    
    -- Check if limits are exceeded
    (COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.status = 'active')) >= o.max_users as users_limit_exceeded,
    (COUNT(DISTINCT c.id)) >= o.max_courses as courses_limit_exceeded,
    
    -- Trial status
    CASE 
        WHEN o.status = 'trial' AND o.trial_ends_at < NOW() THEN 'expired'
        WHEN o.status = 'trial' AND o.trial_ends_at > NOW() THEN 'active'
        ELSE o.status::text
    END as trial_status,
    
    -- Days until trial ends
    CASE 
        WHEN o.status = 'trial' AND o.trial_ends_at > NOW() THEN 
            EXTRACT(days FROM (o.trial_ends_at - NOW()))
        ELSE NULL
    END as trial_days_remaining,
    
    o.created_at,
    o.updated_at
    
FROM public.organizations o
LEFT JOIN public.organization_users ou ON ou.organization_id = o.id
LEFT JOIN public.courses c ON c.organization_id = o.id
LEFT JOIN public.enrollments e ON e.course_id = c.id
WHERE o.id = public.get_current_organization_id()
GROUP BY o.id, o.name, o.slug, o.plan, o.status, o.trial_ends_at, o.subscription_ends_at, 
         o.max_users, o.max_courses, o.max_storage_gb, o.features, o.created_at, o.updated_at;

-- Multi-tenant student dashboard (organization-scoped)
CREATE OR REPLACE VIEW public.organization_student_dashboard AS
SELECT 
    e.id as enrollment_id,
    e.student_id,
    c.id as course_id,
    c.title,
    c.slug,
    c.thumbnail_url,
    c.organization_id,
    p.full_name as instructor_name,
    cat.name as category_name,
    e.status,
    e.progress_percentage,
    e.started_at,
    e.completed_at,
    COUNT(l.id) as total_lessons,
    COUNT(lp.id) as lessons_accessed,
    COUNT(CASE WHEN lp.is_completed THEN 1 END) as lessons_completed,
    o.name as organization_name
FROM public.enrollments e
JOIN public.courses c ON c.id = e.course_id
JOIN public.organizations o ON o.id = c.organization_id
LEFT JOIN public.profiles p ON p.id = c.instructor_id
LEFT JOIN public.categories cat ON cat.id = c.category_id
LEFT JOIN public.lessons l ON l.course_id = c.id AND l.is_required = true
LEFT JOIN public.lesson_progress lp ON lp.lesson_id = l.id AND lp.student_id = e.student_id
WHERE e.student_id = auth.uid()
AND c.organization_id = public.get_current_organization_id()
GROUP BY e.id, e.student_id, c.id, c.title, c.slug, c.thumbnail_url, c.organization_id,
         p.full_name, cat.name, e.status, e.progress_percentage, e.started_at, e.completed_at, o.name;

-- Multi-tenant instructor dashboard (organization-scoped)
CREATE OR REPLACE VIEW public.organization_instructor_dashboard AS
SELECT 
    c.id as course_id,
    c.title,
    c.slug,
    c.status,
    c.organization_id,
    c.created_at,
    COUNT(DISTINCT e.id) as total_students,
    COUNT(DISTINCT CASE WHEN e.status = 'active' THEN e.id END) as active_students,
    COUNT(DISTINCT CASE WHEN e.status = 'completed' THEN e.id END) as completed_students,
    COUNT(DISTINCT l.id) as total_lessons,
    COUNT(DISTINCT a.id) FILTER (WHERE a.is_submitted = true AND a.is_graded = false) as pending_assignments,
    COALESCE(AVG(e.progress_percentage), 0) as average_progress,
    o.name as organization_name
FROM public.courses c
JOIN public.organizations o ON o.id = c.organization_id
LEFT JOIN public.enrollments e ON e.course_id = c.id
LEFT JOIN public.lessons l ON l.course_id = c.id
LEFT JOIN public.assignments a ON a.lesson_id = l.id
WHERE c.instructor_id = auth.uid()
AND c.organization_id = public.get_current_organization_id()
GROUP BY c.id, c.title, c.slug, c.status, c.organization_id, c.created_at, o.name;

-- =============================================================================
-- TRIGGER TO ENFORCE ORGANIZATION LIMITS
-- =============================================================================

-- Function to check limits before creating resources
CREATE OR REPLACE FUNCTION public.enforce_organization_limits()
RETURNS TRIGGER AS $$
DECLARE
    current_org_id UUID;
    limits_check JSONB;
BEGIN
    -- Get organization context
    current_org_id := public.get_current_organization_id();
    
    IF current_org_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check limits based on table being inserted into
    IF TG_TABLE_NAME = 'organization_users' THEN
        limits_check := public.check_organization_limits('users', current_org_id);
        IF (limits_check->>'exceeded')::boolean THEN
            RAISE EXCEPTION 'User limit exceeded for this organization. Current: %, Limit: %', 
                limits_check->>'current', limits_check->>'limit';
        END IF;
    ELSIF TG_TABLE_NAME = 'courses' THEN
        limits_check := public.check_organization_limits('courses', current_org_id);
        IF (limits_check->>'exceeded')::boolean THEN
            RAISE EXCEPTION 'Course limit exceeded for this organization. Current: %, Limit: %', 
                limits_check->>'current', limits_check->>'limit';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply limit enforcement triggers
CREATE TRIGGER enforce_user_limits
    BEFORE INSERT ON public.organization_users
    FOR EACH ROW EXECUTE FUNCTION public.enforce_organization_limits();

CREATE TRIGGER enforce_course_limits
    BEFORE INSERT ON public.courses
    FOR EACH ROW EXECUTE FUNCTION public.enforce_organization_limits();

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant permissions on onboarding functions
GRANT EXECUTE ON FUNCTION public.signup_organization(TEXT, TEXT, TEXT, TEXT, TEXT, organization_plan) TO anon;
GRANT EXECUTE ON FUNCTION public.complete_organization_setup(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_organization_limits(TEXT, UUID) TO authenticated;

-- Grant permissions on new views
GRANT SELECT ON public.organization_student_dashboard TO authenticated;
GRANT SELECT ON public.organization_instructor_dashboard TO authenticated;