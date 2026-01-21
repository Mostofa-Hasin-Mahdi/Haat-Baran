-- Secure Function to Process App Payment (Bypass RLS)
create or replace function process_app_payment(
  p_donation_id uuid,
  p_applicant_id uuid,
  p_amount numeric
)
returns void
language plpgsql
security definer -- Runs with privileges of the creator (Admin), bypassing RLS
as $$
begin
  -- 1. Update Donation Status
  update donations
  set 
    status = 'COMPLETED',
    amount = p_amount,
    updated_at = now()
  where id = p_donation_id;

  update applicants
  set 
    current_funding = coalesce(current_funding, 0) + p_amount
  where id = p_applicant_id;

end;
$$;
