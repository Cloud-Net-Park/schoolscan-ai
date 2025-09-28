import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Users, Building2 } from "lucide-react";
import { AddDepartmentForm } from "./forms/add-department-form";
import { AddSubAdminForm } from "./forms/add-subadmin-form";

export const SuperAdminDashboard = () => {
  const [showAddDepartment, setShowAddDepartment] = useState(false);
  const [showAddSubAdmin, setShowAddSubAdmin] = useState(false);
  const [departments] = useState([
    { id: 1, name: "Computer Science", code: "CS" },
    { id: 2, name: "Electronics", code: "EC" },
    { id: 3, name: "Mechanical", code: "ME" }
  ]);
  const [subAdmins] = useState([
    { id: 1, username: "subadmin_cs", email: "cs@college.edu", department: "Computer Science", workingTime: "9 AM - 5 PM" },
    { id: 2, username: "subadmin_ec", email: "ec@college.edu", department: "Electronics", workingTime: "8 AM - 4 PM" }
  ]);

  return (
    <div className="container mx-auto p-6 space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold">Super Admin Dashboard</h2>
        <div className="flex gap-2">
          <Button 
            onClick={() => setShowAddDepartment(true)}
            className="sky-button gap-2"
          >
            <Plus className="h-4 w-4" />
            Add Department
          </Button>
          <Button 
            onClick={() => setShowAddSubAdmin(true)}
            className="sky-button gap-2"
          >
            <Plus className="h-4 w-4" />
            Add Sub Admin
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="campus-card">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Departments</CardTitle>
            <Building2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{departments.length}</div>
          </CardContent>
        </Card>

        <Card className="campus-card">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Sub Admins</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{subAdmins.length}</div>
          </CardContent>
        </Card>

        <Card className="campus-card">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Sessions</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">12</div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="departments" className="space-y-4">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="departments">Departments</TabsTrigger>
          <TabsTrigger value="subadmins">Sub Admins</TabsTrigger>
        </TabsList>

        <TabsContent value="departments" className="space-y-4">
          <Card className="campus-card">
            <CardHeader>
              <CardTitle>Departments</CardTitle>
              <CardDescription>Manage all departments in the institution</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {departments.map((dept) => (
                  <div key={dept.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h3 className="font-medium">{dept.name}</h3>
                      <p className="text-sm text-muted-foreground">Code: {dept.code}</p>
                    </div>
                    <Button variant="outline" size="sm">
                      Edit
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="subadmins" className="space-y-4">
          <Card className="campus-card">
            <CardHeader>
              <CardTitle>Sub Admins</CardTitle>
              <CardDescription>Manage department administrators</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {subAdmins.map((admin) => (
                  <div key={admin.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <h3 className="font-medium">{admin.username}</h3>
                      <p className="text-sm text-muted-foreground">{admin.email}</p>
                      <p className="text-sm text-muted-foreground">{admin.department} • {admin.workingTime}</p>
                    </div>
                    <Button variant="outline" size="sm">
                      Edit
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {showAddDepartment && (
        <AddDepartmentForm
          onClose={() => setShowAddDepartment(false)}
          onSubmit={(data) => {
            console.log('Department data:', data);
            setShowAddDepartment(false);
          }}
        />
      )}

      {showAddSubAdmin && (
        <AddSubAdminForm
          departments={departments}
          onClose={() => setShowAddSubAdmin(false)}
          onSubmit={(data) => {
            console.log('Sub admin data:', data);
            setShowAddSubAdmin(false);
          }}
        />
      )}
    </div>
  );
};