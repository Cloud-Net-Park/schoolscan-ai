import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { QrCode, Scan, CheckCircle, Clock } from "lucide-react";
import { QRScanner } from "../qr/qr-scanner";
import { OTPVerification } from "../qr/otp-verification";

export const StudentDashboard = () => {
  const [showScanner, setShowScanner] = useState(false);
  const [showOTP, setShowOTP] = useState(false);
  const [scannedData, setScannedData] = useState<any>(null);
  
  const attendanceRecords = [
    { id: 1, subject: "Data Structures", time: "9:00 AM", status: "present", date: "2025-01-10" },
    { id: 2, subject: "Database Systems", time: "11:00 AM", status: "present", date: "2025-01-10" },
    { id: 3, subject: "Computer Networks", time: "2:00 PM", status: "absent", date: "2025-01-10" },
  ];

  const todayClasses = [
    { id: 1, subject: "Operating Systems", time: "9:00 AM - 10:00 AM", room: "Lab 1", status: "upcoming" },
    { id: 2, subject: "Software Engineering", time: "11:00 AM - 12:00 PM", room: "Room 201", status: "current" },
    { id: 3, subject: "Machine Learning", time: "2:00 PM - 3:00 PM", room: "Lab 2", status: "upcoming" },
  ];

  const handleScanComplete = (data: string) => {
    // Simulate QR data parsing
    const qrData = JSON.parse(data || '{"classId": "CS101", "time": "11:00 AM", "teacher": "Prof. Smith"}');
    setScannedData(qrData);
    setShowScanner(false);
    setShowOTP(true);
  };

  const handleOTPVerified = () => {
    setShowOTP(false);
    setScannedData(null);
  };

  return (
    <div className="container mx-auto p-4 space-y-6 max-w-4xl">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold mb-2">Student Dashboard</h2>
        <p className="text-muted-foreground">Scan QR codes to mark your attendance</p>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Card className="campus-card">
          <CardContent className="p-6 text-center">
            <QrCode className="h-12 w-12 text-primary mx-auto mb-4" />
            <h3 className="font-semibold mb-2">Mark Attendance</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Scan QR code to mark your presence
            </p>
            <Button 
              onClick={() => setShowScanner(true)}
              className="sky-button w-full gap-2"
            >
              <Scan className="h-4 w-4" />
              Scan QR Code
            </Button>
          </CardContent>
        </Card>

        <Card className="campus-card">
          <CardHeader className="pb-4">
            <CardTitle className="text-lg">Today's Summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm">Classes Attended</span>
              <span className="font-semibold text-success">2/3</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm">Attendance Rate</span>
              <span className="font-semibold text-primary">67%</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm">Next Class</span>
              <span className="font-semibold">2:00 PM</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Today's Schedule */}
      <Card className="campus-card">
        <CardHeader>
          <CardTitle>Today's Classes</CardTitle>
          <CardDescription>Your class schedule for today</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {todayClasses.map((classItem) => (
              <div key={classItem.id} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center space-x-3">
                  <div className={`w-3 h-3 rounded-full ${
                    classItem.status === 'current' ? 'bg-success' : 
                    classItem.status === 'upcoming' ? 'bg-warning' : 'bg-muted'
                  }`} />
                  <div>
                    <h4 className="font-medium">{classItem.subject}</h4>
                    <p className="text-sm text-muted-foreground">{classItem.room} • {classItem.time}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {classItem.status === 'current' && (
                    <span className="role-badge bg-success text-success-foreground">Live</span>
                  )}
                  <Clock className="h-4 w-4 text-muted-foreground" />
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Attendance History */}
      <Card className="campus-card">
        <CardHeader>
          <CardTitle>Recent Attendance</CardTitle>
          <CardDescription>Your attendance history</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {attendanceRecords.map((record) => (
              <div key={record.id} className="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <h4 className="font-medium">{record.subject}</h4>
                  <p className="text-sm text-muted-foreground">{record.date} • {record.time}</p>
                </div>
                <div className="flex items-center gap-2">
                  {record.status === 'present' ? (
                    <CheckCircle className="h-5 w-5 text-success" />
                  ) : (
                    <div className="w-5 h-5 rounded-full border-2 border-destructive" />
                  )}
                  <span className={`text-sm font-medium ${
                    record.status === 'present' ? 'text-success' : 'text-destructive'
                  }`}>
                    {record.status === 'present' ? 'Present' : 'Absent'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {showScanner && (
        <QRScanner
          onScanComplete={handleScanComplete}
          onClose={() => setShowScanner(false)}
        />
      )}

      {showOTP && scannedData && (
        <OTPVerification
          classData={scannedData}
          onVerified={handleOTPVerified}
          onClose={() => setShowOTP(false)}
        />
      )}
    </div>
  );
};