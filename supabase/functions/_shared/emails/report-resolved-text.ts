export const reportResolvedText = String.raw`{{report_number}} is resolved
=======================

KAUNTI47 BETA

Your report is resolved

Hi {{first_name}}, the team marked your report as resolved.

  {{report_number}}  [Resolved]
  {{report_title}}
  {{category}} - Resolved {{resolved_date}}
{{#if team_reply}}
FROM THE TEAM
{{team_reply}}
{{/if}}
{{#if deep_link}}
See my reports:
{{reports_url}}
{{else}}
To see it, open the app and go to:
Profile > Beta feedback > My reports
{{/if}}

---

Thanks for sending it in. If anything else feels off, tell us the same way.

The Kaunti47 team

--
You received this because you applied for a Kaunti47 beta seat.
Questions? Reply to this email and it reaches the Kaunti47 team.
[Company or postal line: to be confirmed]
`
