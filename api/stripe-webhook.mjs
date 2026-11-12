// Vercel Function: Stripe webhook -> GitHub invite to the private Skillstrand Pack repo.
//
// Env vars (set on the Vercel project, never in the repo):
//   STRIPE_WEBHOOK_SECRET         required. Signing secret (whsec_...) of the Stripe webhook endpoint.
//   GITHUB_INVITE_TOKEN           required. Fine-grained PAT: repo idealinktr/skillstrand-pro only,
//                                 Repository permissions -> Administration: Read and write.
//   GITHUB_INVITE_REPO            optional. Defaults to idealinktr/skillstrand-pro.
//   STRIPE_SECRET_KEY             optional. Restricted key with PaymentIntents: Read and write. When set,
//                                 the delivery result is written to the PaymentIntent metadata so retries
//                                 are skipped and support can see what happened in the Dashboard.
//   SKILLSTRAND_PAYMENT_LINK_IDS  optional. Comma-separated plink_ ids. When set, sessions from other
//                                 payment links are ignored.
import { verifyStripeSignature, planDelivery, interpretInviteStatus } from "./_lib/delivery.mjs";

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

function log(level, msg, extra = {}) {
  // Vercel captures stdout/stderr in the function logs. Never log secrets.
  const line = JSON.stringify({ level, msg, ...extra, at: new Date().toISOString() });
  if (level === "error") console.error(line);
  else console.log(line);
}

async function stripeRequest(method, path, params) {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) return null;
  const body = params ? new URLSearchParams(params).toString() : undefined;
  const res = await fetch(`https://api.stripe.com/v1/${path}`, {
    method,
    headers: {
      authorization: `Bearer ${key}`,
      ...(body ? { "content-type": "application/x-www-form-urlencoded" } : {}),
    },
    body,
  });
  if (!res.ok) {
    log("error", "stripe_api_error", { path, status: res.status });
    return null;
  }
  return res.json();
}

async function alreadyDelivered(paymentIntentId) {
  if (!paymentIntentId) return false;
  const pi = await stripeRequest("GET", `payment_intents/${encodeURIComponent(paymentIntentId)}`);
  const status = pi?.metadata?.skillstrand_delivery;
  return status === "invited" || status === "already_has_access";
}

async function recordDelivery(paymentIntentId, outcome, username) {
  if (!paymentIntentId) return;
  await stripeRequest("POST", `payment_intents/${encodeURIComponent(paymentIntentId)}`, {
    "metadata[skillstrand_delivery]": outcome,
    "metadata[skillstrand_github]": username ?? "",
  });
}

async function inviteCollaborator(username) {
  const repo = process.env.GITHUB_INVITE_REPO || "idealinktr/skillstrand-pro";
  const res = await fetch(`https://api.github.com/repos/${repo}/collaborators/${encodeURIComponent(username)}`, {
    method: "PUT",
    headers: {
      authorization: `Bearer ${process.env.GITHUB_INVITE_TOKEN}`,
      accept: "application/vnd.github+json",
      "x-github-api-version": "2022-11-28",
      "content-type": "application/json",
      "user-agent": "skillstrand-delivery",
    },
    body: JSON.stringify({ permission: "pull" }),
  });
  return { status: res.status, ...interpretInviteStatus(res.status) };
}

export function GET() {
  return json(405, { error: "POST only" });
}

export async function POST(request) {
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret || !process.env.GITHUB_INVITE_TOKEN) {
    log("error", "delivery_not_configured", {
      hasWebhookSecret: Boolean(secret),
      hasGitHubToken: Boolean(process.env.GITHUB_INVITE_TOKEN),
    });
    // 500 makes Stripe retry for up to 3 days, so nothing is lost while env vars are being set.
    return json(500, { error: "not_configured" });
  }

  const raw = await request.text();
  const check = verifyStripeSignature(raw, request.headers.get("stripe-signature"), secret);
  if (!check.ok) {
    log("error", "bad_signature", { reason: check.reason });
    return json(400, { error: "bad_signature" });
  }

  let event;
  try {
    event = JSON.parse(raw);
  } catch {
    return json(400, { error: "bad_json" });
  }

  const allowedPaymentLinks = (process.env.SKILLSTRAND_PAYMENT_LINK_IDS || "")
    .split(",").map((s) => s.trim()).filter(Boolean);
  const plan = planDelivery(event, { allowedPaymentLinks });

  if (plan.action === "ignore") {
    log("info", "event_ignored", { eventId: event.id, type: event.type, reason: plan.reason });
    return json(200, { received: true, ignored: plan.reason });
  }
  if (plan.action === "manual") {
    log("error", "manual_delivery_needed", { eventId: event.id, sessionId: plan.sessionId, reason: plan.reason });
    await recordDelivery(event.data.object.payment_intent, "invalid_github_username", null);
    return json(200, { received: true, delivery: "manual" });
  }

  if (await alreadyDelivered(plan.paymentIntent)) {
    log("info", "already_delivered", { eventId: event.id, sessionId: plan.sessionId });
    return json(200, { received: true, delivery: "already_delivered" });
  }

  let result;
  try {
    result = await inviteCollaborator(plan.username);
  } catch (err) {
    log("error", "github_request_failed", { eventId: event.id, sessionId: plan.sessionId, message: String(err?.message || err) });
    return json(500, { error: "github_unreachable" });
  }

  const level = result.outcome === "invited" || result.outcome === "already_has_access" ? "info" : "error";
  log(level, "invite_result", {
    eventId: event.id, sessionId: plan.sessionId, username: plan.username,
    status: result.status, outcome: result.outcome,
  });
  await recordDelivery(plan.paymentIntent, result.outcome, plan.username);

  if (result.retry) return json(500, { error: result.outcome });
  return json(200, { received: true, delivery: result.outcome });
}
