/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        // Platform Primary - Stitch Design System
        platform: {
          50:  '#e6f7ff',  // very light blue
          100: '#bae7ff',  // light blue
          200: '#7dd3fc',  // soft blue
          300: '#38bdf8',  // medium blue
          400: '#0ea5e9',  // bright blue
          500: '#13a4ec',  // primary platform blue (from Stitch)
          600: '#0284c7',  // dark blue
          700: '#0369a1',  // darker blue
          800: '#075985',  // deep blue
          900: '#0c4a6e',  // deepest blue
        },
        // Supporting colors for educational context
        success: {
          50:  '#ecfdf5',
          500: '#10b981',
          600: '#059669',
        },
        warning: {
          50:  '#fffbeb',
          500: '#f59e0b',
          600: '#d97706',
        },
        error: {
          50:  '#fef2f2',
          500: '#ef4444',
          600: '#dc2626',
        },
        info: {
          50:  '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
        }
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
        "fade-in": {
          from: { opacity: 0 },
          to: { opacity: 1 },
        },
        "slide-in-from-top": {
          from: { transform: "translateY(-100%)" },
          to: { transform: "translateY(0)" },
        },
        "slide-in-from-left": {
          from: { transform: "translateX(-100%)" },
          to: { transform: "translateX(0)" },
        },
        "bounce-gentle": {
          "0%, 100%": { transform: "translateY(-5%)" },
          "50%": { transform: "translateY(0)" },
        }
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.5s ease-out",
        "slide-in-from-top": "slide-in-from-top 0.3s ease-out",
        "slide-in-from-left": "slide-in-from-left 0.3s ease-out",
        "bounce-gentle": "bounce-gentle 2s infinite",
      },
      fontFamily: {
        sans: ["Manrope", "Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "Consolas", "monospace"],
        heading: ["Manrope", "system-ui", "sans-serif"],
      },
      boxShadow: {
        'subtle': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'border': 'inset 0 0 0 1px rgba(0, 0, 0, 0.1)',
        'focus': '0 0 0 2px rgba(34, 197, 94, 0.2)',
        'elevated': '0 4px 12px -2px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.03)',
        'education': '0 4px 12px -2px rgba(34, 197, 94, 0.1), 0 2px 4px -2px rgba(34, 197, 94, 0.05)',
      }
    },
  },
  plugins: [require("tailwindcss-animate")],
};