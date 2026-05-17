# Features roadmap

Product vision: a cycle-aware wellness companion that combines tracking, community, and calm AI guidance—built for safety, sisterhood, and clarity.

---

## 1. Smart Mood & Emotion Tracking

**What to track**

- **Mood** — daily emotional check-ins with optional notes and tags.
- **Energy** — low / medium / high (or 1–10) to spot patterns across the cycle.
- **Stress** — quick intensity logs tied to context (work, sleep, social, health).
- **Sleep** — hours, quality, and disruptions; surface links to mood and symptoms.
- **Cravings** — food or habit cravings; optional macro tags (sweet, salty, comfort).
- **Anxiety & emotional patterns** — frequency, triggers, and physical correlates (tension, racing heart) for trend views.

**AI insight (example quote)**

> “You’ve logged lower energy and higher stress for three days mid-cycle, with sleep down about an hour. That often clusters around ovulation or high-stress weeks—not a judgment, just a pattern. If you want, we can try one small wind-down step tonight.”

---

## 2. Symptom Prediction

**Symptom focus**

- Cramps, headaches, acne, fatigue, ovulation-related discomfort, mood swings.

**Product behavior**

- Use cycle history, logged symptoms, mood, and sleep to surface **likely windows** for recurring symptoms (not medical diagnosis).
- Show **confidence as ranges** (“often in the few days before your period”) and let users correct predictions to improve the model.
- Optional **prep tips** (hydration, rest, heat pack reminders) tied to predicted symptom days.

---

## 3. AI Health Assistant — Dr. Najaat

**Tone**

- **Dr. Najaat** speaks with a **warm, calm, non-judgmental** voice: validating, clear, and careful not to shame choices or bodies.
- Default to **supportive education + general wellness**; escalate to “talk to a clinician” when red flags appear (see Emergency Wellness Check).
- Avoid cold clinical lecturing; prefer short paragraphs, one clear next step, and optional depth.

**Rewrite example**

- **Harsh / clinical (avoid):** “Your data shows non-compliance with sleep goals. You need to fix this.”
- **Dr. Najaat:** “Your sleep has been a bit shorter this week, and that can stack with stress and cramps. What’s one small thing that usually helps you rest—even 20 minutes earlier or a short wind-down? I’m here to brainstorm, not to scold.”

---

## 4. Emergency Wellness Check

**Example scenarios users might flag**

- Severe or sudden pelvic pain, pain with fever, or pain that doesn’t match their usual cramps.
- Very heavy bleeding (e.g., soaking through protection quickly), large clots, or bleeding when pregnant or unsure.
- **Mental wellness:** thoughts of self-harm, panic that won’t ease, feeling unsafe, or prolonged deep depression.

**In-product recommendations**

- **Immediate:** prominent **crisis lines and local emergency (e.g., 988 / emergency number)** plus encouragement to involve a trusted person when safe.
- **Clinical:** clear copy that **this is not a substitute for medical care** and when to seek **urgent** vs **routine** care.
- **Aftercare UX:** gentle follow-up prompts (journal, grounding exercise, trusted contact)—never blocking access to crisis resources behind paywalls.

---

## 5. Real Community (“Sisterhood”)

**Principles**

- **Sisterhood-first:** respect, anonymity options, anti-harassment norms, and moderators/community guidelines visible in onboarding.

**Features to support**

- **Friends** — connect with people you know or meet in groups.
- **Direct messages (DM)** — private conversations with blocking and reporting.
- **Voice notes** — async voice messages in DM or supported groups/circles.
- **Anonymous posting** — posts without displaying real name/profile where policy allows.
- **Group chats** — topic-based or invite-only spaces.
- **Wellness circles** — smaller, moderated peer-support rings (cycle, IVF journey, fitness, mental health adjacent to cycles, etc.).
- **Structured communities** — e.g., **campus** cohorts, **relationship** chats, **PCOS**, **pregnancy / TTC**, and other condition- or life-stage hubs.
- Discovery via **interest tags**, safe **icebreakers**, and **shared goals** (e.g., hydration challenge) without swapping medical data by default.

---

## 6. Anonymous Safe Space

- **Confession-style** and **question** threads where display names can be masked or pseudonymous.
- **Private support** flows: report content, hide users, limit DMs from non-friends, and optional **read-only** mode for sensitive days.
- Clear **community standards** and fast paths to **safety** tools; avoid algorithmic pressure to overshare.

---

## 7. Partner Mode

- **Share cycle info** with explicit opt-in: phase, approximate “high need for rest” days, or custom labels the user controls.
- Optional sharing of **moods** / **phase labels** (not raw journal unless user chooses).
- **Reminders optional** — partner can receive gentle prompts (“check in,” “bring water/snacks”) only if both sides consent.
- **Revocable access** — one-tap pause or revoke; audit of what exactly is visible.

---

## 8. Wellness Recommendations

**Approach**

- Phase-aware suggestions for **food**, **hydration**, **movement**, **breathwork / relaxation**, and **self-care rituals**.

**Examples**

- **Luteal phase:** prioritize **iron-rich** and **complex carb** snacks if fatigue/cravings spike; magnesium-friendly foods (*as general wellness*, not prescribing); emphasize **warmth**, **sleep hygiene**, and **lower-intensity workouts** when energy dips.
- **Ovulation:** highlight **balanced meals**, **steady hydration**, and **moderate cardio or strength** if energy is typically higher; invite **stress-downshifts** (walks, journaling) around mood volatility for those who track it.

Always frame as **optional** and **individualized by user preference**—not rigid rules.

---

## 9. Smart Notifications

**Examples (caring, not annoying)**

- “Hi—just a nudge if you’d like to log mood or energy today. Skip anytime.”
- “Your pattern often dips in sleep before cramps—want a reminder for an early wind-down?”
- “Partner Mode: gentle check-in day for [name] if you’ve both opted in.”
- “Hydration streak’s optional—tap when you drink a glass. No guilt if you mute us.”

**Design rules**

- **Frequency caps**, **quiet hours**, and **snooze presets** (“this week”) are first-class—not buried in settings.

---

## 10. Medical & Educational Section — “Glow Learn”

**Topic areas (illustrative)**

- Cycle basics: phases, hormones at a high level, what’s “common” vs “talk to a doctor.”
- Pain management: heat, movement, when to seek care.
- Skin, hair, and acne across the cycle (general education).
- Sleep, stress, and the cycle; **PMS / PMDD** awareness (no self-diagnosis).
- **PCOS**, **endometriosis**, **thyroid**—introductory, link-out to reputable sources.
- **Pregnancy / TTC** basics only where the product scope includes it; always separate from peer advice.
- **Nutrition myth-busting** and **exercise** across phases.
- **Mental health** resources and **body literacy** for teens and young adults.

Content should be **reviewed for medical accuracy** and **localized** where regulations require.

---

## UI/UX design direction

### Color palette

<!-- Legacy summary — canonical values live under “Design system: Soft Premium Minimalism”. -->

- **Primary:** soft coral or rose (warmth, energy without alarm).
- **Secondary:** sage or mist green (calm, growth).
- **Neutrals:** warm gray backgrounds, off-white cards (reduce clinical coldness).
- **Accents:** lavender or soft gold for highlights and success states.
- **Semantic:** reserved reds only for true warnings / crisis paths; avoid pink-washing every screen.

### UI style

- **Rounded cards**, generous **whitespace**, **large touch targets**, and **readable** type (16px+ body on mobile).
- **Illustrations or soft gradients** over stock “medical” imagery where possible.
- **Micro-celebrations** for logging (subtle, skippable) without gamifying pain.

### Avoid

- Shame language, streaks that punish missed days, comparing users to “average” bodies.
- Cluttered dashboards; burying **safety** and **privacy** under deep menus.
- Hyper-sexualized or infantilizing visuals for women’s health.

### Design system: Soft Premium Minimalism

Structured brief for product + engineering (Flutter + web tokens stay in sync).

1. **Look & feel** — Soft Premium Minimalism: airy layouts, floating cards, generous radius, subtle depth (elevation + soft shadow), calm motion only where it clarifies hierarchy.
2. **Core palette (hex)** — Main lavender `#B8A4FF`, lighter lavender `#C8B6FF`, cream background `#FFF9F5`, rose highlight `#F7C8D0`, deep plum text and primary buttons `#5B3B6F`, peach/coral accents and notifications `#FFB4A2`.
3. **Dark mode** — Soft dark purple scaffold (not pure black); cards as light lavender / elevated violet surfaces; primary controls may use subtle lavender → rose/peach gradients where the platform allows.
4. **Typography** — Prefer **Nunito** for body and **DM Sans** for titles/headings (acceptable alternates: Poppins, Inter). Keep hierarchy obvious without shouting.
5. **Primary navigation** — Five bottom tabs: **Home**, **Cycle**, **Community**, **AI Doctor**, **Profile**; Dr. Najaat lives under AI Doctor; Cycle is the main tracking hub (calendar + period).
6. **Home layout** — Greeting; cycle day + phase summary; mood/wellness summary; daily quote; “How I’m feeling today” quick chips; 2×2 card grid (cycle, mood, AI suggestions, water); lower **Highlights** band for stories/streaks/community teasers (MVP: placeholder).
7. **Buttons** — Rounded (stadium or ~16–20px radius), comfortable minimum tap size; key CTAs may use gradient wrappers (lavender → rose/peach).
8. **Cards** — Large corner radius, cream/white (light) or tinted lavender (dark) surfaces, restrained elevation.
9. **Motion** — Prefer implicit animations (`AnimatedSwitcher`, short `TweenAnimationBuilder`); optional gentle “breathing” scale on the Dr. Najaat avatar / sparkles entry point.
10. **Dr. Najaat** — Warm avatar-adjacent entry (sparkles, soft gradient halo); tone stays supportive and non-clinical in UI copy around the entry.
11. **Community aesthetic** — Approachable, sisterhood-forward cards; no Instagram-clone scope in MVP—shell and placeholders only until feed ships.
12. **Onboarding** — Four screens: welcome, cycle kindness, Dr. Najaat, sisterhood/safety; persist `onboarding_done` and never block returning users with repeats.
13. **Profile ideas** — Avatar, cycle prefs, Partner Mode entry, privacy/export, Glow Learn link, notification caps—grouped in calm list sections.
14. **Wellness quotes** — Short rotating lines (e.g. “Your body deserves kindness today.”) on Home for emotional regulation, not nagging.
15. **Streaks** — Opt-in, non-punitive framing; “we missed you” not “you broke a streak”; detailed rules TBD in Highlights / streak spec.
16. **Cycle metaphor** — Optional “cycle flower” / phase bloom for education and delight without infantilizing.
17. **Viral / shareable moment** — “How I’m feeling today” chips as lightweight, affirmative check-ins (optional share-out later); MVP = local log + snackbar + path to chat.
18. **Water & micro-habits** — Single-tap hydration nudges with local day counts; no backend requirement for first version.
19. **Accessibility** — Maintain contrast for plum on cream/peach; large labels for bottom nav; respect system text scaling.
20. **Web parity** — Mirror the same CSS custom properties for marketing/app shell consistency with Flutter.

### Suggested navigation

| Tab / area   | Role |
|-------------|------|
| **Home**    | Today’s snapshot, quick log, insights teaser. |
| **Cycle**   | Calendar, symptoms, mood, sleep, patterns. |
| **Community** | Feed, circles, DMs, discovery. |
| **AI Doctor** | Dr. Najaat chat, saved guidance, boundaries/reminders. |
| **Profile** | Settings, Partner Mode, privacy, Glow Learn entry, export/delete data. |

### Home screen ideas

- **“How are you today?”** one-tap mood + optional note.
- **Phase strip** or **cycle wheel** with plain-language label.
- **Next best action** (one card: log sleep, read one Glow Learn tip, join a circle).
- **AI Cycle Insights** teaser (see below) with link to full insight.

### Community UI mix

- **Tabs or segments:** For You / Circles / Campus (if enabled) / Anonymous.
- **Cards** with clear **report** … **menu**; **voice** attachment affordance in composer.
- **Onboarding** that sets **DM permissions** and **anonymous defaults** before first post.

### Safety features

- **Block, mute, report** on profiles, posts, and DMs.
- **Anti-harassment** policies, optional **keyword filters**, **minor safety** considerations if under-18 allowed.
- **Crisis resources** surfaced from Emergency Wellness Check flows and help menus.
- **Data minimization** for anonymous modes; **clear data export** and **account deletion**.

### “AI Cycle Insights” spotlight

- Short, **plain-language** summaries: “This month your energy dipped most in [window]; sleep and stress moved together.”
- **Transparent limits:** “Patterns, not predictions of disease.”
- **Action chips:** log more, read Glow Learn, talk to Dr. Najaat (non-clinical), or save for clinician visit.

### Branding & slogans (directional)

- **Brand feel:** trustworthy, warm, modern—**your body, your data, your pace**.
- **Example slogans (pick / iterate):**  
  - *Track gently. Live fully.*  
  - *Your cycle, your story, your sisterhood.*  
  - *Wellness that listens—Dr. Najaat and your community, on your terms.*  
  - *Glow Learn. Grow confident.*

---

## Shipping the app

- **Web —** From `glow_mobile`, run `flutter build web`. Static output is emitted to `build/web`; host those files behind **HTTPS**. Point the client at your API using a build define, for example `--dart-define=API_BASE_URL=https://api.example.com/api` (no trailing ambiguity: set the full REST prefix your `ApiService` expects). Typical flow: TLS reverse proxy → CDN or object storage → same-origin or CORS-permitted API backend.
- **Android (Play Store) —** Produce a signed release bundle: `flutter build appbundle`. In Play Console, create the app listing, attach the `.aab`, complete content rating / policy questions, then roll out tracks (internal testing first). Signing: create an **upload key** and let Play manage **App Signing** (recommended), or manage keys yourself via `keytool` and `flutter build appbundle`; **never commit keystore passwords or key files**.
- **iOS (App Store) —** `flutter build ios` then open `ios/Runner.xcworkspace` in Xcode. Set signing team/bundle ID, archive, upload to App Store Connect, configure metadata/screenshots/TestFlight. Apple requires provisioning profiles and Distribution certificates tied to your team (Apple Developer Program).
- **Windows (Microsoft Store) —** `flutter build windows` produces binaries under `build/windows/x64/runner/Release/` (adjust arch as needed). Publishing to consumers is commonly done via an **MSIX** package Partner Center submission (identity, screenshots, certifications). Use **`msix`** tooling or CI to package signing with a Partner Center-assigned publisher identity; storefront policies and reviewer notes still apply alongside standard Win32 readiness (installer, updater story).

---

*This document is a living roadmap: scope, compliance, and medical review should gate production features.*

---

## Pre-flight checklist (Glow Mobile + API today)

- **Server:** Copy `server/.env.example` → `server/.env`; set **`JWT_SECRET`**, optionally **`MONGO_URI`** (else in-memory).
- **Google (optional):** Set **`GOOGLE_CLIENT_ID`** (Web client ID on server). Flutter run/build: **`GOOGLE_SERVER_CLIENT_ID`** = same value.
- **LLM (optional):** Set **`OPENAI_API_KEY`** and/or **`GEMINI_API_KEY`** in `server/.env`; restart the API.
- **Flutter API URL:** Default `http://localhost:8081/api`; Android emulator:  
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api`
- **Physical device / LAN:** e.g. `--dart-define=API_BASE_URL=http://YOUR_PC_IP:8081/api`
- **Web production:** Build with HTTPS API URL: `--dart-define=API_BASE_URL=https://your.api.host/api`
- **Run server:** From `server/`, `npm start` (or your usual script) on port **8081** unless overridden.
- **Auth:** App uses **`x-auth-token`** on `/auth/profile`, `/chat`, `/tracking/*` after login or Google.
- **Without LLM keys:** Dr. Najaat chat still works via keyword snippets + gentle offline copy; with keys, live **`POST /api/chat`** replies.
