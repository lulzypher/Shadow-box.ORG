import { defineConfig } from "vite";

const port = Number(process.env.SHADOW_BOX_PORT || 8844) || 8844;

/**
 * Cloudflare Tunnel forwards the public Host (e.g. shadow-box.org). Vite's default
 * host check blocks that unless allowed. `true` turns the check off for this server
 * (still only listening on 127.0.0.1, so only your tunnel/local reach it).
 */
const allowTunnelHosts = true;

export default defineConfig({
  server: {
    port,
    strictPort: false,
    host: "127.0.0.1",
    allowedHosts: allowTunnelHosts,
  },
  preview: {
    port,
    strictPort: false,
    host: "127.0.0.1",
    allowedHosts: allowTunnelHosts,
  },
});
