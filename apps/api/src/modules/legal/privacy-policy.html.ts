// The privacy policy is inlined as a template string rather than shipped as a
// static .html asset: the Vercel build only emits compiled JS, so a loose file
// would not be present at runtime.

export const PRIVACY_POLICY_LAST_UPDATED = '3 August 2026';

export const PRIVACY_POLICY_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy — SwarnaLekh</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 2.5rem 1.25rem 4rem;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.65;
    color: #1a1a1a;
    background: #ffffff;
  }
  main { max-width: 46rem; margin: 0 auto; }
  h1 { font-size: 1.9rem; margin: 0 0 .35rem; letter-spacing: -0.02em; }
  h2 { font-size: 1.15rem; margin: 2.25rem 0 .6rem; letter-spacing: -0.01em; }
  .meta { color: #666; font-size: .9rem; margin: 0 0 2rem; }
  ul { padding-left: 1.25rem; }
  li { margin: .3rem 0; }
  code { font-size: .9em; background: rgba(0,0,0,.06); padding: .1rem .35rem; border-radius: 4px; }
  a { color: #8a6d1f; }
  .note {
    border-left: 3px solid #c9a227;
    background: rgba(201,162,39,.08);
    padding: .85rem 1rem;
    border-radius: 0 6px 6px 0;
    margin: 1.25rem 0;
  }
  footer { margin-top: 3rem; padding-top: 1.25rem; border-top: 1px solid rgba(0,0,0,.1); color: #666; font-size: .9rem; }
  @media (prefers-color-scheme: dark) {
    body { background: #0f1216; color: #e6e6e6; }
    .meta, footer { color: #9aa0a6; }
    code { background: rgba(255,255,255,.1); }
    a { color: #d9b84a; }
    footer { border-top-color: rgba(255,255,255,.12); }
  }
</style>
</head>
<body>
<main>
  <h1>Privacy Policy</h1>
  <p class="meta">SwarnaLekh &middot; Last updated ${PRIVACY_POLICY_LAST_UPDATED}</p>

  <p>SwarnaLekh is business record-keeping software for jewellery shops. It lets a shop
  owner and their staff manage their own stock, billing, customer records and pledge/mortgage
  ledgers. It is not a lender, a marketplace, or a consumer finance service, and it does not
  offer credit to the public.</p>

  <p>This policy explains what the app stores, why, and how it is protected.</p>

  <h2>1. Who controls the data</h2>
  <p>SwarnaLekh is used by a registered shop. Two different roles matter here:</p>
  <ul>
    <li><strong>Your shop's own account data</strong> — you are our customer, and we handle this data as described below.</li>
    <li><strong>Records your shop enters about its customers</strong> — your shop decides what to
    collect and why. Your shop is responsible for that data; SwarnaLekh only stores and processes
    it on your shop's behalf, under your instructions.</li>
  </ul>

  <h2>2. What we collect</h2>
  <p><strong>Shop and account information</strong></p>
  <ul>
    <li>Shop name, owner name, address, city, state, pincode</li>
    <li>Phone number and email address</li>
    <li>GSTIN and PAN of the business, where you enter them</li>
    <li>Staff accounts: name, phone, email, role, and a one-way encrypted password hash</li>
    <li>Sign-in timestamps</li>
  </ul>

  <p><strong>Business records you create</strong></p>
  <ul>
    <li>Inventory items, weights, purity, tag numbers, HUID data and photographs of stock</li>
    <li>Invoices, payments, GST amounts and old-gold exchange entries</li>
    <li>Daily metal rates you set</li>
    <li>Pledge/mortgage loans: amounts, interest, top-ups, collections and pledged ornament details</li>
  </ul>

  <p><strong>Information your shop records about its own customers</strong></p>
  <ul>
    <li>Name, phone numbers, email and postal address</li>
    <li>Purchase and payment history</li>
    <li>Where your shop chooses to record them for KYC on a pledge loan: <strong>Aadhaar number,
    PAN number, identity document images and customer photographs</strong></li>
  </ul>

  <div class="note">
    <strong>About Aadhaar, PAN and identity documents.</strong> These fields are optional and exist
    only because Indian pledge-lending record-keeping commonly requires them. Enter them only where
    you are legally permitted to, only with your customer's consent, and only for as long as you
    need them. You remain responsible for how you use these identifiers. We never use them for any
    purpose of our own, never share them, and never use them to identify anyone across shops.
  </div>

  <p><strong>What we do not collect</strong></p>
  <ul>
    <li>No location data</li>
    <li>No contacts, call logs, SMS or device identifiers for advertising</li>
    <li>No advertising or third-party analytics trackers</li>
    <li>We do not sell data, and we do not share it for advertising</li>
  </ul>

  <h2>3. How the data is used</h2>
  <p>Strictly to run the service for your shop: signing you in, storing and showing your records,
  producing invoices, statements and reports, calculating interest and totals, and keeping backups
  so your books are not lost. We also use aggregate, non-identifying technical logs to keep the
  service running and to diagnose faults.</p>

  <h2>4. Where the data is stored and who processes it</h2>
  <p>Data is stored in a managed PostgreSQL database and transmitted over encrypted HTTPS
  connections. We use the following infrastructure providers, which process data only to host the
  service:</p>
  <ul>
    <li><strong>Supabase</strong> — database and authentication</li>
    <li><strong>Vercel</strong> — application server hosting</li>
  </ul>
  <p>We do not share your data with anyone else, except where we are legally required to by a valid
  order under applicable law.</p>

  <h2>5. Security</h2>
  <ul>
    <li>Passwords are stored only as one-way encrypted hashes and cannot be read by us or anyone else.</li>
    <li>Your sign-in session is kept in your device's secure hardware-backed storage, not in plain text.</li>
    <li>Every shop's records are isolated — no shop can read another shop's data.</li>
    <li>All traffic between the app and our servers is encrypted in transit.</li>
    <li>Access within the app is limited by role, so staff see only what their role permits.</li>
  </ul>
  <p>No system is perfectly secure, but we treat the data above as sensitive and design accordingly.</p>

  <h2>6. How long we keep it</h2>
  <p>We keep your records for as long as your shop's account is active, because they are your books
  and you need them. Deleted records may persist briefly in encrypted backups before being
  overwritten. If you close your account, we delete or irreversibly anonymise your data within
  90 days, except where a law requires us to retain specific records for longer.</p>

  <h2>7. Your rights and deleting your account</h2>
  <p>You can view and correct most of your data directly in the app at any time. You may also ask us
  to export your data, correct it, or delete your account and everything in it.</p>
  <p>To request deletion of your account and associated data, email us from the address registered to
  your shop with the subject <code>Delete my account</code>. We will confirm and complete the request
  within 30 days.</p>
  <p>If your shop recorded data about you as its customer and you want it removed, please contact
  that shop directly, as they control those records. If you cannot reach them, contact us and we
  will help.</p>

  <h2>8. Children</h2>
  <p>SwarnaLekh is a tool for running a business and is not directed at children. We do not knowingly
  collect data from anyone under 18.</p>

  <h2>9. Changes to this policy</h2>
  <p>If we change this policy we will update the date at the top of this page. Material changes will
  also be notified in the app.</p>

  <h2>10. Contact</h2>
  <p>Questions, requests or complaints about this policy or your data:
  <a href="mailto:jsatyam4@gmail.com">jsatyam4@gmail.com</a></p>

  <footer>
    SwarnaLekh &middot; Jewellery shop management software &middot; India
  </footer>
</main>
</body>
</html>`;
