{ ... }:
{
  # システム側の Tor デーモン。Tor Browser 同梱の tor とは別に、
  # 任意のアプリから SOCKS5 (既定 127.0.0.1:9050) を使えるようにする。
  # DNS もプロキシ側で解決させるため、クライアントでは
  # curl --socks5-hostname 127.0.0.1:9050 ... のように hostname 解決を使う。
  services.tor = {
    enable = true;
    client.enable = true;
    # Tor 自体に SOCKS 経由の外向き接続は無い (入口ノードへの直結のみ)。
  };
}
