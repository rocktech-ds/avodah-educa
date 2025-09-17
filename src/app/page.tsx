import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { BookOpen, Users, Target, Zap, Download, Smartphone } from 'lucide-react';

export default function HomePage() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Hero Section */}
      <section className="hero-pattern bg-gradient-to-br from-avodah-50 via-white to-study-50 dark:from-gray-950 dark:via-gray-900 dark:to-gray-950 px-4 py-16 md:py-24">
        <div className="max-w-6xl mx-auto text-center">
          <div className="mb-8">
            <Badge variant="secondary" className="mb-4 text-avodah-700 bg-avodah-100 border-avodah-200">
              <Smartphone className="w-4 h-4 mr-2" />
              Progressive Web App
            </Badge>
            <h1 className="text-4xl md:text-6xl font-bold font-heading text-gradient-education mb-6">
              Avodah Educa
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground mb-8 max-w-3xl mx-auto">
              Empowering education through technology. A modern, accessible learning platform 
              designed for students, teachers, and educational institutions.
            </p>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Button size="lg" className="btn-education text-lg px-8 py-3">
              <BookOpen className="w-5 h-5 mr-2" />
              Start Learning
            </Button>
            <Button variant="outline" size="lg" className="btn-education-outline text-lg px-8 py-3">
              <Download className="w-5 h-5 mr-2" />
              Install App
            </Button>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 px-4 bg-background">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-bold font-heading mb-4">
              Modern Education Platform
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Built with cutting-edge technology to enhance the learning experience 
              for everyone in the educational ecosystem.
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card className="card-education hover:shadow-lg transition-all duration-300 animate-fade-in">
              <CardHeader>
                <div className="w-12 h-12 bg-avodah-100 dark:bg-avodah-900/30 rounded-lg flex items-center justify-center mb-4">
                  <BookOpen className="w-6 h-6 text-avodah-600 dark:text-avodah-400" />
                </div>
                <CardTitle className="text-xl font-heading">Interactive Learning</CardTitle>
                <CardDescription>
                  Engage with dynamic content, quizzes, and multimedia resources 
                  that adapt to your learning style.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="card-education hover:shadow-lg transition-all duration-300 animate-fade-in animation-delay-200">
              <CardHeader>
                <div className="w-12 h-12 bg-study-100 dark:bg-study-900/30 rounded-lg flex items-center justify-center mb-4">
                  <Users className="w-6 h-6 text-study-600 dark:text-study-400" />
                </div>
                <CardTitle className="text-xl font-heading">Collaborative Tools</CardTitle>
                <CardDescription>
                  Work together with classmates and teachers through real-time 
                  collaboration features and group projects.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="card-education hover:shadow-lg transition-all duration-300 animate-fade-in animation-delay-400">
              <CardHeader>
                <div className="w-12 h-12 bg-wisdom-100 dark:bg-wisdom-900/30 rounded-lg flex items-center justify-center mb-4">
                  <Target className="w-6 h-6 text-wisdom-600 dark:text-wisdom-400" />
                </div>
                <CardTitle className="text-xl font-heading">Progress Tracking</CardTitle>
                <CardDescription>
                  Monitor your learning journey with detailed analytics and 
                  personalized feedback to achieve your goals.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="card-education hover:shadow-lg transition-all duration-300 animate-fade-in animation-delay-600">
              <CardHeader>
                <div className="w-12 h-12 bg-focus-100 dark:bg-focus-900/30 rounded-lg flex items-center justify-center mb-4">
                  <Zap className="w-6 h-6 text-focus-600 dark:text-focus-400" />
                </div>
                <CardTitle className="text-xl font-heading">Offline Access</CardTitle>
                <CardDescription>
                  Continue learning even without internet connection. Download 
                  content and sync when you're back online.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="card-education hover:shadow-lg transition-all duration-300 animate-fade-in animation-delay-200">
              <CardHeader>
                <div className="w-12 h-12 bg-avodah-100 dark:bg-avodah-900/30 rounded-lg flex items-center justify-center mb-4">
                  <Smartphone className="w-6 h-6 text-avodah-600 dark:text-avodah-400" />
                </div>
                <CardTitle className="text-xl font-heading">Mobile First</CardTitle>
                <CardDescription>
                  Responsive design ensures perfect experience across all devices 
                  - desktop, tablet, and mobile.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="card-education hover:shadow-lg transition-all duration-300 animate-fade-in animation-delay-400">
              <CardHeader>
                <div className="w-12 h-12 bg-study-100 dark:bg-study-900/30 rounded-lg flex items-center justify-center mb-4">
                  <Users className="w-6 h-6 text-study-600 dark:text-study-400" />
                </div>
                <CardTitle className="text-xl font-heading">Accessibility</CardTitle>
                <CardDescription>
                  Designed with accessibility in mind, ensuring everyone can 
                  participate in the learning experience.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gradient-to-r from-avodah-600 to-study-600 px-4 py-16">
        <div className="max-w-4xl mx-auto text-center text-white">
          <h2 className="text-3xl md:text-4xl font-bold font-heading mb-6">
            Ready to Transform Your Learning?
          </h2>
          <p className="text-xl mb-8 opacity-90">
            Join thousands of students and educators who are already using 
            Avodah Educa to enhance their educational journey.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" variant="secondary" className="text-lg px-8 py-3">
              <BookOpen className="w-5 h-5 mr-2" />
              Get Started Free
            </Button>
            <Button size="lg" variant="outline" className="text-lg px-8 py-3 border-white/20 text-white hover:bg-white/10">
              Learn More
            </Button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-muted/50 px-4 py-8">
        <div className="max-w-6xl mx-auto text-center">
          <p className="text-muted-foreground">
            © 2024 Avodah Educa. Built with ❤️ for education.
          </p>
        </div>
      </footer>
    </div>
  );
}