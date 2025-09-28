import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { CheckCircle, Mail } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface OTPVerificationProps {
  classData: any;
  onVerified: () => void;
  onClose: () => void;
}

export const OTPVerification = ({ classData, onVerified, onClose }: OTPVerificationProps) => {
  const [otp, setOtp] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [otpSent, setOtpSent] = useState(false);
  const { toast } = useToast();

  const sendOTP = () => {
    setOtpSent(true);
    toast({
      title: "OTP Sent",
      description: "Check your email for the verification code",
    });
  };

  const verifyOTP = () => {
    setIsVerifying(true);
    
    // Mock OTP verification
    setTimeout(() => {
      if (otp === "123456" || otp.length === 6) {
        toast({
          title: "Attendance Marked",
          description: "Your attendance has been successfully recorded",
        });
        onVerified();
      } else {
        toast({
          title: "Invalid OTP",
          description: "Please enter the correct OTP",
          variant: "destructive",
        });
      }
      setIsVerifying(false);
    }, 1000);
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="campus-card max-w-md">
        <DialogHeader>
          <DialogTitle>Verify Attendance</DialogTitle>
          <DialogDescription>
            Complete OTP verification to mark your attendance
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Class Information */}
          <div className="bg-secondary/50 p-4 rounded-lg">
            <h3 className="font-semibold">{classData.subject}</h3>
            <p className="text-sm text-muted-foreground">
              {classData.time} • {classData.room}
            </p>
            <p className="text-sm text-muted-foreground">
              Teacher: {classData.teacher}
            </p>
          </div>

          {!otpSent ? (
            <div className="text-center space-y-4">
              <Mail className="h-12 w-12 text-primary mx-auto" />
              <p className="text-sm text-muted-foreground">
                We'll send a verification code to your registered email address
              </p>
              <Button onClick={sendOTP} className="sky-button w-full gap-2">
                <Mail className="h-4 w-4" />
                Send OTP
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="text-center">
                <CheckCircle className="h-8 w-8 text-success mx-auto mb-2" />
                <p className="text-sm text-muted-foreground">
                  OTP sent to your email. Please check and enter below.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="otp">Enter OTP</Label>
                <Input
                  id="otp"
                  type="text"
                  placeholder="Enter 6-digit code"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  maxLength={6}
                  className="text-center text-lg tracking-wider"
                />
              </div>

              <Button 
                onClick={verifyOTP}
                disabled={otp.length !== 6 || isVerifying}
                className="sky-button w-full"
              >
                {isVerifying ? "Verifying..." : "Verify & Mark Attendance"}
              </Button>

              <Button 
                variant="ghost" 
                onClick={sendOTP}
                className="w-full text-sm"
              >
                Resend OTP
              </Button>
            </div>
          )}

          <Button variant="outline" onClick={onClose} className="w-full">
            Cancel
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};