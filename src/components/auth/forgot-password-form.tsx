'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Loader2, Mail } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { authClient } from '@/lib/auth/utils';
import { useToast } from '@/hooks/use-toast';

export function ForgotPasswordForm() {
  const { toast } = useToast();
  
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [isEmailSent, setIsEmailSent] = useState(false);
  const [email, setEmail] = useState('');

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsLoading(true);
    setError('');

    const formData = new FormData(event.currentTarget);
    const emailValue = formData.get('email') as string;
    setEmail(emailValue);

    try {
      await authClient.resetPassword(emailValue);
      
      setIsEmailSent(true);
      toast({
        title: 'Email enviado!',
        description: 'Verifique sua caixa de entrada para redefinir sua senha.',
        variant: 'default',
      });

    } catch (error) {
      console.error('Password reset error:', error);
      setError(
        error instanceof Error 
          ? error.message 
          : 'Ocorreu um erro ao enviar o email. Tente novamente.'
      );
    } finally {
      setIsLoading(false);
    }
  };

  if (isEmailSent) {
    return (
      <Card className="w-full max-w-md mx-auto">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <div className="p-3 bg-green-100 rounded-full">
              <Mail className="h-6 w-6 text-green-600" />
            </div>
          </div>
          <CardTitle className="text-2xl font-bold text-center text-platform">
            Email Enviado!
          </CardTitle>
          <CardDescription className="text-center text-gray-600">
            Enviamos as instruções para redefinir sua senha para:
          </CardDescription>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="text-center">
            <p className="font-medium text-gray-900">{email}</p>
          </div>
          
          <Alert>
            <Mail className="h-4 w-4" />
            <AlertDescription>
              Verifique sua caixa de entrada e spam. O email pode levar alguns minutos para chegar.
            </AlertDescription>
          </Alert>
        </CardContent>

        <CardFooter className="flex flex-col space-y-4">
          <Link href="/auth/login" className="w-full">
            <Button variant="outline" className="w-full">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Voltar ao Login
            </Button>
          </Link>
          
          <button
            onClick={() => {
              setIsEmailSent(false);
              setEmail('');
            }}
            className="text-sm text-platform hover:text-platform-dark underline"
          >
            Enviar para outro email
          </button>
        </CardFooter>
      </Card>
    );
  }

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader className="space-y-1">
        <CardTitle className="text-2xl font-bold text-center text-platform">
          Esqueceu a Senha?
        </CardTitle>
        <CardDescription className="text-center text-gray-600">
          Digite seu email e enviaremos instruções para redefinir sua senha
        </CardDescription>
      </CardHeader>

      <form onSubmit={handleSubmit}>
        <CardContent className="space-y-4">
          {error && (
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              name="email"
              type="email"
              placeholder="seu@email.com"
              required
              disabled={isLoading}
              className="w-full"
            />
          </div>
        </CardContent>

        <CardFooter className="flex flex-col space-y-4">
          <Button
            type="submit"
            className="w-full"
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Enviando...
              </>
            ) : (
              'Enviar Instruções'
            )}
          </Button>

          <Link href="/auth/login" className="w-full">
            <Button variant="outline" className="w-full">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Voltar ao Login
            </Button>
          </Link>
        </CardFooter>
      </form>
    </Card>
  );
}