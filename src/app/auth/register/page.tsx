import { RegisterForm } from '@/components/auth/register-form';

export default function RegisterPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-platform mb-2">
            Avodah Educa
          </h1>
          <p className="text-gray-600">
            Plataforma de Educação
          </p>
        </div>
        
        <RegisterForm />
      </div>
    </div>
  );
}