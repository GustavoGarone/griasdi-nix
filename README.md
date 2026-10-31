# griasdi-nix

A Nix flake for [griasdi](https://griasdi.github.io/), end-to-end encrypted chat
and voice, on x86_64 and aarch64 Linux.

griasdi is proprietary, so this repackages the official Linux tarball
instead of building from source and runs it unmodified in an FHS environment
(`buildFHSEnv`).

## Try it

```sh
nix run github:GustavoGarone/griasdi-nix
```

## Install on NixOS

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

You don't need `allowUnfree`, because the flake allows griasdi and nothing else.
If you use `overlays.default` instead, your own nixpkgs has to allow it.

**The app doesn't update itself.** It sees that it's in the read-only store
  and leaves updates to the package.

## Updating

```sh
./update.sh        # newest build of the release channel, else dev
./update.sh dev    # a specific channel
```

The script reads the update server's manifest and writes the build number, URL
and sha256 into `sources.json`.

`.github/workflows/update.yml` does this every hour: it runs `update.sh`, builds
the new pin, and commits `sources.json` if anything changed.

**Note:** as of writing, the update server only keeps the newest build and
the one before it, and new builds come out often, so a pinned build stops
downloading soon after it's replaced. Machines that already have it in the
store keep working, but a fresh install fails with a 404 until `sources.json`
is updated.
