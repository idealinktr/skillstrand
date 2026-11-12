# Template pack delivery

1. A buyer pays through a Stripe Payment Link that has a required text field `github_username`.
2. Stripe sends `checkout.session.completed` (and `checkout.session.async_payment_succeeded` for delayed methods) to `https://skillstrand.com/api/stripe-webhook`.
3. `api/stripe-webhook.mjs` checks the `Stripe-Signature` header, reads the username, and calls
   `PUT /repos/idealinktr/skillstrand-pro/collaborators/{username}` with `permission: pull`.
4. The buyer lands on `/thanks.html` and accepts the GitHub invite.

## Environment variables (Vercel project `skillstrand`)

| Name | Required | What |
| --- | --- | --- |
| `STRIPE_WEBHOOK_SECRET` | yes | Signing secret of the webhook endpoint (`whsec_...`). Test and live endpoints have different secrets. |
| `GITHUB_INVITE_TOKEN` | yes | Fine-grained PAT, resource owner `idealinktr`, repository access: only `skillstrand-pro`, Repository permissions → Administration: Read and write. |
| `STRIPE_SECRET_KEY` | no | Restricted key, PaymentIntents: Read and write. Lets the function record the result in PaymentIntent metadata (`skillstrand_delivery`, `skillstrand_github`) and skip duplicates. |
| `SKILLSTRAND_PAYMENT_LINK_IDS` | no | Comma-separated `plink_` ids to accept. Other sessions are ignored. |
| `GITHUB_INVITE_REPO` | no | Defaults to `idealinktr/skillstrand-pro`. |

## Failure handling

- Missing env vars, a GitHub 401/403/429/5xx, or a network error return HTTP 500, so Stripe retries for up to 3 days.
- An invalid username or GitHub 404/422 returns 200 and logs `manual_delivery_needed` / `invite_result` at error level. Search the Vercel function logs for these and invite by hand.
- Repeat deliveries are safe: GitHub's add-collaborator call is idempotent, and with `STRIPE_SECRET_KEY` set the PaymentIntent metadata short-circuits retries.

## Tests

```
node --test tests/webhook/*.test.mjs
```
