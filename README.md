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

The script reads the update server's manifest and writes the build number,
URLs and sha256 into `sources.json`.

`.github/workflows/update.yml` does this every hour (GitHub often runs it
later): it runs `update.sh`, checks the tarballs, mirrors them to the release
`<channel>-<build>` of this repo, builds the new pin, commits
`sources.json` if anything changed, and then deletes the older mirror releases
(griasdi doesn't work with older builds, so only the current pin is kept).

**Why the mirror:** the update server keeps only the newest build, and new
builds come out several times a day, so an upstream URL stops working as soon
as the build is replaced. Each pin lists the release mirror first and the
update server second. The griasdi license allows passing on unmodified copies
free of charge. If you run `update.sh` yourself without the workflow, the
mirror doesn't exist yet and the download falls back to the update server.
