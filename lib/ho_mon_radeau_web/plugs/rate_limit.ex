defmodule HoMonRadeauWeb.Plugs.RateLimit do
  use PlugAttack

  # 5 registration attempts per IP per 10 minutes
  rule "registration by ip", conn do
    if conn.method == "POST" and conn.request_path == "/users/register" do
      throttle(conn.remote_ip,
        period: 10 * 60_000,
        limit: 5,
        storage: {PlugAttack.Storage.Ets, HoMonRadeauWeb.RateLimitStorage}
      )
    end
  end

  # 10 login attempts per IP per minute
  rule "login by ip", conn do
    if conn.method == "POST" and conn.request_path == "/users/log-in" do
      throttle(conn.remote_ip,
        period: 60_000,
        limit: 10,
        storage: {PlugAttack.Storage.Ets, HoMonRadeauWeb.RateLimitStorage}
      )
    end
  end

  # 300 API requests per IP per minute - generous enough for normal/MCP usage,
  # low enough to blunt token brute-forcing or runaway scripts.
  rule "api by ip", conn do
    if String.starts_with?(conn.request_path, "/api") do
      throttle(conn.remote_ip,
        period: 60_000,
        limit: 300,
        storage: {PlugAttack.Storage.Ets, HoMonRadeauWeb.RateLimitStorage}
      )
    end
  end
end
