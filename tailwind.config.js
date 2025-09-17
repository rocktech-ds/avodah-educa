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
        // Education Theme - Avodah Colors
        avodah: {
          50:  '#f0fdf4',  // very light green
          100: '#dcfce7',  // light green
          200: '#bbf7d0',  // soft green
          300: '#86efac',  // medium green
          400: '#4ade80',  // bright green
          500: '#22c55e',  // primary green
          600: '#16a34a',  // dark green
          700: '#15803d',  // darker green
          800: '#166534',  // deep green
          900: '#14532d',  // deepest green
          950: '#052e16'   // forest green
        },
        wisdom: {
          50:  '#fefce8',  // very light yellow
          100: '#fef3c7',  // light yellow
          200: '#fde68a',  // soft yellow
          300: '#fcd34d',  // medium yellow
          400: '#fbbf24',  // bright yellow
          500: '#f59e0b',  // primary amber
          600: '#d97706',  // dark amber
          700: '#b45309',  // darker amber
          800: '#92400e',  // deep amber
          900: '#78350f',  // deepest amber
        },
        // Education-specific colors
        study: {
          50:  '#eff6ff',  // very light blue
          100: '#dbeafe',  // light blue
          200: '#bfdbfe',  // soft blue
          300: '#93c5fd',  // medium blue
          400: '#60a5fa',  // bright blue
          500: '#3b82f6',  // primary blue
          600: '#2563eb',  // dark blue
          700: '#1d4ed8',  // darker blue
          800: '#1e40af',  // deep blue
          900: '#1e3a8a',  // deepest blue
        },
        focus: {
          50:  '#fdf4ff',  // very light purple
          100: '#fae8ff',  // light purple
          200: '#f5d0fe',  // soft purple
          300: '#f0abfc',  // medium purple
          400: '#e879f9',  // bright purple
          500: '#d946ef',  // primary purple
          600: '#c026d3',  // dark purple
          700: '#a21caf',  // darker purple
          800: '#86198f',  // deep purple
          900: '#701a75',  // deepest purple
        },
        success: '#10b981',
        warning: '#f59e0b',
        error: '#ef4444',
        info: '#3b82f6'
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
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "Consolas", "monospace"],
        heading: ["Poppins", "system-ui", "sans-serif"],
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