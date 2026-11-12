// Pure helpers for the Skillstrand Pack delivery webhook.
// No third-party dependencies: Stripe signatures are checked with node:crypto.
import { createHmac, timingSafeEqual } from "node:crypto";

export const DEFAULT_TOLERANCE_SECONDS = 300;
export const GITHUB_FIELD_KEY = "github_username";

/**
 * Verify a Stripe-Signature header against the raw request body.
 * Returns { ok: true } or { ok: false, reason }.
 * See https://docs.stripe.com/webhooks#verify-manually
 */
export function verifyStripeSignature(rawBody, header, secret, {
  toleranceSeconds = DEFAULT_TOLERANCE_SECONDS,
  now = Math.floor(Date.now() / 1000),
} = {}) {
  if (!secret) return { ok: false, reason: "missing_secret" };
  if (!header || typeof header !== "string") return { ok: false, reason: "missing_header" };

  let timestamp = null;
  const signatures = [];
  for (const part of header.split(",")) {
    const idx = part.indexOf("=");
    if (idx === -1) continue;
    const key = part.slice(0, idx).trim();
    const value = part.slice(idx + 1).trim();
    if (key === "t") timestamp = Number(value);
    else if (key === "v1") signatures.push(value);
  }
  if (!Number.isFinite(timestamp)) return { ok: false, reason: "bad_timestamp" };
  if (signatures.length === 0) return { ok: false, reason: "no_v1_signature" };
  if (Math.abs(now - timestamp) > toleranceSeconds) return { ok: false, reason: "timestamp_outside_tolerance" };

  const expected = createHmac("sha256", secret).update(`${timestamp}.${rawBody}`, "utf8").digest("hex");
  const expectedBuf = Buffer.from(expected, "hex");
  const match = signatures.some((sig) => {
    if (!/^[0-9a-f]+$/i.test(sig)) return false;
    const sigBuf = Buffer.from(sig, "hex");
    return sigBuf.length === expectedBuf.length && timingSafeEqual(sigBuf, expectedBuf);
  });
  return match ? { ok: true } : { ok: false, reason: "signature_mismatch" };
}

/** Build a header the way Stripe does. Used by tests and local smoke checks. */
export function signStripePayload(rawBody, secret, timestamp = Math.floor(Date.now() / 1000)) {
  const sig = createHmac("sha256", secret).update(`${timestamp}.${rawBody}`, "utf8").digest("hex");
  return `t=${timestamp},v1=${sig}`;
}

const GITHUB_LOGIN = /^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$/;

/**
 * Normalize what a buyer typed into a GitHub login.
 * Accepts "octocat", "@octocat", "github.com/octocat", "https://github.com/octocat/".
 * Returns the login or null when it cannot be a valid GitHub username.
 */
export function normalizeGitHubUsername(input) {
  if (typeof input !== "string") return null;
  let value = input.trim();
  value = value.replace(/^https?:\/\//i, "").replace(/^(www\.)?github\.com\//i, "");
  value = value.replace(/^@/, "").replace(/\/+$/, "");
  if (value.includes("/")) return null;
  return GITHUB_LOGIN.test(value) ? value : null;
}

/** Read the GitHub username custom field from a Checkout Session object. */
export function readGitHubField(session, key = GITHUB_FIELD_KEY) {
  const fields = Array.isArray(session?.custom_fields) ? session.custom_fields : [];
  const field = fields.find((f) => f?.key === key);
  return field?.text?.value ?? null;
}

/**
 * Decide whether a Stripe event should produce an invite.
 * allowedPaymentLinks: optional list of plink_ ids; when non-empty, other links are ignored.
 */
export function planDelivery(event, { allowedPaymentLinks = [] } = {}) {
  const handled = ["checkout.session.completed", "checkout.session.async_payment_succeeded"];
  if (!event || !handled.includes(event.type)) return { action: "ignore", reason: "unhandled_event_type" };
  const session = event.data?.object;
  if (!session || session.object !== "checkout.session") return { action: "ignore", reason: "not_a_checkout_session" };
  if (allowedPaymentLinks.length > 0 && !allowedPaymentLinks.includes(session.payment_link)) {
    return { action: "ignore", reason: "other_payment_link" };
  }
  if (session.payment_status !== "paid" && session.payment_status !== "no_payment_required") {
    // async methods: wait for checkout.session.async_payment_succeeded
    return { action: "ignore", reason: `payment_status_${session.payment_status}` };
  }
  const raw = readGitHubField(session);
  const username = normalizeGitHubUsername(raw);
  if (!username) return { action: "manual", reason: "invalid_github_username", raw, sessionId: session.id };
  return { action: "invite", username, sessionId: session.id, paymentIntent: session.payment_intent ?? null };
}

/** Map a GitHub "add collaborator" response status to an outcome. */
export function interpretInviteStatus(status) {
  if (status === 201) return { outcome: "invited", retry: false };
  if (status === 204) return { outcome: "already_has_access", retry: false };
  if (status === 404) return { outcome: "user_or_repo_not_found", retry: false };
  if (status === 422) return { outcome: "rejected_by_github", retry: false };
  if (status === 401 || status === 403) return { outcome: "token_not_permitted", retry: true };
  return { outcome: "github_error", retry: status >= 500 || status === 429 };
}
