{
  inputs,
  config,
  lib,
  ...
}:

let
  version = (builtins.fromJSON (builtins.readFile "${inputs.superpowers}/package.json")).version;
  installPath = "${config.home.homeDirectory}/.claude/plugins/cache/claude-plugins-official/superpowers/${version}";
in
{
  home.file.".claude/plugins/cache/claude-plugins-official/superpowers/${version}".source =
    inputs.superpowers;

  home.activation.claudeSuperpowers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -s "${config.home.homeDirectory}/.claude/settings.json" ]; then
          install -Dm644 /dev/null "${config.home.homeDirectory}/.claude/settings.json"
          cat > "${config.home.homeDirectory}/.claude/settings.json" <<'EOF'
    {
      "extraKnownMarketplaces": {
        "superpowers-marketplace": {
          "source": { "source": "github", "repo": "obra/superpowers-marketplace" }
        }
      },
      "enabledPlugins": { "superpowers@claude-plugins-official": true }
    }
    EOF
        fi

        if [ ! -s "${config.home.homeDirectory}/.claude/plugins/installed_plugins.json" ]; then
          install -Dm644 /dev/null "${config.home.homeDirectory}/.claude/plugins/installed_plugins.json"
          cat > "${config.home.homeDirectory}/.claude/plugins/installed_plugins.json" <<EOF
    {
      "version": 2,
      "plugins": {
        "superpowers@claude-plugins-official": [{
          "scope": "user",
          "installPath": "${installPath}",
          "version": "${version}",
          "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
          "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
          "gitCommitSha": "${inputs.superpowers.rev}"
        }]
      }
    }
    EOF
        fi
  '';
}
