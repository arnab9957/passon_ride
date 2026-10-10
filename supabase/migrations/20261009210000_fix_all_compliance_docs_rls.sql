-- Drop all existing policies on compliance_documents to ensure clean state
DROP POLICY IF EXISTS "Public select compliance documents" ON public.compliance_documents;
DROP POLICY IF EXISTS "Users can view their own compliance documents" ON public.compliance_documents;
DROP POLICY IF EXISTS "Admins can view all compliance documents" ON public.compliance_documents;
DROP POLICY IF EXISTS "Public insert compliance documents" ON public.compliance_documents;
DROP POLICY IF EXISTS "Public update compliance documents" ON public.compliance_documents;
DROP POLICY IF EXISTS "Public delete compliance documents" ON public.compliance_documents;

-- Recreate permissive policies for authenticated users
CREATE POLICY "Enable read access for all authenticated users" 
ON public.compliance_documents FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable insert access for all authenticated users" 
ON public.compliance_documents FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update access for all authenticated users" 
ON public.compliance_documents FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Enable delete access for all authenticated users" 
ON public.compliance_documents FOR DELETE TO authenticated USING (true);
