import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Auth is enforced client-side via the AuthProvider (Supabase stores the
// session in localStorage, which middleware/cookies cannot read). This
// middleware only short-circuits static assets — everything else passes
// through and is gated by the dashboard layout's useAuth() redirect.
export function middleware(_req: NextRequest) {
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
};
