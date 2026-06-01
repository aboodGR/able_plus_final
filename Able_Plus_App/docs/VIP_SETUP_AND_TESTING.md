# Able+ Demo VIP Membership Setup and Testing

## What this implementation stores

The demo card form is UI-only. It does **not** send or save the cardholder name, card number, expiration value, CVV, brand, or a payment record. Supabase stores only the provider subscription row and its `started_at` / `expires_at` dates so VIP can stop automatically after 30 days and renew correctly.

## Database setup

1. Open the Supabase SQL Editor for the Able+ project.
2. Run `supabase/migrations/20260526_demo_vip_membership.sql`.
3. The migration assumes the existing tables use UUID primary keys (`tutors.id`, `businesses.id`, `charities.id`) and that the app's existing `current_viewer()` RPC returns `id` and `account_type` (`tutor`, `business`, `charity`, or `client`).
4. No card/payment table is created.

If the migration reports a type mismatch or a missing `current_viewer()` function, provide the output of these read-only queries so the migration can be adjusted precisely:

```sql
select table_name, column_name, data_type, udt_name
from information_schema.columns
where table_schema = 'public'
  and table_name in ('clients','tutors','businesses','charities','posts','profiles')
  and column_name in ('id','client_id','tutor_id','business_id','charity_id','auth_user_id','email');

select routine_name, routine_definition
from information_schema.routines
where specific_schema = 'public' and routine_name in ('current_viewer','user_profile');
```

## Demo flow test

Sign in as a `business`, `tutor`, or `charity`; open the drawer and choose **VIP Membership**. On the demo card page, values such as `abood`, `1324 1234`, `12/34`, and `1234` are accepted because no real payment validation runs. Tap **Pay 2 JOD (Demo)** and confirm the success page shows an expiry date about 30 days later. A renewal before expiry adds 30 days from the active expiry date.

A `client` must not see the drawer item and cannot activate the RPC.

## Create Post check

Create Post now resolves the logged-in role through the shared `current_viewer()` RPC, instead of waiting on four sequential email-table probes. If that RPC/schema is missing, an inline error with a retry button is shown rather than leaving the page loading. After creating a post, the feed providers are invalidated so a newly created VIP provider post is refreshed immediately.

## Verification checklist

- Provider drawer exposes VIP Membership; client drawer does not.
- Demo form clearly says no charge/card storage and accepts fake values.
- Error is visible within the payment page if SQL has not been applied.
- VIP post, business, tutor, and place cards receive the gold frame/badge while expiry is active.
- VIP content sorts ahead of non-VIP content; expired subscriptions do not appear VIP.
- No `vip_demo_payments` table exists and no payment/card data is sent by Flutter.
