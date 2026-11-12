import { test } from "node:test";
import assert from "node:assert/strict";
import {
  verifyStripeSignature, signStripePayload, normalizeGitHubUsername,
  planDelivery, interpretInviteStatus,
} from "../../api/_lib/delivery.mjs";

const SECRET = "whsec_test_only_not_a_real_secret";

const session = (overrides = {}) => ({
  id: "cs_test_123",
  object: "checkout.session",
  payment_status: "paid",
  payment_link: "plink_test",
  payment_intent: "pi_test_123",
  custom_fields: [{ key: "github_username", type: "text", text: { value: "octocat" } }],
  ...overrides,
});
const event = (obj, type = "checkout.session.completed") => ({ id: "evt_1", type, data: { object: obj } });

test("accepts a valid Stripe signature", () => {
  const body = JSON.stringify(event(session()));
  const header = signStripePayload(body, SECRET, 1_000_000);
  assert.deepEqual(verifyStripeSignature(body, header, SECRET, { now: 1_000_010 }), { ok: true });
});

test("rejects tampered body, wrong secret, stale timestamp, missing header", () => {
  const body = JSON.stringify(event(session()));
  const header = signStripePayload(body, SECRET, 1_000_000);
  assert.equal(verifyStripeSignature(body + " ", header, SECRET, { now: 1_000_000 }).reason, "signature_mismatch");
  assert.equal(verifyStripeSignature(body, header, "whsec_other", { now: 1_000_000 }).reason, "signature_mismatch");
  assert.equal(verifyStripeSignature(body, header, SECRET, { now: 1_000_000 + 301 }).reason, "timestamp_outside_tolerance");
  assert.equal(verifyStripeSignature(body, null, SECRET).reason, "missing_header");
  assert.equal(verifyStripeSignature(body, "t=1000000", SECRET, { now: 1_000_000 }).reason, "no_v1_signature");
});

test("accepts when any of several v1 signatures matches (secret rotation)", () => {
  const body = "{}";
  const good = signStripePayload(body, SECRET, 1_000_000).split(",")[1];
  const header = `t=1000000,v1=${"0".repeat(64)},${good}`;
  assert.equal(verifyStripeSignature(body, header, SECRET, { now: 1_000_000 }).ok, true);
});

test("normalizes GitHub usernames", () => {
  assert.equal(normalizeGitHubUsername("octocat"), "octocat");
  assert.equal(normalizeGitHubUsername("  @Octo-Cat "), "Octo-Cat");
  assert.equal(normalizeGitHubUsername("https://github.com/octocat/"), "octocat");
  assert.equal(normalizeGitHubUsername("github.com/octocat"), "octocat");
  assert.equal(normalizeGitHubUsername("-bad"), null);
  assert.equal(normalizeGitHubUsername("bad-"), null);
  assert.equal(normalizeGitHubUsername("a--b"), null);
  assert.equal(normalizeGitHubUsername("octocat/repo"), null);
  assert.equal(normalizeGitHubUsername("x".repeat(40)), null);
  assert.equal(normalizeGitHubUsername(""), null);
  assert.equal(normalizeGitHubUsername(undefined), null);
});

test("plans an invite for a paid session", () => {
  assert.deepEqual(planDelivery(event(session())), {
    action: "invite", username: "octocat", sessionId: "cs_test_123", paymentIntent: "pi_test_123",
  });
  assert.equal(planDelivery(event(session(), "checkout.session.async_payment_succeeded")).action, "invite");
});

test("ignores unpaid, other events and other payment links", () => {
  assert.equal(planDelivery(event(session({ payment_status: "unpaid" }))).action, "ignore");
  assert.equal(planDelivery(event(session(), "payment_intent.succeeded")).action, "ignore");
  assert.equal(planDelivery(event(session()), { allowedPaymentLinks: ["plink_other"] }).reason, "other_payment_link");
  assert.equal(planDelivery(event(session()), { allowedPaymentLinks: ["plink_test"] }).action, "invite");
});

test("flags invalid usernames for manual delivery", () => {
  const s = session({ custom_fields: [{ key: "github_username", text: { value: "not a user" } }] });
  assert.equal(planDelivery(event(s)).action, "manual");
  assert.equal(planDelivery(event(session({ custom_fields: [] }))).action, "manual");
});

test("maps GitHub statuses", () => {
  assert.deepEqual(interpretInviteStatus(201), { outcome: "invited", retry: false });
  assert.deepEqual(interpretInviteStatus(204), { outcome: "already_has_access", retry: false });
  assert.equal(interpretInviteStatus(404).retry, false);
  assert.equal(interpretInviteStatus(403).retry, true);
  assert.equal(interpretInviteStatus(502).retry, true);
});
