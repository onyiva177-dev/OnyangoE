# Evans Onyango — Portfolio + Blog System

## File structure

```
evans-blog/
├── index.html          ← Public portfolio + blog (deploy as root)
├── admin/
│   └── index.html      ← Admin panel (deploy as /admin/)
└── schema.sql          ← Run once in Supabase SQL Editor
```

---

## 1-time setup

### Step 1 — Run the SQL
1. Open **Supabase Dashboard → SQL Editor**
2. Paste the full contents of `schema.sql` and click **Run**
3. This creates all tables, RLS policies, and the `documents` storage bucket

### Step 2 — Create your admin user
1. Go to **Supabase Dashboard → Authentication → Users**
2. Click **Add User** → enter your email + a strong password
3. This is the only login that grants admin access

### Step 3 — Fill in credentials (2 places)

In **`index.html`** (line ~14):
```js
window.SB_URL  = 'https://YOUR-PROJECT.supabase.co';
window.SB_ANON = 'YOUR-ANON-KEY';
```

In **`admin/index.html`** (line ~8):
```js
window.SB_URL  = 'https://YOUR-PROJECT.supabase.co';
window.SB_ANON = 'YOUR-ANON-KEY';
```

Both values: **Supabase Dashboard → Settings → API**

### Step 4 — Deploy
Upload both files to any static host:
- **GitHub Pages** — put in `/docs` folder or root
- **Vercel / Netlify** — drop folder, auto-deploys
- **Shared hosting** — FTP upload

---

## Features

### Public site (`index.html`)
- Portfolio sections (hero, about, expertise, skills, philosophy, projects, contact)
- Live blog grid loaded from Supabase
- Post reader modal with rich content
- **Likes** — one per device, persisted to DB
- **Comments** — with moderation support
- **Ads** — between posts and top banner, with impression/click tracking
- **Share** — Twitter, WhatsApp, LinkedIn, copy link
- **All animations** controlled by site settings (speed, style, cursor, progress bar)

### Admin panel (`admin/index.html`)
| Section | Features |
|---|---|
| **Dashboard** | Post count, total views, total likes, ad CTR |
| **Posts** | Create, edit, publish/unpublish, delete; rich text editor; file attachments (any type); cover image; tags; category |
| **Media Library** | Upload any file, browse by type, copy link, delete |
| **Comments** | Approve, reject, delete; pending badge in sidebar |
| **Ads** | Create ads with title, body HTML, image, link, placement, position; track impressions + clicks; CTR calculation |
| **Settings** | Toggle: views, likes, comments, comment moderation, ads; animation speed (slow/normal/fast); reveal style (slide/fade/zoom/rotate); cursor effect, scroll progress bar, hero animation |

---

## Shared database with media site

This system uses the **same Supabase project** as your media site (`media-delta-inky.vercel.app`). The existing `posts`, `comments`, `likes`, `views`, and `media` bucket are untouched. The blog adds new tables (`blog_posts`, `blog_files`, `blog_comments`, `blog_likes`, `blog_ads`, `site_settings`) and a new `documents` bucket.

---

## Customising

**Contact details** — Edit `CONFIG` at the top of the `<script>` in `index.html`:
```js
const CONFIG = { whatsapp: '254110696552', email: 'onyiva177@gmail.com' };
```

**Portfolio content** — The `index.html` preserves the `data-ed` attributes and `localStorage` persistence from v2. Open the file in a browser and edit text directly (no admin login needed for portfolio text — this is intentional for offline edits).

**Animation style** — Change in Admin → Settings. Takes effect on next public page load.

**Adding ad placements** — In `index.html`, search for `getBetweenAds()` and `renderTopBanner()` to add new injection points.
