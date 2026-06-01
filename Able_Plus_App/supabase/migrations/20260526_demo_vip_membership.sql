-- Able+ demo VIP membership (presentation mode)
-- This deliberately stores NO cardholder name, card number, expiry, CVV,
-- card brand, payment receipt, or demo-payment history. The Flutter form is visual-only.
-- The only persisted VIP information is the provider's active 30-day period.

begin;

create extension if not exists pgcrypto;

create table if not exists public.vip_subscriptions (
  id uuid primary key default gen_random_uuid(),
  tutor_id uuid references public.tutors(id) on delete cascade,
  business_id uuid references public.businesses(id) on delete cascade,
  charity_id uuid references public.charities(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'cancelled')),
  started_at timestamptz not null default now(),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vip_subscription_exactly_one_provider check (
    num_nonnulls(tutor_id, business_id, charity_id) = 1
  )
);

create unique index if not exists vip_subscriptions_one_tutor
  on public.vip_subscriptions (tutor_id) where tutor_id is not null;
create unique index if not exists vip_subscriptions_one_business
  on public.vip_subscriptions (business_id) where business_id is not null;
create unique index if not exists vip_subscriptions_one_charity
  on public.vip_subscriptions (charity_id) where charity_id is not null;
create index if not exists vip_subscriptions_active_expiry_idx
  on public.vip_subscriptions (expires_at desc) where status = 'active';

alter table public.vip_subscriptions enable row level security;

-- Subscription rows expose only provider identity and VIP expiry for badges/sorting.
drop policy if exists vip_subscriptions_authenticated_read on public.vip_subscriptions;
create policy vip_subscriptions_authenticated_read
  on public.vip_subscriptions for select
  to authenticated
  using (true);

-- No direct client insert/update/delete policy is granted. Activation happens only
-- through the guarded security-definer RPC below.

create or replace function public.activate_demo_vip()
returns table (subscription_id uuid, started_at timestamptz, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_viewer record;
  v_sub public.vip_subscriptions%rowtype;
  v_new_started timestamptz;
  v_new_expiry timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required to activate VIP.';
  end if;

  -- The app already depends on current_viewer() for logged-in account identity.
  select * into v_viewer from public.current_viewer() limit 1;
  if v_viewer is null or v_viewer.account_type not in ('tutor', 'business', 'charity') then
    raise exception 'VIP is available only for tutor, business, or charity accounts.';
  end if;

  if v_viewer.account_type = 'tutor' then
    select * into v_sub from public.vip_subscriptions where tutor_id = v_viewer.id for update;
  elsif v_viewer.account_type = 'business' then
    select * into v_sub from public.vip_subscriptions where business_id = v_viewer.id for update;
  else
    select * into v_sub from public.vip_subscriptions where charity_id = v_viewer.id for update;
  end if;

  v_new_started := case
    when v_sub.id is null or v_sub.expires_at <= now() or v_sub.status <> 'active' then now()
    else v_sub.started_at
  end;
  v_new_expiry := greatest(coalesce(v_sub.expires_at, now()), now()) + interval '30 days';

  if v_sub.id is null then
    insert into public.vip_subscriptions (tutor_id, business_id, charity_id, status, started_at, expires_at)
    values (
      case when v_viewer.account_type = 'tutor' then v_viewer.id else null end,
      case when v_viewer.account_type = 'business' then v_viewer.id else null end,
      case when v_viewer.account_type = 'charity' then v_viewer.id else null end,
      'active', v_new_started, v_new_expiry
    ) returning * into v_sub;
  else
    update public.vip_subscriptions
      set status = 'active', started_at = v_new_started,
          expires_at = v_new_expiry, updated_at = now()
      where id = v_sub.id
      returning * into v_sub;
  end if;

  return query select v_sub.id, v_sub.started_at, v_sub.expires_at;
end;
$$;

revoke all on function public.activate_demo_vip() from public;
grant execute on function public.activate_demo_vip() to authenticated;

comment on function public.activate_demo_vip() is
  'Activates/renews 30-day demo VIP; stores subscription timing only and no payment/card fields.';

commit;
