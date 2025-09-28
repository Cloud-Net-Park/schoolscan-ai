import { useState } from "react";
import { LoginForm } from "@/components/auth/login-form";
import { Header } from "@/components/ui/header";
import { Footer } from "@/components/ui/footer";
import { SuperAdminDashboard } from "@/components/dashboard/superadmin-dashboard";
import { StudentDashboard } from "@/components/dashboard/student-dashboard";

const Index = () => {
  const [user, setUser] = useState<{ role: string; name: string } | null>(null);

  const handleLogin = (role: string, credentials: any) => {
    // Mock login - in real app, this would authenticate with backend
    setUser({
      role,
      name: credentials.username || credentials.rollNo || "User"
    });
  };

  const handleLogout = () => {
    setUser(null);
  };

  if (!user) {
    return <LoginForm onLogin={handleLogin} />;
  }

  const renderDashboard = () => {
    switch (user.role) {
      case 'superadmin':
        return <SuperAdminDashboard />;
      case 'student':
        return <StudentDashboard />;
      default:
        return (
          <div className="container mx-auto p-6 text-center">
            <h2 className="text-2xl font-bold mb-4">Dashboard Coming Soon</h2>
            <p className="text-muted-foreground">
              {user.role} dashboard is under development
            </p>
          </div>
        );
    }
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Header 
        userRole={user.role} 
        userName={user.name} 
        onLogout={handleLogout} 
      />
      <main className="flex-1">
        {renderDashboard()}
      </main>
      <Footer />
    </div>
  );
};

export default Index;
