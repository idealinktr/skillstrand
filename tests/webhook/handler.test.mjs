import { test, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import { POST } from "../../api/stripe-webhook.mjs";
import { signStripePayload } from "../../api/_lib/delivery.mjs";

const SECRET = "whsec_test_only_not_a_real_secret";
const realFetch = globalThis.fetch;
let calls;

function paidEvent(username = "octocat") {
  return {
    id: "evt_1", type: "checkout.session.completed",
    data: { object: {
      id: "cs_test_1", object: "checkout.session", payment_status: "paid",
      payment_link: "plink_test", payment_intent: "pi_test_1",
      custom_fields: [{ key: "github_username", text: { value: username } }],
    } },
  };
}
function req(body, secret = SECRET) {
  return new Request("https://example.test/api/stripe-webhook", {
    method: "POST", body, headers: { "stripe-signature": signStripePayload(body, secret) },
  });
}

beforeEach(() => {
  calls = [];
  process.env.STRIPE_WEBHOOK_SECRET = SECRET;
  process.env.GITHUB_INVITE_TOKEN = "github_pat_test_only";
  delete process.env.STRIPE_SECRET_KEY;
  delete process.env.SKILLSTRAND_PAYMENT_LINK_IDS;
  globalThis.fetch = async (url, init) => {
    calls.push({ url: String(url), init });
    return new Response(null, { status: 201 });
  };
});
afterEach(() => { globalThis.fetch = realFetch; });

test("invites the buyer with pull permission", async () => {
  const res = await POST(req(JSON.stringify(paidEvent())));
  assert.equal(res.status, 200);
  assert.equal((await res.json()).delivery, "invited");
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://api.github.com/repos/idealinktr/skillstrand-pro/collaborators/octocat");
  assert.equal(calls[0].init.method, "PUT");
  assert.deepEqual(JSON.parse(calls[0].init.body), { permission: "pull" });
});

test("rejects a bad signature without calling GitHub", async () => {
  const res = await POST(req(JSON.stringify(paidEvent()), "whsec_wrong"));
  assert.equal(res.status, 400);
  assert.equal(calls.length, 0);
});

test("returns 500 (Stripe retries) when not configured", async () => {
  delete process.env.GITHUB_INVITE_TOKEN;
  const res = await POST(req(JSON.stringify(paidEvent())));
  assert.equal(res.status, 500);
  assert.equal(calls.length, 0);
});

test("skips the invite when the PaymentIntent is already marked delivered", async () => {
  process.env.STRIPE_SECRET_KEY = "rk_test_only";
  globalThis.fetch = async (url, init) => {
    calls.push({ url: String(url), init });
    return new Response(JSON.stringify({ metadata: { skillstrand_delivery: "invited" } }), { status: 200 });
  };
  const res = await POST(req(JSON.stringify(paidEvent())));
  assert.equal((await res.json()).delivery, "already_delivered");
  assert.ok(calls.every((c) => !c.url.includes("api.github.com")));
});

test("invalid username is acknowledged for manual follow-up, no GitHub call", async () => {
  const res = await POST(req(JSON.stringify(paidEvent("not a user"))));
  assert.equal(res.status, 200);
  assert.equal((await res.json()).delivery, "manual");
  assert.equal(calls.length, 0);
});

test("token problems return 500 so Stripe retries", async () => {
  globalThis.fetch = async () => new Response(null, { status: 403 });
  const res = await POST(req(JSON.stringify(paidEvent())));
  assert.equal(res.status, 500);
});
