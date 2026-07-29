# Plan — Mortgage redesign (26 July 2026)

From owner screenshots. Two requests, owner decisions captured.

## Order of work

- **A. Close-time interest choice** (Req 1) — first.
- **B. Detail/list visual redesign** (Req 2a) — from existing data.
- **C. Ledger + Statement PDF + Edit Loan** (Req 2b) — heavy, new backend.

## A · Close-time top-up interest choice

Move the merge/separate choice OUT of the global setting and INTO the Close Loan
screen, shown only when the loan has top-ups.

- [x] Remove the global "Top-up interest policy" settings sheet + tune icon +
      repo get/set. Ongoing list/detail figures default to **Separate**.
- [x] `closeLoan` accepts `topupInterestMode` ("separate" | "merge") and uses it
      for the settlement calc.
- [x] `GET /mortgages/:id/close-preview` → figures under BOTH modes (pending
      interest, outstanding, total payable) + loanDate, first top-up date, total.
- [x] Close Loan screen: when the loan has top-ups, show two option cards
      — **From Original Loan Date** (merge, recommended) / **From Top-up Date**
      (separate) — with a live preview; send the chosen mode. Plain close otherwise.

## B · Mortgage detail/list redesign (existing data)

- [x] Full-page detail (replace bottom sheet): Loan Overview, Loan Details.
- [x] Top-up History section (loan.topups).
- [x] Gold Details section (ornaments) + Payment History (receipt/edit preserved).
- [x] Call / WhatsApp buttons (url_launcher).
- [x] 3-dot context menu on list cards (View Details, Collect, Top-up, Close, Reopen).
- [x] "DUE IN N days" / overdue badge + avatar. (Header edit/print icons come with C.)

## C · Heavy new pieces

- [ ] Loan Ledger: chronological events (created, top-up added, interest/principal
      collected, closed) assembled from loan + payments + topups; View Full Ledger.
- [ ] Print / Share Statement: a loan statement PDF (details + ledger).
- [ ] Edit Loan: new `PUT /mortgages/:id` update endpoint + form.

## Decisions (owner, 26 Jul)

1. Remove the global top-up setting; choose only at close. Ongoing display = Separate. ✓
2. Sequence: Req 1 first, then redesign in two waves (B then C). ✓
3. All three heavy pieces (Ledger, Statement PDF, Edit Loan) are in scope. ✓
