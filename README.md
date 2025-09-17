# 📚 Avodah Educa

A modern Progressive Web App (PWA) for education, built with Next.js 15, TypeScript, and Tailwind CSS. Avodah Educa is designed to empower learning through technology, providing an accessible and engaging platform for students, teachers, and educational institutions.

## 🌟 Features

- **Progressive Web App**: Full PWA support with offline capabilities and app-like experience
- **Modern UI**: Clean, accessible design with education-focused color palette
- **Responsive Design**: Mobile-first approach ensuring perfect experience across all devices
- **Dark Mode**: Built-in theme switching with system preference detection
- **TypeScript**: Full type safety for better developer experience
- **Component-Based**: Reusable UI components with consistent design patterns
- **Accessible**: Designed with accessibility in mind (WCAG compliance)

## 🎨 Design System

### Color Palette

**Primary - Avodah (Green)**
- Symbolizes growth, learning, and progress
- Primary: `#22c55e` (avodah-500)
- Range: `#f0fdf4` (avodah-50) to `#052e16` (avodah-950)

**Secondary Colors**
- **Study Blue**: `#3b82f6` - For knowledge and trust
- **Wisdom Amber**: `#f59e0b` - For insights and achievements  
- **Focus Purple**: `#d946ef` - For concentration and creativity

### Typography
- **Headings**: Poppins (modern, friendly)
- **Body**: Inter (readable, professional)
- **Code**: JetBrains Mono

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm, yarn, or pnpm

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd avodah-educa
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   # or
   pnpm install
   ```

3. **Run the development server**
   ```bash
   npm run dev
   # or
   yarn dev
   # or
   pnpm dev
   ```

4. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

### PWA Installation

When running on HTTPS or localhost, you'll see an install prompt to add Avodah Educa to your home screen or desktop.

## 📁 Project Structure

```
avodah-educa/
├── public/
│   ├── icons/           # PWA icons
│   ├── manifest.json    # PWA manifest
│   └── robots.txt
├── src/
│   ├── app/            # Next.js 15 app router
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/
│   │   ├── ui/         # Reusable UI components
│   │   ├── layout/     # Layout components
│   │   └── forms/      # Form components
│   ├── lib/
│   │   ├── hooks/      # Custom React hooks
│   │   ├── services/   # API services
│   │   └── utils/      # Utility functions
│   ├── providers/      # React context providers
│   ├── types/          # TypeScript type definitions
│   └── styles/         # Additional styles
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

## 🛠️ Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm run typecheck` - Run TypeScript checks

## 🧩 Key Components

### UI Components

All UI components are built with:
- **Radix UI**: For accessibility and behavior
- **Tailwind CSS**: For styling
- **CVA**: For variant management
- **Education Theme**: Custom color palette and styling

**Available Components:**
- Button (multiple variants)
- Card (with header, content, footer)
- Badge (status indicators)
- Toast (notifications)

### PWA Features

- **Service Worker**: Automatic caching and offline support
- **Web Manifest**: App metadata and icons
- **Install Prompt**: Native app-like installation
- **Offline Fallback**: Content available without internet

## 🎯 Educational Focus

Avodah Educa is specifically designed for educational environments:

- **Student-Friendly**: Intuitive interface for learners of all ages
- **Teacher Tools**: Built-in features for educators
- **Institutional Support**: Scalable for schools and universities
- **Accessibility First**: WCAG compliant for inclusive learning
- **Mobile Learning**: Perfect for on-the-go education

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Next.js](https://nextjs.org/)
- UI components powered by [Radix UI](https://radix-ui.com/)
- Styled with [Tailwind CSS](https://tailwindcss.com/)
- PWA capabilities by [next-pwa](https://github.com/shadowwalker/next-pwa)
- Icons from [Lucide](https://lucide.dev/)

---

**Avodah Educa** - Empowering education through technology 🎓✨