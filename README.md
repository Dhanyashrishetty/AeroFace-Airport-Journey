# AeroFace – Face-Based Seamless Airport Journey System

AeroFace is a web-based airport system that uses **face recognition** for a contactless passenger journey from **booking to boarding**.

Passengers register their face once while booking and paying. At the airport, they scan their face at each checkpoint. The system identifies the passenger, shows booking and flight details, updates journey status, and guides the next step.

---

## Features

### Booking & Registration
- Search flights by origin, destination, and date
- Route-based ticket pricing
- Passenger details form (domestic / international)
- Face capture with liveness checks
- Multi-step payment flow (UPI, GPay, PhonePe, Card, Net Banking UI)
- Ticket generation and booking confirmation

### Face Recognition Checkpoints
- Airport Entry
- Check-In (boarding pass issued)
- Bag Drop
- Security
- Immigration (international)
- Boarding Gate
- Boarded

At every checkpoint the system shows:
- Passenger details
- Flight details
- Current status
- Next step guidance

### Boarding Pass & Email
- Boarding pass PDF download after Check-In
- Payment receipt email
- Boarding pass email
- Email delivery via Resend (Supabase Edge Function)

### Admin Dashboard
- Passenger monitoring
- Flight list
- Journey logs
- Alerts
- Boarding pass email trigger

---

## Journey Flow

```text
Book Flight → Enter Details → Face Registration → Payment
        ↓
Airport Entry → Check-In → Bag Drop → Security
        ↓
Immigration (International only) → Gate → Boarded
