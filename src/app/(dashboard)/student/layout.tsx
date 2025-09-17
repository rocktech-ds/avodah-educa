import { Sidebar } from '@/components/layout/sidebar';

interface StudentLayoutProps {
  children: React.ReactNode;
}

export default function StudentLayout({ children }: StudentLayoutProps) {
  // Mock user data - in real app this would come from auth context
  const mockUser = {
    name: 'Sofia Mendes',
    role: 'Aluna',
    avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB4-uZyBPCM96AZUwBk2dQcTaBLLAWEl610dEzkq9b1mea7i7Db1wQGR8XcTfqOt347sr36MHqD1Fpf6nGhKIvKiH6Lt6RG46BXxQlc_kox7GHgfyJ7VInRx2VAthEnSJ8eANjvvYTaVnWxp9dUHEGi-NBWzvdNx8UxaUDOz81Rc9I8ipfZhl70Zpc-o3boCQHt5MOI3ahTOoQnufwRmUTllx2dTw8gvm3ofO4MTLy2S3XpNAraX-KM7M3TTSq4EqgyG2XvmyO3ujHE'
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar user={mockUser} variant="student" />
      <main className="flex-1 p-8 overflow-y-auto">
        <div className="max-w-4xl mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
}