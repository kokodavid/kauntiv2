export const seatInviteText = String.raw`Your seat is ready
==================

KAUNTI47 BETA

You've been selected to test Kaunti47.

Your seat: {{seat_number}} ({{seat_roman}}) of 47, on {{platform_name}}.
{{#if show_premium}}
Your seat comes with Lifetime Premium, free.
{{/if}}

INSTALL IN THREE STEPS
{{#if is_android}}
1. Open the link below in Chrome, signed in to Google with {{tester_email}}.
2. Accept the invite on that page.
3. Tap "Download test app". It opens Google Play, which should also be signed in with {{tester_email}}. Then install.
{{else}}
1. Install Apple TestFlight from the App Store if you do not have it.
2. Open the link below on your iPhone.
3. Accept the Kaunti47 invitation in TestFlight, then install the app.
{{/if}}

Open Kaunti47 beta access:
{{install_url}}
{{#if is_android}}
Hint: Not seeing the Download test app button? You're probably signed in with a different Google account. Open the link again in Chrome with {{tester_email}}, or switch accounts in the Play Store app.
{{/if}}
Sign in with {{tester_email}}. Use the same email you applied with. Your seat is matched to it.

---

WHAT YOUR SEAT MEANS

You're one of the first 47 people testing Kaunti47, and we want you to help shape what we build. Your feedback comes first, and you get new features before the app goes public. While you hold your seat, premium is free for you, including anything new we add. If you're not using the app, your seat may go to someone on the waiting list.

---

SENDING FEEDBACK

In the app, go to Profile > Beta feedback. Pick what it is about and how bad it is, say what happened in your own words, and add a screenshot if you can.

You get a report number, like FB-0042, and can follow it under My reports. A rough report is fine.

---

WHAT WE ASK

- Use the app the way you normally would.
- Tell us what feels wrong or confusing, in your own words. You do not have to be technical.
- Share Kaunti47 freely: screenshots, what you are seeing, what you think. Friends can join the waiting list at kaunti47.com. Your install link is tied to your seat, so point them there instead.
- We read every report. We cannot promise a reply or a fix for each one.

---

Need help? Email hello@kaunti47.com and the Kaunti47 team will help you get set up. Please write to that address, not to the one this email came from.

The Kaunti47 team

--
You received this because you applied for a Kaunti47 beta seat.
Questions? Email hello@kaunti47.com.
[Company or postal line: to be confirmed]
`
