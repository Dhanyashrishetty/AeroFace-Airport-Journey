# AeroFace — Real email setup (payment receipt + boarding pass)

Emails are sent to the **passenger’s registered email**.

## What is sent
1. **After payment** — Payment receipt + booking confirmation  
2. **Boarding pass** — From Check-In (or later) “Email Boarding Pass”, and from Admin  

## Delivery (two paths)

### A) FormSubmit (works without API keys — default fallback)
- Used automatically from the browser if Resend is not configured  
- **First email** to a new address: FormSubmit sends an **activation link** — open inbox/spam and click **Confirm** once  
- After that, receipts and boarding passes arrive normally  

### B) Resend (recommended for production)
1. Create a free account at https://resend.com  
2. Create an API key  
3. Supabase Dashboard → **Edge Functions** → `send-boarding-pass` → **Secrets**  
4. Add:
   - `RESEND_API_KEY` = your key  
   - `RESEND_FROM_EMAIL` = `AeroFace <onboarding@resend.dev>` (or your verified domain)  
5. Redeploy the `send-boarding-pass` function  

## Deploy edge function
```bash
supabase functions deploy send-boarding-pass
```

Without Resend, FormSubmit still delivers after the one-time confirmation.
