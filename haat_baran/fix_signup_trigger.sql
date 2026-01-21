-- Update the handle_new_user function to extract metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (user_id, email, username, phone, user_type)
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'phone',
    'DONOR'
  );
  
  -- Also create the donor record
  INSERT INTO public.donors (user_id)
  VALUES (new.id);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also, add a generic UPDATE policy for users to be able to edit their own profile later
CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = user_id);
