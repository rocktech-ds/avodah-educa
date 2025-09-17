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