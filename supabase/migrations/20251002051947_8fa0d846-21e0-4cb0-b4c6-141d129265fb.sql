-- Drop everything
DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.otps CASCADE;
DROP TABLE IF EXISTS public.qr_codes CASCADE;
DROP TABLE IF EXISTS public.schedules CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.classes CASCADE;
DROP TABLE IF EXISTS public.departments CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP FUNCTION IF EXISTS public.get_user_role(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.has_role(uuid, user_role) CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS attendance_status CASCADE;
DROP TYPE IF EXISTS day_of_week CASCADE;

-- Step 1: Create enum types
CREATE TYPE user_role AS ENUM ('student', 'subadmin', 'superadmin');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late');
CREATE TYPE day_of_week AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

-- Step 2: Create all tables
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE,
  email TEXT NOT NULL,
  username TEXT NOT NULL,
  role user_role NOT NULL,
  department_id UUID,
  working_time TEXT,
  roll_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE public.departments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE public.classes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  department_id UUID NOT NULL REFERENCES public.departments(id),
  class_teacher_id UUID,
  semester INTEGER,
  academic_year TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE public.students (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES public.profiles(id),
  roll_number TEXT NOT NULL,
  class_id UUID NOT NULL REFERENCES public.classes(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(profile_id)
);

CREATE TABLE public.schedules (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  class_id UUID NOT NULL REFERENCES public.classes(id),
  teacher_id UUID NOT NULL REFERENCES public.profiles(id),
  subject TEXT NOT NULL,
  day_of_week day_of_week NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE public.qr_codes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_id UUID NOT NULL REFERENCES public.schedules(id),
  teacher_id UUID NOT NULL REFERENCES public.profiles(id),
  code TEXT NOT NULL UNIQUE,
  valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE public.otps (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id UUID NOT NULL REFERENCES public.students(id),
  qr_code_id UUID NOT NULL REFERENCES public.qr_codes(id),
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE public.attendance (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_id UUID NOT NULL REFERENCES public.schedules(id),
  student_id UUID NOT NULL REFERENCES public.students(id),
  status attendance_status NOT NULL DEFAULT 'present',
  marked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  qr_code_id UUID REFERENCES public.qr_codes(id),
  otp_id UUID REFERENCES public.otps(id),
  notes TEXT
);

-- Step 3: Create functions (now that tables exist)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_user_role(user_uuid uuid)
RETURNS user_role
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE user_id = user_uuid;
$$;

CREATE OR REPLACE FUNCTION public.has_role(user_uuid uuid, required_role user_role)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = user_uuid AND role = required_role
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email, username, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'student'::user_role)
  );
  RETURN NEW;
END;
$$;

-- Step 4: Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Step 5: Add RLS policies
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Superadmins can manage all profiles" ON public.profiles
  FOR ALL USING (public.has_role(auth.uid(), 'superadmin'));

CREATE POLICY "Sub-admins can view profiles in their department" ON public.profiles
  FOR SELECT USING (
    public.has_role(auth.uid(), 'subadmin')
    AND department_id = (SELECT department_id FROM public.profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Other users can view departments" ON public.departments
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Superadmins can manage departments" ON public.departments
  FOR ALL USING (public.has_role(auth.uid(), 'superadmin'));

CREATE POLICY "Superadmins can manage all classes" ON public.classes
  FOR ALL USING (public.has_role(auth.uid(), 'superadmin'));

CREATE POLICY "Sub-admins can manage classes in their department" ON public.classes
  FOR ALL USING (
    public.has_role(auth.uid(), 'subadmin')
    AND department_id = (SELECT department_id FROM public.profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Teachers can view their assigned classes" ON public.classes
  FOR SELECT USING (
    class_teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    OR id IN (SELECT class_id FROM public.schedules WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
  );

CREATE POLICY "Students can view their own record" ON public.students
  FOR SELECT USING (profile_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage students" ON public.students
  FOR ALL USING (public.has_role(auth.uid(), 'superadmin') OR public.has_role(auth.uid(), 'subadmin'));

CREATE POLICY "Teachers can view students in their classes" ON public.students
  FOR SELECT USING (
    class_id IN (
      SELECT id FROM public.classes WHERE class_teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
      UNION
      SELECT class_id FROM public.schedules WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Teachers can view their own schedules" ON public.schedules
  FOR SELECT USING (teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can manage schedules" ON public.schedules
  FOR ALL USING (public.has_role(auth.uid(), 'superadmin') OR public.has_role(auth.uid(), 'subadmin'));

CREATE POLICY "Class teachers can view schedules for their classes" ON public.schedules
  FOR SELECT USING (
    class_id IN (SELECT id FROM public.classes WHERE class_teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
  );

CREATE POLICY "Teachers can manage their QR codes" ON public.qr_codes
  FOR ALL USING (teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

CREATE POLICY "Students can view active QR codes for their classes" ON public.qr_codes
  FOR SELECT USING (
    is_active = true
    AND schedule_id IN (
      SELECT s.id FROM public.schedules s
      JOIN public.students st ON st.class_id = s.class_id
      WHERE st.profile_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Students can manage their own OTPs" ON public.otps
  FOR ALL USING (
    student_id = (
      SELECT s.id FROM public.students s
      JOIN public.profiles p ON s.profile_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can view OTPs for their classes" ON public.otps
  FOR SELECT USING (
    qr_code_id IN (
      SELECT id FROM public.qr_codes WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Students can view their own attendance" ON public.attendance
  FOR SELECT USING (
    student_id = (
      SELECT s.id FROM public.students s
      JOIN public.profiles p ON s.profile_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

CREATE POLICY "Students can mark their own attendance" ON public.attendance
  FOR INSERT WITH CHECK (
    student_id = (
      SELECT s.id FROM public.students s
      JOIN public.profiles p ON s.profile_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all attendance" ON public.attendance
  FOR SELECT USING (public.has_role(auth.uid(), 'superadmin') OR public.has_role(auth.uid(), 'subadmin'));

CREATE POLICY "Teachers can view attendance for their classes" ON public.attendance
  FOR SELECT USING (
    schedule_id IN (SELECT id FROM public.schedules WHERE teacher_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
  );

-- Step 6: Add triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON public.departments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON public.classes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON public.schedules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();