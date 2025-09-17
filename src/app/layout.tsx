import type { Metadata, Viewport } from 'next';
import { Manrope } from 'next/font/google';
import { ThemeProvider } from '@/providers/theme-provider';
import { Toaster } from '@/components/ui/toaster';
import './globals.css';

const manrope = Manrope({
  subsets: ['latin'],
  variable: '--font-manrope',
  weight: ['400', '500', '600', '700', '800'],
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: 'Avodah Educa',
    template: '%s | Avodah Educa'
  },
  description: 'Progressive Web App for Education - Empowering learning through technology',
  keywords: ['education', 'learning', 'pwa', 'students', 'teachers', 'avodah'],
  authors: [{ name: 'Avodah Educa Team' }],
  creator: 'Avodah Educa',
  publisher: 'Avodah Educa',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://avodah-educa.com'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'Avodah Educa - Educational Platform',
    description: 'Progressive Web App for Education - Empowering learning through technology',
    url: 'https://avodah-educa.com',
    siteName: 'Avodah Educa',
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Avodah Educa - Educational Platform',
    description: 'Progressive Web App for Education - Empowering learning through technology',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  manifest: '/manifest.json',
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#22c55e' },
    { media: '(prefers-color-scheme: dark)', color: '#15803d' },
  ],
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${manrope.variable} font-sans antialiased bg-slate-50 text-gray-800`} style={{ fontFamily: 'Manrope, sans-serif' }}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <div className="relative flex min-h-screen flex-col">
            <div className="flex-1">{children}</div>
          </div>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}