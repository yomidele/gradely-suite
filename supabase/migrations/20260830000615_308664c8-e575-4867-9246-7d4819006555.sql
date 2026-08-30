CREATE TABLE public.applicants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_number text NOT NULL UNIQUE DEFAULT ('APP-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  gender text,
  date_of_birth date,
  address text,
  state_of_origin text,
  qualification text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.applicants TO anon;
GRANT SELECT, INSERT, UPDATE ON public.applicants TO authenticated;
GRANT ALL ON public.applicants TO service_role;
ALTER TABLE public.applicants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can submit applicant details" ON public.applicants FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Super admins read applicants" ON public.applicants FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'super_admin'));
CREATE POLICY "Super admins update applicants" ON public.applicants FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'super_admin')) WITH CHECK (public.has_role(auth.uid(), 'super_admin'));
CREATE TRIGGER trg_applicants_updated BEFORE UPDATE ON public.applicants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id uuid NOT NULL REFERENCES public.applicants(id) ON DELETE CASCADE,
  programme_id uuid NOT NULL REFERENCES public.programmes(id),
  status text NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'admitted', 'rejected')),
  notes text,
  reviewed_by uuid REFERENCES auth.users(id),
  reviewed_at timestamptz,
  converted_student_id uuid REFERENCES public.students(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.applications TO anon;
GRANT SELECT, INSERT, UPDATE ON public.applications TO authenticated;
GRANT ALL ON public.applications TO service_role;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can submit applications" ON public.applications FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Super admins read applications" ON public.applications FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'super_admin'));
CREATE POLICY "Super admins update applications" ON public.applications FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'super_admin')) WITH CHECK (public.has_role(auth.uid(), 'super_admin'));
CREATE TRIGGER trg_applications_updated BEFORE UPDATE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE INDEX idx_applications_status ON public.applications(status);
CREATE INDEX idx_applications_applicant ON public.applications(applicant_id);

CREATE TABLE public.news_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  category text NOT NULL DEFAULT 'news' CHECK (category IN ('news', 'event', 'announcement')),
  excerpt text,
  content text NOT NULL,
  cover_image_url text,
  author_name text,
  is_published boolean NOT NULL DEFAULT false,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.news_posts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.news_posts TO authenticated;
GRANT ALL ON public.news_posts TO service_role;
ALTER TABLE public.news_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view published posts" ON public.news_posts FOR SELECT USING (is_published = true);
CREATE POLICY "Authenticated staff can view all posts" ON public.news_posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "Super admin manages posts" ON public.news_posts FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'super_admin')) WITH CHECK (public.has_role(auth.uid(), 'super_admin'));
CREATE TRIGGER trg_news_posts_updated BEFORE UPDATE ON public.news_posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE INDEX idx_news_posts_published ON public.news_posts (published_at DESC) WHERE is_published = true;