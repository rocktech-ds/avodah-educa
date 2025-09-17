import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value));
          response = NextResponse.next({
            request,
          });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // This will refresh session if expired - required for Server Components
  const { data: { user }, error } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;

  // Protected routes that require authentication
  const protectedRoutes = [
    '/dashboard',
    '/student',
    '/teacher',
    '/admin',
    '/profile',
    '/courses/manage',
    '/settings'
  ];

  // Auth routes that should redirect if already authenticated
  const authRoutes = ['/auth/login', '/auth/register', '/auth/forgot-password'];

  // Admin-only routes
  const adminRoutes = ['/admin'];

  // Teacher-only routes (teachers and admins can access)
  const teacherRoutes = ['/teacher', '/courses/manage'];

  // Check if the current path requires authentication
  const isProtectedRoute = protectedRoutes.some(route => pathname.startsWith(route));
  const isAuthRoute = authRoutes.some(route => pathname.startsWith(route));
  const isAdminRoute = adminRoutes.some(route => pathname.startsWith(route));
  const isTeacherRoute = teacherRoutes.some(route => pathname.startsWith(route));

  // If user is not authenticated and trying to access protected route
  if (isProtectedRoute && (!user || error)) {
    const redirectUrl = new URL('/auth/login', request.url);
    redirectUrl.searchParams.set('redirectTo', pathname);
    return NextResponse.redirect(redirectUrl);
  }

  // If user is authenticated and trying to access auth routes, redirect to dashboard
  if (isAuthRoute && user && !error) {
    // Get user role to determine redirect destination
    let redirectPath = '/dashboard';
    
    try {
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

      if (profile?.role) {
        switch (profile.role) {
          case 'admin':
            redirectPath = '/admin';
            break;
          case 'teacher':
            redirectPath = '/teacher';
            break;
          case 'student':
            redirectPath = '/student';
            break;
          default:
            redirectPath = '/dashboard';
        }
      }
    } catch (err) {
      // Fallback to dashboard if profile fetch fails
      redirectPath = '/dashboard';
    }

    return NextResponse.redirect(new URL(redirectPath, request.url));
  }

  // Role-based access control
  if (user && !error && (isAdminRoute || isTeacherRoute)) {
    try {
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

      if (!profile) {
        return NextResponse.redirect(new URL('/auth/login', request.url));
      }

      // Admin route access control
      if (isAdminRoute && profile.role !== 'admin') {
        return NextResponse.redirect(new URL('/dashboard', request.url));
      }

      // Teacher route access control (teachers and admins can access)
      if (isTeacherRoute && !['teacher', 'admin'].includes(profile.role)) {
        return NextResponse.redirect(new URL('/dashboard', request.url));
      }

    } catch (err) {
      // If profile fetch fails, redirect to login
      return NextResponse.redirect(new URL('/auth/login', request.url));
    }
  }

  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     * - api routes (handled separately)
     */
    '/((?!_next/static|_next/image|favicon.ico|manifest.json|sw.js|workbox-.*|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)',
  ],
};