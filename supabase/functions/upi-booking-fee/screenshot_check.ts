// OCR + rule checks for a UPI payment screenshot.
// A screenshot can be edited, so passing these checks is strong evidence, not proof:
// anything doubtful is left for an admin to review.

export interface Check {
  key: string;
  label: string;
  ok: boolean;
  detail: string;
}

export interface ScreenshotReport {
  utr: string | null;
  checks: Check[];
  passed: boolean;
}

const MONTHS: Record<string, number> = {
  jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5, jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11,
};
const IST_MS = 5.5 * 60 * 60 * 1000;

/** Runs OCR.space (engine 2) on a base64 image and returns the plain text. */
export async function ocrImage(base64: string, mime: string, apiKey: string): Promise<string> {
  const form = new FormData();
  form.append('base64Image', `data:${mime};base64,${base64}`);
  form.append('OCREngine', '2');
  form.append('scale', 'true');
  form.append('language', 'eng');
  const res = await fetch('https://api.ocr.space/parse/image', {
    method: 'POST',
    headers: { apikey: apiKey },
    body: form,
  });
  const data = await res.json();
  if (data?.IsErroredOnProcessing) {
    const msg = Array.isArray(data.ErrorMessage) ? data.ErrorMessage.join(' ') : String(data.ErrorMessage ?? '');
    throw new Error(`OCR failed: ${msg}`);
  }
  return (data?.ParsedResults ?? []).map((r: { ParsedText?: string }) => r.ParsedText ?? '').join('\n');
}

export async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function norm(s: string): string {
  return s.toLowerCase().replace(/\s+/g, ' ').trim();
}

/** Prefers a 12-digit number labelled UTR / UPI Ref / Transaction ID; falls back to the only 12-digit number. */
export function extractUtr(text: string): string | null {
  const labelled = text.match(
    /(?:utr|upi\s*ref(?:erence)?(?:\s*(?:no|number|id))?|upi\s*transaction\s*id|transaction\s*id|ref(?:erence)?\s*(?:no|number))[\s.:#-]*((?:\d[\s-]?){12})(?!\d)/i,
  );
  if (labelled) return labelled[1].replace(/\D/g, '');
  const all = [...new Set((text.match(/(?<!\d)\d{12}(?!\d)/g) ?? []))];
  return all.length === 1 ? all[0] : null;
}

function istParts(d: Date) {
  const x = new Date(d.getTime() + IST_MS);
  return { y: x.getUTCFullYear(), m: x.getUTCMonth(), d: x.getUTCDate() };
}

/** All calendar dates (y, m, d) written in the text. */
function findDates(text: string): { y: number; m: number; d: number }[] {
  const out: { y: number; m: number; d: number }[] = [];
  const t = text.toLowerCase();
  const year = (y: string) => (y.length === 2 ? 2000 + Number(y) : Number(y));
  for (const m of t.matchAll(/(\d{1,2})(?:st|nd|rd|th)?[\s\-/,]*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s\-/,]*(\d{4}|\d{2})?/g)) {
    out.push({ d: Number(m[1]), m: MONTHS[m[2]], y: m[3] ? year(m[3]) : NaN });
  }
  for (const m of t.matchAll(/(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4})?/g)) {
    out.push({ d: Number(m[2]), m: MONTHS[m[1]], y: m[3] ? year(m[3]) : NaN });
  }
  for (const m of t.matchAll(/(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)/g)) {
    out.push({ d: Number(m[1]), m: Number(m[2]) - 1, y: year(m[3]) }); // Indian apps use dd/mm/yyyy
  }
  return out;
}

/** Minutes after IST midnight for each clock time in the text. */
function findTimes(text: string): number[] {
  const out: number[] = [];
  for (const m of text.toLowerCase().matchAll(/(?<!\d)(\d{1,2})[:.](\d{2})(?::\d{2})?\s*(am|pm)?(?![\d])/g)) {
    let h = Number(m[1]);
    const min = Number(m[2]);
    if (min > 59 || h > 23) continue;
    if (m[3] === 'pm' && h < 12) h += 12;
    if (m[3] === 'am' && h === 12) h = 0;
    if (!m[3] && h < 1) continue; // bare "0:xx" is usually noise
    out.push(h * 60 + min);
  }
  return out;
}

export function checkScreenshot(
  text: string,
  opts: { payeeName: string; payeeVpa: string; amount: number; createdAt: Date; now: Date },
): ScreenshotReport {
  const t = norm(text);
  const checks: Check[] = [];
  const add = (key: string, label: string, ok: boolean, detail: string) => checks.push({ key, label, ok, detail });

  // 1. Readable text at all
  add('readable', 'Screenshot is readable', t.length >= 40, t.length >= 40 ? 'Text extracted' : 'Too little text — upload a clear, uncropped screenshot');

  // 2. UTR
  const utr = extractUtr(text);
  add('utr', 'UTR / UPI reference found', !!utr, utr ? utr : 'No 12-digit UPI reference found');

  // 3. Payee: name or UPI ID
  const name = norm(opts.payeeName);
  const nameTokens = name.split(' ').filter(Boolean);
  const nameOk = t.includes(name) || nameTokens.every((tok) => t.includes(tok));
  const vpaOk = t.replace(/\s/g, '').includes(opts.payeeVpa.toLowerCase());
  add('payee', `Paid to ${opts.payeeName}`, nameOk || vpaOk,
    nameOk || vpaOk ? (vpaOk ? `UPI ID ${opts.payeeVpa} found` : 'Payee name found') : `Neither "${opts.payeeName}" nor ${opts.payeeVpa} appears`);

  // 4. Amount
  const amt = opts.amount.toFixed(0);
  const amountRe = new RegExp(`(?:₹|rs\\.?|inr|%|\\u20b9)\\s*${amt}(?:\\.00)?(?![\\d.])|(?:^|\\n)\\s*${amt}(?:\\.00)?\\s*(?:\\n|$)`, 'i');
  const amountOk = amountRe.test(text);
  add('amount', `Amount ₹${amt}`, amountOk, amountOk ? `₹${amt} found` : `₹${amt} not found on the screenshot`);

  // 5. Success status
  const successOk = /\b(success(ful(ly)?)?|completed|paid|payment done|money sent|sent)\b/.test(t);
  const failed = /\b(failed|failure|declined|pending|processing|cancelled)\b/.test(t);
  add('status', 'Payment successful', successOk && !failed,
    failed ? 'Screenshot shows a failed / pending payment' : successOk ? 'Marked successful' : 'No "Successful / Completed" status visible');

  // 6. Date = today (IST)
  const today = istParts(opts.now);
  const dates = findDates(text);
  const hasToday = dates.some((d) => d.d === today.d && d.m === today.m && (Number.isNaN(d.y) || d.y === today.y)) || /\btoday\b/.test(t);
  add('date', 'Paid today', hasToday,
    hasToday ? 'Date matches today' : dates.length ? 'Payment date is not today' : 'No payment date visible');

  // 7. Time: after this payment request was created, not in the future
  const startIst = istParts(opts.createdAt);
  const sameDay = startIst.d === today.d;
  const minutesOf = (d: Date) => {
    const x = new Date(d.getTime() + IST_MS);
    return x.getUTCHours() * 60 + x.getUTCMinutes();
  };
  const from = sameDay ? minutesOf(opts.createdAt) - 5 : 0; // 5 min grace for clock drift
  const to = minutesOf(opts.now) + 5;
  const times = findTimes(text);
  const timeOk = times.some((m) => m >= from && m <= to);
  add('time', 'Paid after booking was created', timeOk,
    timeOk ? 'Payment time is within the booking window' : times.length ? 'Payment time is before this booking or in the future' : 'No payment time visible');

  return { utr, checks, passed: checks.every((c) => c.ok) };
}
