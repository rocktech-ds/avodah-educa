-- =============================================================================
-- AVODAH EDUCA - MULTI-TENANT SAAS MIGRATION
-- =============================================================================
-- This migration transforms the platform into a multi-tenant SaaS

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- MULTI-TENANT ENUMS
-- =============================================================================

CREATE TYPE organization_plan AS ENUM ('starter', 'professional', 'enterprise', 'custom');
CREATE TYPE organization_status AS ENUM ('active', 'suspended', 'trial', 'cancelled');
CREATE TYPE subscription_status AS ENUM ('active', 'cancelled', 'past_due', 'trialing', 'unpaid');
CREATE TYPE tenant_user_role AS ENUM ('owner', 'admin', 'instructor', 'student');

-- =============================================================================
-- ORGANIZATIONS (TENANTS) TABLE
-- =============================================================================

CREATE TABLE public.organizations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    domain TEXT, -- Custom domain for tenant
    logo_url TEXT,
    description TEXT,
    
    -- Contact information
    contact_email TEXT NOT NULL,
    contact_phone TEXT,
    address JSONB DEFAULT '{}',
    
    -- Subscription & billing
    plan organization_plan NOT NULL DEFAULT 'starter',
    status organization_status NOT NULL DEFAULT 'trial',
    subscription_status subscription_status DEFAULT 'trialing',
    trial_ends_at TIMESTAMPTZ,
    subscription_ends_at TIMESTAMPTZ,
    
    -- Limits based on plan
    max_users INTEGER DEFAULT 10,
    max_courses INTEGER DEFAULT 5,
    max_storage_gb INTEGER DEFAULT 1,
    
    -- Features enabled
    features JSONB DEFAULT '{
        "custom_branding": false,
        "advanced_analytics": false,
        "sso_integration": false,
        "api_access": false,
        "custom_domain": false,
        "priority_support": false
    }',
    
    -- Customization
    theme_config JSONB DEFAULT '{}',
    custom_css TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes
CREATE INDEX idx_organizations_slug ON public.organizations(slug);
CREATE INDEX idx_organizations_status ON public.organizations(status);
CREATE INDEX idx_organizations_plan ON public.organizations(plan);
CREATE INDEX idx_organizations_domain ON public.organizations(domain) WHERE domain IS NOT NULL;

-- =============================================================================
-- ORGANIZATION USERS (TENANT MEMBERSHIP)
-- =============================================================================

CREATE TABLE public.organization_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role tenant_user_role NOT NULL DEFAULT 'student',
    
    -- Invitation status
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'suspended')),
    invited_by UUID REFERENCES auth.users(id),
    invited_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Permissions within tenant
    permissions JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Unique constraint - user can only have one role per organization
    UNIQUE(organization_id, user_id)
);

-- Add indexes
CREATE INDEX idx_organization_users_org_id ON public.organization_users(organization_id);
CREATE INDEX idx_organization_users_user_id ON public.organization_users(user_id);
CREATE INDEX idx_organization_users_role ON public.organization_users(role);
CREATE INDEX idx_organization_users_status ON public.organization_users(status);

-- =============================================================================
-- ADD TENANT COLUMNS TO EXISTING TABLES
-- =============================================================================

-- Add organization_id to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS current_organization_id UUID REFERENCES public.organizations(id);

-- Add organization_id to categories
ALTER TABLE public.categories 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

-- Add organization_id to courses
ALTER TABLE public.courses 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

-- Add organization_id to course_modules (inherits from course)
-- No direct FK needed as it's derived from course

-- Add organization_id to lessons (inherits from course)
-- No direct FK needed as it's derived from course

-- Add organization_id to enrollments (inherits from course)
-- No direct FK needed as it's derived from course

-- Add organization_id to lesson_progress (inherits from enrollment)
-- No direct FK needed as it's derived from enrollment

-- Add organization_id to assignments (inherits from lesson)
-- No direct FK needed as it's derived from lesson

-- Add organization_id to notifications
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE;

-- =============================================================================
-- CREATE INDEXES FOR TENANT ISOLATION
-- =============================================================================

CREATE INDEX idx_categories_organization_id ON public.categories(organization_id);
CREATE INDEX idx_courses_organization_id ON public.courses(organization_id);
CREATE INDEX idx_notifications_organization_id ON public.notifications(organization_id);

-- =============================================================================
-- ORGANIZATION INVITATIONS TABLE
-- =============================================================================

CREATE TABLE public.organization_invitations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role tenant_user_role NOT NULL DEFAULT 'student',
    invited_by UUID NOT NULL REFERENCES auth.users(id),
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMPTZ,
    accepted_by UUID REFERENCES auth.users(id),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Unique constraint - one pending invitation per email per organization
    UNIQUE(organization_id, email) WHERE accepted_at IS NULL
);

-- Add indexes
CREATE INDEX idx_invitations_org_id ON public.organization_invitations(organization_id);
CREATE INDEX idx_invitations_email ON public.organization_invitations(email);
CREATE INDEX idx_invitations_token ON public.organization_invitations(token);
CREATE INDEX idx_invitations_expires_at ON public.organization_invitations(expires_at);

-- =============================================================================
-- ORGANIZATION SETTINGS TABLE
-- =============================================================================

CREATE TABLE public.organization_settings (
    organization_id UUID PRIMARY KEY REFERENCES public.organizations(id) ON DELETE CASCADE,
    
    -- Branding
    primary_color TEXT DEFAULT '#3B82F6',
    secondary_color TEXT DEFAULT '#10B981',
    logo_url TEXT,
    favicon_url TEXT,
    custom_domain TEXT,
    
    -- Email settings
    from_email TEXT,
    from_name TEXT,
    email_signature TEXT,
    
    -- Learning settings
    default_course_visibility TEXT DEFAULT 'public' CHECK (default_course_visibility IN ('public', 'private', 'organization')),
    allow_public_enrollment BOOLEAN DEFAULT true,
    require_email_verification BOOLEAN DEFAULT true,
    auto_approve_instructors BOOLEAN DEFAULT false,
    
    -- Notification settings
    notification_settings JSONB DEFAULT '{
        "course_enrollment": true,
        "assignment_submission": true,
        "course_completion": true,
        "weekly_progress": true
    }',
    
    -- Integration settings
    integrations JSONB DEFAULT '{}',
    
    -- Custom fields for users
    custom_user_fields JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- HELPER FUNCTIONS FOR MULTI-TENANCY
-- =============================================================================

-- Function to get user's current organization
CREATE OR REPLACE FUNCTION public.get_current_organization_id()
RETURNS UUID AS $$
DECLARE
    org_id UUID;
BEGIN
    SELECT current_organization_id INTO org_id
    FROM public.profiles 
    WHERE id = auth.uid();
    
    RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user belongs to organization
CREATE OR REPLACE FUNCTION public.user_belongs_to_organization(user_id UUID, org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.organization_users
        WHERE user_id = user_belongs_to_organization.user_id 
        AND organization_id = org_id
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's role in organization
CREATE OR REPLACE FUNCTION public.get_user_role_in_organization(user_id UUID, org_id UUID)
RETURNS tenant_user_role AS $$
DECLARE
    user_role tenant_user_role;
BEGIN
    SELECT role INTO user_role
    FROM public.organization_users
    WHERE user_id = get_user_role_in_organization.user_id 
    AND organization_id = org_id
    AND status = 'active';
    
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to switch user's current organization
CREATE OR REPLACE FUNCTION public.switch_organization(org_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Check if user belongs to the organization
    IF NOT public.user_belongs_to_organization(auth.uid(), org_id) THEN
        RAISE EXCEPTION 'User does not belong to this organization';
    END IF;
    
    -- Update user's current organization
    UPDATE public.profiles
    SET current_organization_id = org_id,
        updated_at = NOW()
    WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a new organization
CREATE OR REPLACE FUNCTION public.create_organization(
    org_name TEXT,
    org_slug TEXT,
    owner_email TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_org_id UUID;
    owner_user_id UUID;
BEGIN
    -- Use provided email or current user's email
    IF owner_email IS NULL THEN
        owner_user_id := auth.uid();
    ELSE
        SELECT id INTO owner_user_id FROM auth.users WHERE email = owner_email;
        IF owner_user_id IS NULL THEN
            RAISE EXCEPTION 'Owner user not found';
        END IF;
    END IF;
    
    -- Create organization
    INSERT INTO public.organizations (name, slug, contact_email, status, trial_ends_at)
    VALUES (
        org_name, 
        org_slug, 
        (SELECT email FROM auth.users WHERE id = owner_user_id),
        'trial',
        NOW() + INTERVAL '14 days'
    )
    RETURNING id INTO new_org_id;
    
    -- Add owner to organization
    INSERT INTO public.organization_users (organization_id, user_id, role, status)
    VALUES (new_org_id, owner_user_id, 'owner', 'active');
    
    -- Set as user's current organization
    UPDATE public.profiles
    SET current_organization_id = new_org_id
    WHERE id = owner_user_id;
    
    -- Create default settings
    INSERT INTO public.organization_settings (organization_id)
    VALUES (new_org_id);
    
    RETURN new_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- UPDATE EXISTING TRIGGERS FOR MULTI-TENANCY
-- =============================================================================

-- Update the profile creation trigger to handle organization context
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'student')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to set organization_id on new records
CREATE OR REPLACE FUNCTION public.set_organization_id()
RETURNS TRIGGER AS $$
DECLARE
    current_org_id UUID;
BEGIN
    -- Get user's current organization
    current_org_id := public.get_current_organization_id();
    
    IF current_org_id IS NULL THEN
        RAISE EXCEPTION 'User must belong to an organization to perform this action';
    END IF;
    
    NEW.organization_id := current_org_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply organization trigger to relevant tables
CREATE TRIGGER set_org_id_categories
    BEFORE INSERT ON public.categories
    FOR EACH ROW EXECUTE FUNCTION public.set_organization_id();

CREATE TRIGGER set_org_id_courses
    BEFORE INSERT ON public.courses
    FOR EACH ROW EXECUTE FUNCTION public.set_organization_id();

CREATE TRIGGER set_org_id_notifications
    BEFORE INSERT ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION public.set_organization_id();

-- =============================================================================
-- ORGANIZATION ANALYTICS VIEWS
-- =============================================================================

-- View for organization dashboard
CREATE VIEW public.organization_dashboard AS
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
    
    o.created_at,
    o.updated_at
    
FROM public.organizations o
LEFT JOIN public.organization_users ou ON ou.organization_id = o.id
LEFT JOIN public.courses c ON c.organization_id = o.id
LEFT JOIN public.enrollments e ON e.course_id = c.id
WHERE o.id = public.get_current_organization_id()
GROUP BY o.id, o.name, o.slug, o.plan, o.status, o.trial_ends_at, o.subscription_ends_at, 
         o.max_users, o.max_courses, o.max_storage_gb, o.created_at, o.updated_at;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE public.organizations IS 'Multi-tenant organizations - each represents a separate educational institution';
COMMENT ON TABLE public.organization_users IS 'User membership in organizations with roles and permissions';
COMMENT ON TABLE public.organization_invitations IS 'Pending invitations to join organizations';
COMMENT ON TABLE public.organization_settings IS 'Customizable settings for each organization';
COMMENT ON FUNCTION public.get_current_organization_id() IS 'Gets the current user organization context for tenant isolation';
COMMENT ON FUNCTION public.create_organization(TEXT, TEXT, TEXT) IS 'Creates a new organization with owner and default settings';

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant permissions on new tables
GRANT SELECT, INSERT, UPDATE ON public.organizations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organization_users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organization_invitations TO authenticated;
GRANT SELECT, UPDATE ON public.organization_settings TO authenticated;

-- Grant permissions on functions
GRANT EXECUTE ON FUNCTION public.get_current_organization_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_belongs_to_organization(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role_in_organization(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.switch_organization(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_organization(TEXT, TEXT, TEXT) TO authenticated;

-- Grant permissions on views
GRANT SELECT ON public.organization_dashboard TO authenticated;