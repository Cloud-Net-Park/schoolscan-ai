import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Camera, Upload } from "lucide-react";

interface QRScannerProps {
  onScanComplete: (data: string) => void;
  onClose: () => void;
}

export const QRScanner = ({ onScanComplete, onClose }: QRScannerProps) => {
  const [scanMethod, setScanMethod] = useState<'camera' | 'upload'>('camera');

  // Mock QR scan for demo
  const handleMockScan = () => {
    const mockQRData = JSON.stringify({
      classId: "CS101",
      subject: "Data Structures",
      time: "11:00 AM",
      teacher: "Prof. Smith",
      room: "Lab 1",
      timestamp: Date.now()
    });
    onScanComplete(mockQRData);
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="campus-card max-w-md">
        <DialogHeader>
          <DialogTitle>Scan QR Code</DialogTitle>
          <DialogDescription>
            Scan the QR code displayed by your teacher to mark attendance
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          <div className="flex gap-2">
            <Button
              variant={scanMethod === 'camera' ? 'default' : 'outline'}
              onClick={() => setScanMethod('camera')}
              className="flex-1 gap-2"
            >
              <Camera className="h-4 w-4" />
              Camera
            </Button>
            <Button
              variant={scanMethod === 'upload' ? 'default' : 'outline'}
              onClick={() => setScanMethod('upload')}
              className="flex-1 gap-2"
            >
              <Upload className="h-4 w-4" />
              Upload
            </Button>
          </div>

          {scanMethod === 'camera' ? (
            <div className="bg-muted rounded-lg p-8 text-center">
              <Camera className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
              <p className="text-sm text-muted-foreground mb-4">
                Camera access would be enabled here in a real implementation
              </p>
              <Button onClick={handleMockScan} className="sky-button">
                Simulate QR Scan
              </Button>
            </div>
          ) : (
            <div className="bg-muted rounded-lg p-8 text-center">
              <Upload className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
              <p className="text-sm text-muted-foreground mb-4">
                Upload a QR code image
              </p>
              <Button onClick={handleMockScan} className="sky-button">
                Upload & Scan
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