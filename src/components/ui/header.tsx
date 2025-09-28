import { Button } from "@/components/ui/button";
import { LogOut, User, Calendar, QrCode } from "lucide-react";

interface HeaderProps {
  userRole: string;
  userName: string;
  onLogout: () => void;
}

export const Header = ({ userRole, userName, onLogout }: HeaderProps) => {
  const getRoleIcon = () => {
    switch (userRole) {
      case 'superadmin':
        return <User className="h-4 w-4" />;
      case 'subadmin':
        return <Calendar className="h-4 w-4" />;
      case 'classteacher':
      case 'subteacher':
        return <QrCode className="h-4 w-4" />;
      default:
        return <User className="h-4 w-4" />;
    }
  };

  return (
    <header className="bg-white/90 backdrop-blur-md border-b border-border shadow-sm">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <h1 className="text-2xl font-bold text-primary">
            Attendance Management
          </h1>
          <span className="role-badge">
            {getRoleIcon()}
            {userRole.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
          </span>
        </div>
        
        <div className="flex items-center space-x-4">
          <span className="text-sm text-muted-foreground">
            Welcome, <span className="font-medium text-foreground">{userName}</span>
          </span>
          <Button
            variant="outline"
            size="sm"
            onClick={onLogout}
            className="gap-2"
          >
            <LogOut className="h-4 w-4" />
            Logout
          </Button>
        </div>
      </div>
    </header>
  );
};