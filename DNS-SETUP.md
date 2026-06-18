# cigmas.org — final step (DNS)

The site is **live and verified** on GitHub Pages and the custom domain
`cigmas.org` is already configured on the host. The only remaining step is
pointing the domain's DNS (at **Porkbun**) to GitHub. That step needs the
Porkbun account, which is why it isn't already done.

- **Repo / host:** https://github.com/gamesforloveorg/cigmas-site
- **Pages status:** built ✓ · custom domain `cigmas.org` set ✓
- **Pages URL (redirects to cigmas.org once DNS is live):** https://gamesforloveorg.github.io/cigmas-site/

## Option A — run the script (fastest)

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-dns.ps1 -ApiKey "pk1_xxx" -SecretKey "sk1_xxx"
```

Get the keys: Porkbun → Account → **API Access** (creates `pk1_…` + `sk1_…`),
then Domain Management → cigmas.org → **Details** → toggle **API Access ON**,
and turn **URL Forwarding OFF** for the domain.

## Option B — do it by hand in the Porkbun dashboard (~2 min)

In Porkbun → cigmas.org → **DNS Records**:

1. **Turn OFF URL Forwarding** (this is what currently sends `www` →
   `pixie.porkbun.com` and parks the domain).
2. **Delete** the existing apex `A`/`ALIAS` records (the `44.227.x.x` parking IPs).
3. **Add** these records:

| Type  | Host (Name) | Answer / Content              | TTL |
|-------|-------------|-------------------------------|-----|
| A     | (blank / @) | `185.199.108.153`             | 600 |
| A     | (blank / @) | `185.199.109.153`             | 600 |
| A     | (blank / @) | `185.199.110.153`             | 600 |
| A     | (blank / @) | `185.199.111.153`             | 600 |
| CNAME | `www`       | `gamesforloveorg.github.io`   | 600 |

Leave any MX / TXT records alone (there currently are none).

## After DNS is set

- Propagation is usually minutes (up to ~1 hour).
- GitHub auto-issues the HTTPS certificate once DNS resolves; then you can
  enable **Enforce HTTPS** in the repo's Settings → Pages.
- Verify: https://cigmas.org and https://www.cigmas.org should load the site.

---

## What's deployed

Static, fully self-contained pages (no build step, no external dependencies):

| File | Purpose |
|------|---------|
| `index.html` / `CIGMAs-Home.html` | Home |
| `CIGMAs-Categories.html` · `categories.html` | Categories |
| `CIGMAs-FAQ.html` · `faq.html` | FAQ |
| `CIGMAs-Sponsor.html` · `sponsor.html` | Sponsor |
| `CIGMAs-Apply.html` · `apply.html` | Apply / Submit |

Both filename forms are included because the pages link to each other using
both forms, and GitHub Pages is case-sensitive.

To update the site later: replace the HTML files, then `git commit` and
`git push`. GitHub Pages redeploys automatically.
