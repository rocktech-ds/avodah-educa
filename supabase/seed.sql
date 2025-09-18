-- =============================================================================
-- AVODAH EDUCA - MULTI-TENANT SAAS SEED DATA
-- =============================================================================
-- This file contains sample data for development and testing

-- =============================================================================
-- SAMPLE ORGANIZATIONS FOR TESTING
-- =============================================================================

-- Note: In production, organizations are created through the signup flow
-- These are for development testing only

/*
Example organizations (create these after setting up the authentication system):

SELECT public.signup_organization(
    'Universidade Demo',
    'universidade-demo', 
    'João Silva',
    'admin@universidade-demo.com',
    'password123',
    'professional'
);

SELECT public.signup_organization(
    'Escola Técnica ABC',
    'escola-abc',
    'Maria Santos', 
    'admin@escola-abc.com',
    'password123',
    'starter'
);

SELECT public.signup_organization(
    'Instituto de Tecnologia',
    'instituto-tech',
    'Carlos Oliveira',
    'admin@instituto-tech.com', 
    'password123',
    'enterprise'
);
*/

-- =============================================================================
-- MULTI-TENANT SAMPLE DATA STRUCTURE
-- =============================================================================

-- Categories will be created automatically when organizations are set up
-- Each organization gets its own set of default categories

-- Sample courses (organization-specific)
/*
After creating organizations and users, you can create sample courses:

-- First, get the organization ID and instructor ID
-- Then create courses for that organization:

INSERT INTO public.courses (
    title, 
    slug, 
    description, 
    short_description,
    organization_id,
    instructor_id, 
    category_id, 
    status, 
    level, 
    duration_minutes, 
    price, 
    is_free,
    tags,
    language
) VALUES
(
    'Introdução ao React.js',
    'introducao-react-js',
    'Aprenda os fundamentos do React.js, uma das bibliotecas JavaScript mais populares para desenvolvimento de interfaces de usuário.',
    'Fundamentos do React.js para iniciantes',
    '[ORG_UUID]', -- Replace with organization UUID
    '[INSTRUCTOR_UUID]', -- Replace with instructor UUID
    (SELECT id FROM public.categories WHERE slug = 'tecnologia' AND organization_id = '[ORG_UUID]'),
    'published',
    'beginner',
    480, -- 8 hours
    99.90,
    false,
    ARRAY['React', 'JavaScript', 'Frontend', 'Web Development'],
    'pt'
);
*/

-- =============================================================================
-- DEVELOPMENT HELPER FUNCTIONS
-- =============================================================================

-- Function to create a demo organization with sample data
CREATE OR REPLACE FUNCTION public.create_demo_organization(
    p_org_name TEXT,
    p_org_slug TEXT,
    p_owner_email TEXT
)
RETURNS UUID AS $$
DECLARE
    demo_org_id UUID;
    tech_category_id UUID;
    sample_course_id UUID;
BEGIN
    -- Create organization (this will create default categories)
    SELECT public.signup_organization(
        p_org_name,
        p_org_slug,
        'Demo Owner',
        p_owner_email,
        'demopassword123',
        'professional'
    )->>'organization_id' INTO demo_org_id;
    
    -- Get technology category ID
    SELECT id INTO tech_category_id
    FROM public.categories 
    WHERE organization_id = demo_org_id::uuid 
    AND slug = 'tecnologia';
    
    -- Note: To complete this demo setup, you would need to:
    -- 1. Create a user account for the owner email
    -- 2. Call complete_organization_setup()
    -- 3. Add sample courses, lessons, etc.
    
    RETURN demo_org_id::uuid;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- HELPER QUERIES FOR DEVELOPMENT
-- =============================================================================

-- Query to check if database is set up correctly
-- SELECT 'Multi-tenant database setup complete!' as message;

-- Query to show all tables
-- SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Query to show all functions
-- SELECT routine_name, routine_type FROM information_schema.routines WHERE routine_schema = 'public' ORDER BY routine_name;

-- Query to show RLS policies
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;

-- Query to show storage buckets
-- SELECT * FROM storage.buckets;

-- Query to show organizations
-- SELECT id, name, slug, status, plan, trial_ends_at FROM public.organizations;

-- =============================================================================
-- MULTI-TENANT SAMPLE DATA NOTES
-- =============================================================================

-- To add sample data in a multi-tenant setup:
-- 1. Create organizations using signup_organization()
-- 2. Create user accounts through Supabase Auth
-- 3. Complete organization setup using complete_organization_setup()
-- 4. Invite users to organizations using invite_user_to_organization()
-- 5. Create organization-specific courses, lessons, etc.
-- 6. Enroll students in courses within their organizations

-- Example organization signup flow:
-- 1. Call signup_organization() -> returns org data
-- 2. Create user account in Supabase Auth
-- 3. User logs in and calls complete_organization_setup()
-- 4. Organization is ready with default categories and settings

-- Example user invitation flow:
-- 1. Org admin calls invite_user_to_organization()
-- 2. Invited user receives email with token
-- 3. User signs up (or logs in) and calls accept_organization_invitation()
-- 4. User becomes member of organization with assigned role

-- Example organization switching:
-- 1. User calls switch_organization() with desired org ID
-- 2. All subsequent operations are scoped to that organization
-- 3. Data isolation is maintained through RLS policies

-- Example limit checking:
-- SELECT public.check_organization_limits('all'); -- Check all limits
-- SELECT public.check_organization_limits('users'); -- Check user limit only

-- Example usage statistics:
-- SELECT public.get_organization_usage_stats(); -- Current org stats
-- SELECT public.get_organization_usage_stats('[ORG_UUID]'); -- Specific org stats

-- Sample data for Avodah Educa platform
-- This file contains initial data for testing and development

-- Insert sample categories
INSERT INTO public.categories (name, slug, description, color, icon, sort_order) VALUES
('Programação', 'programacao', 'Cursos de desenvolvimento e programação', '#13a4ec', 'Code', 1),
('Design', 'design', 'Cursos de design gráfico e UX/UI', '#f59e0b', 'Palette', 2),
('Marketing', 'marketing', 'Estratégias de marketing digital', '#10b981', 'TrendingUp', 3),
('Negócios', 'negocios', 'Empreendedorismo e gestão empresarial', '#8b5cf6', 'Briefcase', 4),
('Idiomas', 'idiomas', 'Cursos de línguas estrangeiras', '#ef4444', 'Globe', 5);

-- Insert sample admin user (note: this will be created via auth, but we can prepare profile data)
-- Password will be 'admin123' when created via signup

-- Sample courses (we'll use placeholder instructor IDs that should be replaced with real user IDs)
INSERT INTO public.courses (
  title, 
  slug, 
  description, 
  short_description,
  thumbnail_url,
  instructor_id,
  category_id,
  status,
  level,
  duration_minutes,
  price,
  is_free,
  learning_objectives,
  tags,
  language,
  is_featured,
  published_at
) VALUES
(
  'Introdução ao React.js',
  'introducao-react-js',
  'Aprenda os fundamentos do React.js, uma das bibliotecas JavaScript mais populares para criação de interfaces de usuário. Este curso aborda desde conceitos básicos até práticas avançadas.',
  'Domine React.js do básico ao avançado com projetos práticos',
  '/images/courses/react-intro.jpg',
  '00000000-0000-0000-0000-000000000000', -- Placeholder - replace with real instructor ID
  (SELECT id FROM public.categories WHERE slug = 'programacao'),
  'published',
  'beginner',
  1200,
  99.99,
  true,
  ARRAY['Entender componentes React', 'Gerenciar estado com hooks', 'Trabalhar com props', 'Criar aplicações interativas'],
  ARRAY['react', 'javascript', 'frontend', 'web development'],
  'pt',
  true,
  NOW()
),
(
  'Design System com Figma',
  'design-system-figma',
  'Aprenda a criar e manter sistemas de design consistentes utilizando o Figma. Desde a criação de componentes até a documentação completa.',
  'Crie sistemas de design profissionais no Figma',
  '/images/courses/figma-design-system.jpg',
  '00000000-0000-0000-0000-000000000000', -- Placeholder
  (SELECT id FROM public.categories WHERE slug = 'design'),
  'published',
  'intermediate',
  900,
  149.99,
  true,
  ARRAY['Criar componentes reutilizáveis', 'Definir tokens de design', 'Documentar sistemas', 'Colaborar com desenvolvedores'],
  ARRAY['figma', 'design system', 'ui/ux', 'design'],
  'pt',
  false,
  NOW()
),
(
  'Marketing Digital para Iniciantes',
  'marketing-digital-iniciantes',
  'Um guia completo sobre marketing digital, cobrindo desde SEO até redes sociais. Perfeito para quem está começando no mundo digital.',
  'Domine as estratégias essenciais do marketing digital',
  '/images/courses/marketing-digital.jpg',
  '00000000-0000-0000-0000-000000000000', -- Placeholder
  (SELECT id FROM public.categories WHERE slug = 'marketing'),
  'published',
  'beginner',
  800,
  79.99,
  true,
  ARRAY['Entender SEO básico', 'Criar campanhas no Google Ads', 'Gerenciar redes sociais', 'Analisar métricas'],
  ARRAY['marketing', 'seo', 'google ads', 'redes sociais'],
  'pt',
  true,
  NOW()
);

-- Insert sample course modules and lessons for React course
WITH react_course AS (
  SELECT id FROM public.courses WHERE slug = 'introducao-react-js'
)
INSERT INTO public.course_modules (course_id, title, description, sort_order) 
SELECT 
  react_course.id,
  module.title,
  module.description,
  module.sort_order
FROM react_course
CROSS JOIN (
  VALUES 
    ('Fundamentos', 'Conceitos básicos do React', 1),
    ('Componentes', 'Criando e organizando componentes', 2),
    ('Estado e Props', 'Gerenciamento de dados no React', 3),
    ('Hooks', 'Usando React Hooks', 4),
    ('Projeto Prático', 'Construindo uma aplicação completa', 5)
) AS module(title, description, sort_order);

-- Insert lessons for the first module (Fundamentos)
WITH react_course AS (
  SELECT id FROM public.courses WHERE slug = 'introducao-react-js'
),
fundamentos_module AS (
  SELECT id FROM public.course_modules 
  WHERE course_id = (SELECT id FROM react_course) 
  AND title = 'Fundamentos'
)
INSERT INTO public.lessons (
  course_id, 
  module_id, 
  title, 
  slug,
  description,
  content,
  type,
  sort_order,
  is_preview,
  estimated_minutes
)
SELECT 
  react_course.id,
  fundamentos_module.id,
  lesson.title,
  lesson.slug,
  lesson.description,
  lesson.content,
  lesson.type::lesson_type,
  lesson.sort_order,
  lesson.is_preview,
  lesson.estimated_minutes
FROM react_course, fundamentos_module
CROSS JOIN (
  VALUES 
    (
      'O que é React?', 
      'o-que-e-react',
      'Introdução ao React e sua filosofia',
      'React é uma biblioteca JavaScript criada pelo Facebook para construção de interfaces de usuário...',
      'text',
      1,
      true,
      15
    ),
    (
      'Configurando o Ambiente',
      'configurando-ambiente',
      'Como configurar seu ambiente de desenvolvimento',
      'Nesta aula você aprenderá a configurar seu ambiente para desenvolvimento React...',
      'video',
      2,
      true,
      20
    ),
    (
      'Primeiro Componente',
      'primeiro-componente',
      'Criando seu primeiro componente React',
      'Vamos criar nosso primeiro componente React e entender sua estrutura...',
      'video',
      3,
      false,
      25
    )
) AS lesson(title, slug, description, content, type, sort_order, is_preview, estimated_minutes);

-- Insert sample notifications templates
INSERT INTO public.notifications (user_id, title, message, type, metadata) VALUES
('00000000-0000-0000-0000-000000000000', -- Placeholder for system notifications
'Bem-vindo ao Avodah Educa!',
'Sua conta foi criada com sucesso. Comece explorando nossos cursos.',
'welcome',
'{"action": "explore_courses"}'::jsonb);

-- Update course durations based on lessons
UPDATE public.courses 
SET duration_minutes = (
  SELECT COALESCE(SUM(estimated_minutes), 0)
  FROM public.lessons 
  WHERE lessons.course_id = courses.id
)
WHERE EXISTS (
  SELECT 1 FROM public.lessons WHERE lessons.course_id = courses.id
);