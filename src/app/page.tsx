import { Button } from '@/components/ui/button';
import Link from 'next/link';
import { ChevronDownIcon } from 'lucide-react';

export default function WelcomePage() {
  return (
    <>
      {/* Header */}
      <header className="absolute top-0 left-0 right-0 z-10 p-8">
        <div className="container mx-auto flex justify-between items-center">
          <div className="text-white text-2xl font-bold">EducaTech</div>
          <nav>
            <ul className="flex space-x-8 text-white">
              <li><Link className="hover:text-platform-500 transition-colors" href="/courses">Cursos</Link></li>
              <li><Link className="hover:text-platform-500 transition-colors" href="/teachers">Para Professores</Link></li>
              <li><Link className="hover:text-platform-500 transition-colors" href="/admin">Administração</Link></li>
              <li><Link className="hover:text-platform-500 transition-colors" href="/contact">Contato</Link></li>
            </ul>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <main>
        <section 
          className="relative min-h-screen flex items-center justify-center bg-cover bg-center bg-no-repeat"
          style={{
            backgroundImage: `linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.7)), url('https://lh3.googleusercontent.com/aida-public/AB6AXuBKoaeE3eJ4C6LT4w1_pso9ESMIRZEjHMmhoBxwDgf34oUU9BaHmvkSdX3Y5v7saWoRjufuI7A8pADKEkUkzgao6bc_sRo02xOwj84Sc-6ZMa1nu2SbrxtBoOtq63LVR865L2Yv6UMiWHtXA6mi70Gk2xyDBnErdjovdhoafDlfFpII0R8hqKEkWy36_TiRDCAShYICxZ-kivWBXy3nkDcfuNiqnZ8h8KIcbuTSoUg1_KYXGumo_zg98Ymug6fQ2O7GyXDfnStdiUgn')`
          }}
        >
          <div className="text-center text-white px-4">
            <h1 className="text-5xl md:text-7xl font-extrabold leading-tight tracking-tight mb-4">
              Bem-vindo ao futuro da educação.
            </h1>
            <p className="text-lg md:text-xl max-w-3xl mx-auto mb-8 font-light">
              Explore cursos inovadores, gerencie seus professores e administre sua instituição com facilidade e eficiência.
            </p>
            <Button 
              className="bg-platform-500 hover:bg-platform-600 text-white font-bold py-3 px-8 rounded-full text-lg transition-transform transform hover:scale-105"
              asChild
            >
              <Link href="/dashboard/student">Comece Agora</Link>
            </Button>
          </div>
          
          {/* Scroll indicator */}
          <div className="absolute bottom-10 left-1/2 -translate-x-1/2 text-white animate-bounce">
            <ChevronDownIcon className="h-8 w-8" />
          </div>
        </section>
      </main>
    </>
  );
}
