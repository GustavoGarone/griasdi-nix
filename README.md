# griasdi-nix

A Nix flake for [griasdi](https://griasdi.github.io/), end-to-end encrypted chat
and voice. griasdi is proprietary, so this repackages the official Linux tarball
(x86_64 and aarch64) without building from source. As per the license, the
binary is not patched: it runs unmodified in an FHS environment (`buildFHSEnv`),
similar to the way nixpkgs runs Discord.

## Use on NixOS

```nix
{
  inputs.griasdi.url = "github:GustavoGarone/griasdi-nix";

  outputs = { nixpkgs, griasdi, ... }: {
    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      modules = [
        griasdi.nixosModules.default
        { programs.griasdi.enable = true; }
      ];
    };
  };
}
```

You don't need `allowUnfree`: the flake allows only griasdi. If you use
`overlays.default` instead, your nixpkgs has to allow it.

Try it without installing: `nix run .#griasdi`.

Screen sharing on Wayland goes through xdg-desktop-portal, so enable
`xdg.portal` with a backend that supports screen capture (gnome, kde, wlr,
hyprland, ...).

Screen sharing fails on niri with `no more input formats`. griasdi only accepts
shared-memory frames, and niri only sends DMA-BUF, so the PipeWire format
negotiation fails. This might also happen on other compositors that only send
DMA-BUF, though I've not tested that. This is in griasdi, not in the packaging.

The app doesn't update itself here: it sees the read-only store and leaves
updates to the package.

## Updating

```sh
./update.sh        # newest build of the release channel, else dev
./update.sh dev    # a specific channel
```

The script writes the build, URL and sha256 from the server's manifest into
`sources.json`.

On GitHub, `.github/workflows/update.yml` does this every hour: it runs
`update.sh`, builds the new pin, and commits `sources.json` if it changed. It
can also be started by hand from the Actions tab.

**Caveat:** the update server keeps only the newest build and the one before
it, and new builds come out often. A pinned build stops downloading soon after
it's replaced. Machines that already have it in the store keep working, but a
fresh install fails with a 404 until you run `./update.sh`.
