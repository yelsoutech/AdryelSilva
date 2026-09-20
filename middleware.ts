import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const PUBLIC_ROUTES = ['/login', '/signup', '/reset-password'];

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Allow public routes
  if (PUBLIC_ROUTES.some((route) => pathname === route || pathname.startsWith(route + '/'))) {
    // If already authenticated and visiting a public route, redirect to dashboard
    const sessionToken = req.cookies.get('sb-access-token')?.value;
    if (sessionToken && (pathname === '/login' || pathname === '/signup')) {
      return NextResponse.redirect(new URL('/dashboard', req.url));
    }
    return NextResponse.next();
  }

  // Check for session token on protected routes
  const sessionToken = req.cookies.get('sb-access-token')?.value;

  if (!sessionToken) {
    const redirect = encodeURIComponent(pathname);
    return NextResponse.redirect(new URL(`/login?redirect=${redirect}`, req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
