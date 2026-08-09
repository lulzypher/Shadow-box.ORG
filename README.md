# shadow-box.org

Hub for little projects. Each app lives in its own repo, then gets built into `public/apps/<slug>/` and listed in `public/projects.json`.

## URLs

| Path | App |
|------|-----|
| `/` | Hub directory |
| `/apps/ship/` | PrintParcel (bambu-ship-kit) |
| `/apps/printers/` | 3D Printer Build lab (voron-trident-350-configurator) |
| `/apps/manufacturing/` | Manufacturing Map (manufacturing-map) — filament → feedstock → periodic table |
| `/apps/dns/` | ROOT ZONE (dns-root-map) |
| `/apps/skills/` | 3dEST Skill Tree (3dExhaustiveSkillTree) |
| `/apps/fluke/` | Pi hosts/Tailscale helper |
| `/fluke/` | Legacy alias of Fluke helper |
| `/apps/cult-of-saturn/` | Cult of Saturn / FalseProphet field guide |

## Add a project

1. Build it with Vite `base: '/apps/<slug>/'` (or `BASE_PATH` env).
2. Add a row to `public/projects.json`.
3. Add an entry to `scripts/sync-apps.ps1` `$Catalog`.
4. Run:

```bash
npm run sync-apps
npm run build
npm run serve
```

Public site is served on port **8844** behind the Cloudflare tunnel.
