-- Create enum types for roles and attendance status
CREATE TYPE public.user_role AS ENUM ('superadmin', 'subadmin', 'class_teacher', 'sub_teacher', 'student');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'late');
CREATE TYPE public.day_of_week AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

-- Create departments table
CREATE TABLE public.departments (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create profiles table for user information
CREATE TABLE public.profiles (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    role user_role NOT NULL,
    department_id UUID REFERENCES public.departments(id),
    working_time TEXT,
    roll_number TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(user_id)
);

-- Create classes table
CREATE TABLE public.classes (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    department_id UUID NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
    class_teacher_id UUID REFERENCES public.profiles(id),
    semester INTEGER,
    academic_year TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create students table
CREATE TABLE public.students (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    roll_number TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create schedules table
CREATE TABLE public.schedules (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    day_of_week day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create QR codes table for dynamic QR generation
CREATE TABLE public.qr_codes (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    schedule_id UUID NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create OTP table for attendance verification
CREATE TABLE public.otps (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    qr_code_id UUID NOT NULL REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    otp_code TEXT NOT NULL,
    email TEXT NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create attendance table
CREATE TABLE public.attendance (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    schedule_id UUID NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
    qr_code_id UUID REFERENCES public.qr_codes(id),
    otp_id UUID REFERENCES public.otps(id),
    status attendance_status NOT NULL DEFAULT 'present',
    marked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    notes TEXT
);

-- Enable Row Level Security on all tables
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Create function to get user role
CREATE OR REPLACE FUNCTION public.get_user_role(user_uuid UUID)
RETURNS user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE user_id = user_uuid;
$$;

-- Create function to check if user has role
CREATE OR REPLACE FUNCTION public.has_role(user_uuid UUID, required_role user_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = user_uuid AND role = required_role
    );
$$;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Create triggers for updated_at columns
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON public.classes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON public.schedules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS Policies for departments
CREATE POLICY "Superadmins can manage departments" ON public.departments FOR ALL USING (public.has_role(auth.uid(), 'superadmin'));
CREATE POLICY "Other users can view departments" ON public.departments FOR SELECT USING (auth.role() = 'authenticated');

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Superadmins can manage all profiles" ON public.profiles FOR ALL USING (public.has_role(auth.uid(), 'superadmin'));
CREATE POLICY "Sub-admins can view profiles in their department" ON public.profiles FOR SELECT USING (
    public.has_role(auth.uid(), 'subadmin') AND 
    department_id = (SELECT department_id FROM public.profiles WHERE user_id = auth.uid())
);

-- RLS Policies for classes
CREATE POLICY "Superadmins can manage all classes" ON public.classes FOR ALL USING (public.has_role(auth.uid(), 'superadmin'));
CREATE POLICY "Sub-admins can manage classes in their department" ON public.classes FOR ALL USING (
    public.has_role(auth.uid(), 'subadmin') AND 
    department_id = (SELECT department_id FROM public.profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Teachers can view their assigned classes" ON public.classes FOR SELECT USING (
    class_teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()) OR
    id IN (SELECT class_id FROM public.schedules WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
);

-- RLS Policies for students
CREATE POLICY "Students can view their own record" ON public.students FOR SELECT USING (
    profile_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Teachers can view students in their classes" ON public.students FOR SELECT USING (
    class_id IN (
        SELECT id FROM public.classes WHERE class_teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
        UNION
        SELECT class_id FROM public.schedules WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    )
);
CREATE POLICY "Admins can manage students" ON public.students FOR ALL USING (
    public.has_role(auth.uid(), 'superadmin') OR public.has_role(auth.uid(), 'subadmin')
);

-- RLS Policies for schedules
CREATE POLICY "Teachers can view their own schedules" ON public.schedules FOR SELECT USING (
    teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Class teachers can view schedules for their classes" ON public.schedules FOR SELECT USING (
    class_id IN (SELECT id FROM public.classes WHERE class_teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
);
CREATE POLICY "Admins can manage schedules" ON public.schedules FOR ALL USING (
    public.has_role(auth.uid(), 'superadmin') OR public.has_role(auth.uid(), 'subadmin')
);

-- RLS Policies for QR codes
CREATE POLICY "Teachers can manage their QR codes" ON public.qr_codes FOR ALL USING (
    teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Students can view active QR codes for their classes" ON public.qr_codes FOR SELECT USING (
    is_active = true AND 
    schedule_id IN (
        SELECT s.id FROM public.schedules s
        JOIN public.students st ON st.class_id = s.class_id
        WHERE st.profile_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    )
);

-- RLS Policies for OTPs
CREATE POLICY "Students can manage their own OTPs" ON public.otps FOR ALL USING (
    student_id = (SELECT s.id FROM public.students s JOIN public.profiles p ON s.profile_id = p.id WHERE p.user_id = auth.uid())
);
CREATE POLICY "Teachers can view OTPs for their classes" ON public.otps FOR SELECT USING (
    qr_code_id IN (SELECT id FROM public.qr_codes WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
);

-- RLS Policies for attendance
CREATE POLICY "Students can view their own attendance" ON public.attendance FOR SELECT USING (
    student_id = (SELECT s.id FROM public.students s JOIN public.profiles p ON s.profile_id = p.id WHERE p.user_id = auth.uid())
);
CREATE POLICY "Students can mark their own attendance" ON public.attendance FOR INSERT WITH CHECK (
    student_id = (SELECT s.id FROM public.students s JOIN public.profiles p ON s.profile_id = p.id WHERE p.user_id = auth.uid())
);
CREATE POLICY "Teachers can view attendance for their classes" ON public.attendance FOR SELECT USING (
    schedule_id IN (SELECT id FROM public.schedules WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
);
CREATE POLICY "Admins can view all attendance" ON public.attendance FOR SELECT USING (
    public.has_role(auth.uid(), 'superadmin') OR public.has_role(auth.uid(), 'subadmin')
);

-- Create indexes for better performance
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_department_id ON public.profiles(department_id);
CREATE INDEX idx_classes_department_id ON public.classes(department_id);
CREATE INDEX idx_students_class_id ON public.students(class_id);
CREATE INDEX idx_schedules_class_id ON public.schedules(class_id);
CREATE INDEX idx_schedules_teacher_id ON public.schedules(teacher_id);
CREATE INDEX idx_attendance_student_id ON public.attendance(student_id);
CREATE INDEX idx_attendance_schedule_id ON public.attendance(schedule_id);
CREATE INDEX idx_qr_codes_valid_dates ON public.qr_codes(valid_from, valid_until);
CREATE INDEX idx_otps_expires_at ON public.otps(expires_at);