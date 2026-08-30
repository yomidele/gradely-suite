GRANT ALL ON public.result_pin_payments TO service_role;
GRANT ALL ON public.result_pins TO service_role;
GRANT ALL ON public.report_verifications TO service_role;

CREATE POLICY "No direct browser access to result pin payments"
  ON public.result_pin_payments
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY "No direct browser access to result pins"
  ON public.result_pins
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY "No direct browser access to report verifications"
  ON public.report_verifications
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);