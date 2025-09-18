-- =============================================================================
-- MULTI-TENANT STORAGE AND MANAGEMENT FUNCTIONS
-- =============================================================================

-- =============================================================================
-- UPDATE STORAGE POLICIES FOR MULTI-TENANCY
-- =============================================================================

-- Drop existing storage policies
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;

DROP POLICY IF EXISTS "Instructors can upload course materials" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can update their course materials" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can delete their course materials" ON storage.objects;
DROP POLICY IF EXISTS "Public can view course materials" ON storage.objects;
DROP POLICY IF EXISTS "Enrolled students can view course materials" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all course materials" ON storage.objects;

DROP POLICY IF EXISTS "Students can upload assignment submissions" ON storage.objects;
DROP POLICY IF EXISTS "Students can update their assignment submissions" ON storage.objects;
DROP POLICY IF EXISTS "Students can delete their assignment submissions" ON storage.objects;
DROP POLICY IF EXISTS "Instructors can view assignment submissions" ON storage.objects;
DROP POLICY IF EXISTS "Students can view their own assignment submissions" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all assignment files" ON storage.objects;

DROP POLICY IF EXISTS "System can create certificates" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own certificates" ON storage.objects;
DROP POLICY IF EXISTS "Public can view certificates" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all certificates" ON storage.objects;

-- =============================================================================
-- MULTI-TENANT STORAGE POLICIES - PROFILES BUCKET
-- =============================================================================

-- Users can upload their own avatar within their organization
CREATE POLICY "Users can upload organization avatars"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'profiles' 
        AND auth.uid()::text = (storage.foldername(name))[2]  -- user_id folder
        AND (storage.foldername(name))[1] = public.get_current_organization_id()::text  -- org_id folder
        AND (storage.foldername(name))[3] = 'avatars'
    );

-- Users can update their own avatar within their organization
CREATE POLICY "Users can update organization avatars"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'profiles' 
        AND auth.uid()::text = (storage.foldername(name))[2]
        AND (storage.foldername(name))[1] = public.get_current_organization_id()::text
        AND (storage.foldername(name))[3] = 'avatars'
    );

-- Users can delete their own avatar within their organization
CREATE POLICY "Users can delete organization avatars"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'profiles' 
        AND auth.uid()::text = (storage.foldername(name))[2]
        AND (storage.foldername(name))[1] = public.get_current_organization_id()::text
        AND (storage.foldername(name))[3] = 'avatars'
    );

-- Users can view avatars within their organization
CREATE POLICY "Users can view organization avatars"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'profiles'
        AND (storage.foldername(name))[3] = 'avatars'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT STORAGE POLICIES - COURSES BUCKET
-- =============================================================================

-- Instructors can upload course materials for their courses within their organization
CREATE POLICY "Instructors can upload organization course materials"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'courses' 
        AND EXISTS (
            SELECT 1 FROM public.courses c
            JOIN public.organization_users ou ON ou.organization_id = c.organization_id
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Instructors can update their course materials
CREATE POLICY "Instructors can update organization course materials"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'courses' 
        AND EXISTS (
            SELECT 1 FROM public.courses c
            JOIN public.organization_users ou ON ou.organization_id = c.organization_id
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Instructors can delete their course materials
CREATE POLICY "Instructors can delete organization course materials"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'courses' 
        AND EXISTS (
            SELECT 1 FROM public.courses c
            JOIN public.organization_users ou ON ou.organization_id = c.organization_id
            WHERE c.id::text = (storage.foldername(name))[1]
            AND c.instructor_id = auth.uid()
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Organization members can view course materials for published courses they have access to
CREATE POLICY "Organization members can view course materials"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1 FROM public.courses c
            JOIN public.organization_users ou ON ou.organization_id = c.organization_id
            WHERE c.id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
            AND (
                c.status = 'published'
                OR c.instructor_id = auth.uid()
                OR ou.role IN ('owner', 'admin')
                OR EXISTS (
                    SELECT 1 FROM public.enrollments e
                    WHERE e.course_id = c.id
                    AND e.student_id = auth.uid()
                    AND e.status = 'active'
                )
            )
        )
    );

-- Organization admins can manage all course materials in their org
CREATE POLICY "Organization admins can manage all course materials"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'courses'
        AND EXISTS (
            SELECT 1 FROM public.courses c
            JOIN public.organization_users ou ON ou.organization_id = c.organization_id
            WHERE c.id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT STORAGE POLICIES - ASSIGNMENTS BUCKET
-- =============================================================================

-- Students can upload assignment submissions within their organization
CREATE POLICY "Students can upload organization assignment submissions"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'assignments'
        AND auth.uid()::text = (storage.foldername(name))[2]  -- student_id folder
        AND (storage.foldername(name))[3] = 'submissions'
        AND EXISTS (
            SELECT 1 FROM public.assignments a
            JOIN public.lessons l ON l.id = a.lesson_id
            JOIN public.courses c ON c.id = l.course_id
            JOIN public.organization_users ou ON ou.organization_id = c.organization_id
            WHERE (storage.foldername(name))[1]::uuid = c.organization_id
            AND a.student_id = auth.uid()
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Students can update their assignment submissions
CREATE POLICY "Students can update organization assignment submissions"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'assignments'
        AND auth.uid()::text = (storage.foldername(name))[2]
        AND (storage.foldername(name))[3] = 'submissions'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Students can delete their assignment submissions
CREATE POLICY "Students can delete organization assignment submissions"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'assignments'
        AND auth.uid()::text = (storage.foldername(name))[2]
        AND (storage.foldername(name))[3] = 'submissions'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Instructors can view assignment submissions for their courses
CREATE POLICY "Instructors can view organization assignment submissions"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'assignments'
        AND (storage.foldername(name))[3] = 'submissions'
        AND EXISTS (
            SELECT 1 FROM public.assignments a
            JOIN public.lessons l ON l.id = a.lesson_id
            JOIN public.courses c ON c.id = l.course_id
            WHERE (storage.foldername(name))[1]::uuid = c.organization_id
            AND (storage.foldername(name))[2]::uuid = a.student_id
            AND c.instructor_id = auth.uid()
        )
    );

-- Students can view their own assignment submissions
CREATE POLICY "Students can view their own organization assignment submissions"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'assignments'
        AND auth.uid()::text = (storage.foldername(name))[2]
        AND (storage.foldername(name))[3] = 'submissions'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Organization admins can manage all assignment files
CREATE POLICY "Organization admins can manage all assignment files"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'assignments'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT STORAGE POLICIES - CERTIFICATES BUCKET
-- =============================================================================

-- System can create certificates (organization-scoped)
CREATE POLICY "System can create organization certificates"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'certificates'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id::text = (storage.foldername(name))[2]
            AND ou.status = 'active'
        )
    );

-- Users can view their own certificates within their organization
CREATE POLICY "Users can view their own organization certificates"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'certificates'
        AND auth.uid()::text = (storage.foldername(name))[2]
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Organization members can view certificates within their organization (for verification)
CREATE POLICY "Organization members can view certificates"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'certificates'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.status = 'active'
        )
    );

-- Organization admins can manage all certificates
CREATE POLICY "Organization admins can manage certificates"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'certificates'
        AND EXISTS (
            SELECT 1 FROM public.organization_users ou
            WHERE ou.organization_id::text = (storage.foldername(name))[1]
            AND ou.user_id = auth.uid()
            AND ou.role IN ('owner', 'admin')
            AND ou.status = 'active'
        )
    );

-- =============================================================================
-- MULTI-TENANT MANAGEMENT FUNCTIONS
-- =============================================================================

-- Function to invite user to organization
CREATE OR REPLACE FUNCTION public.invite_user_to_organization(
    p_organization_id UUID,
    p_email TEXT,
    p_role tenant_user_role DEFAULT 'student'
)
RETURNS UUID AS $$
DECLARE
    invitation_id UUID;
    invitation_token TEXT;
BEGIN
    -- Check if user has permission to invite
    IF NOT EXISTS (
        SELECT 1 FROM public.organization_users ou
        WHERE ou.organization_id = p_organization_id
        AND ou.user_id = auth.uid()
        AND ou.role IN ('owner', 'admin')
        AND ou.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only organization owners/admins can invite users';
    END IF;
    
    -- Generate invitation token
    invitation_token := encode(gen_random_bytes(32), 'base64');
    
    -- Create invitation
    INSERT INTO public.organization_invitations (
        organization_id,
        email,
        role,
        invited_by,
        token
    )
    VALUES (
        p_organization_id,
        p_email,
        p_role,
        auth.uid(),
        invitation_token
    )
    RETURNING id INTO invitation_id;
    
    -- Create notification for the inviter
    PERFORM public.create_notification(
        auth.uid(),
        'Invitation Sent',
        'Invitation sent to ' || p_email,
        'invitation_sent',
        NULL,
        jsonb_build_object('invitation_id', invitation_id, 'email', p_email, 'role', p_role)
    );
    
    RETURN invitation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to accept organization invitation
CREATE OR REPLACE FUNCTION public.accept_organization_invitation(p_token TEXT)
RETURNS UUID AS $$
DECLARE
    invitation_record RECORD;
    membership_id UUID;
    user_email TEXT;
BEGIN
    -- Get user email
    SELECT email INTO user_email FROM auth.users WHERE id = auth.uid();
    
    -- Find and validate invitation
    SELECT * INTO invitation_record
    FROM public.organization_invitations
    WHERE token = p_token
    AND email = user_email
    AND accepted_at IS NULL
    AND expires_at > NOW();
    
    IF invitation_record.id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired invitation token';
    END IF;
    
    -- Check if user is already a member
    IF EXISTS (
        SELECT 1 FROM public.organization_users
        WHERE organization_id = invitation_record.organization_id
        AND user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'User is already a member of this organization';
    END IF;
    
    -- Create organization membership
    INSERT INTO public.organization_users (
        organization_id,
        user_id,
        role,
        status,
        invited_by,
        invited_at
    )
    VALUES (
        invitation_record.organization_id,
        auth.uid(),
        invitation_record.role,
        'active',
        invitation_record.invited_by,
        invitation_record.created_at
    )
    RETURNING id INTO membership_id;
    
    -- Mark invitation as accepted
    UPDATE public.organization_invitations
    SET accepted_at = NOW(),
        accepted_by = auth.uid()
    WHERE id = invitation_record.id;
    
    -- Set as user's current organization if they don't have one
    UPDATE public.profiles
    SET current_organization_id = COALESCE(current_organization_id, invitation_record.organization_id)
    WHERE id = auth.uid();
    
    -- Create notification for the inviter
    PERFORM public.create_notification(
        invitation_record.invited_by,
        'Invitation Accepted',
        user_email || ' has joined your organization',
        'invitation_accepted',
        NULL,
        jsonb_build_object('user_email', user_email, 'role', invitation_record.role)
    );
    
    RETURN membership_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user role in organization
CREATE OR REPLACE FUNCTION public.update_organization_user_role(
    p_user_id UUID,
    p_role tenant_user_role
)
RETURNS VOID AS $$
DECLARE
    current_org_id UUID;
BEGIN
    current_org_id := public.get_current_organization_id();
    
    -- Check permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.organization_users ou
        WHERE ou.organization_id = current_org_id
        AND ou.user_id = auth.uid()
        AND ou.role IN ('owner', 'admin')
        AND ou.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only organization owners/admins can update user roles';
    END IF;
    
    -- Cannot modify owner role unless you're the owner
    IF p_role = 'owner' AND NOT EXISTS (
        SELECT 1 FROM public.organization_users ou
        WHERE ou.organization_id = current_org_id
        AND ou.user_id = auth.uid()
        AND ou.role = 'owner'
        AND ou.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only organization owner can assign owner role';
    END IF;
    
    -- Update role
    UPDATE public.organization_users
    SET role = p_role,
        updated_at = NOW()
    WHERE organization_id = current_org_id
    AND user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found in organization';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove user from organization
CREATE OR REPLACE FUNCTION public.remove_user_from_organization(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    current_org_id UUID;
    target_user_role tenant_user_role;
BEGIN
    current_org_id := public.get_current_organization_id();
    
    -- Get target user's role
    SELECT role INTO target_user_role
    FROM public.organization_users
    WHERE organization_id = current_org_id
    AND user_id = p_user_id
    AND status = 'active';
    
    IF target_user_role IS NULL THEN
        RAISE EXCEPTION 'User not found in organization';
    END IF;
    
    -- Check permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.organization_users ou
        WHERE ou.organization_id = current_org_id
        AND ou.user_id = auth.uid()
        AND ou.role IN ('owner', 'admin')
        AND ou.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only organization owners/admins can remove users';
    END IF;
    
    -- Cannot remove owner
    IF target_user_role = 'owner' THEN
        RAISE EXCEPTION 'Cannot remove organization owner';
    END IF;
    
    -- Remove user from organization
    DELETE FROM public.organization_users
    WHERE organization_id = current_org_id
    AND user_id = p_user_id;
    
    -- Clear user's current organization if it was this one
    UPDATE public.profiles
    SET current_organization_id = NULL
    WHERE id = p_user_id
    AND current_organization_id = current_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get organization usage statistics
CREATE OR REPLACE FUNCTION public.get_organization_usage_stats(org_id UUID DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
    target_org_id UUID;
    usage_stats JSONB;
BEGIN
    target_org_id := COALESCE(org_id, public.get_current_organization_id());
    
    -- Check permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.organization_users ou
        WHERE ou.organization_id = target_org_id
        AND ou.user_id = auth.uid()
        AND ou.role IN ('owner', 'admin')
        AND ou.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only organization owners/admins can view usage stats';
    END IF;
    
    -- Calculate usage statistics
    SELECT jsonb_build_object(
        'organization_id', target_org_id,
        'users', jsonb_build_object(
            'total', COUNT(DISTINCT ou.user_id),
            'owners', COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'owner'),
            'admins', COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'admin'),
            'instructors', COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'instructor'),
            'students', COUNT(DISTINCT ou.user_id) FILTER (WHERE ou.role = 'student')
        ),
        'courses', jsonb_build_object(
            'total', COUNT(DISTINCT c.id),
            'published', COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'published'),
            'draft', COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'draft'),
            'archived', COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'archived')
        ),
        'enrollments', jsonb_build_object(
            'total', COUNT(DISTINCT e.id),
            'active', COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'active'),
            'completed', COUNT(DISTINCT e.id) FILTER (WHERE e.status = 'completed')
        ),
        'lessons', COUNT(DISTINCT l.id),
        'assignments', COUNT(DISTINCT a.id)
    )
    INTO usage_stats
    FROM public.organization_users ou
    LEFT JOIN public.courses c ON c.organization_id = ou.organization_id
    LEFT JOIN public.enrollments e ON e.course_id = c.id
    LEFT JOIN public.lessons l ON l.course_id = c.id
    LEFT JOIN public.assignments a ON a.lesson_id = l.id
    WHERE ou.organization_id = target_org_id
    AND ou.status = 'active';
    
    RETURN usage_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- UPDATE EXISTING FUNCTIONS FOR MULTI-TENANCY
-- =============================================================================

-- Update create_notification function to be organization-aware
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
    target_org_id UUID;
BEGIN
    -- Get organization context for the notification
    SELECT current_organization_id INTO target_org_id
    FROM public.profiles
    WHERE id = p_user_id;
    
    INSERT INTO public.notifications (user_id, title, message, type, action_url, metadata, organization_id)
    VALUES (p_user_id, p_title, p_message, p_type, p_action_url, p_metadata, target_org_id)
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update course search function for multi-tenancy
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
DECLARE
    current_org_id UUID;
BEGIN
    current_org_id := public.get_current_organization_id();
    
    IF current_org_id IS NULL THEN
        RAISE EXCEPTION 'User must belong to an organization to search courses';
    END IF;
    
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
        c.organization_id = current_org_id
        AND c.status = 'published'
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
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant permissions on new functions
GRANT EXECUTE ON FUNCTION public.invite_user_to_organization(UUID, TEXT, tenant_user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_organization_invitation(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_organization_user_role(UUID, tenant_user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_user_from_organization(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_organization_usage_stats(UUID) TO authenticated;