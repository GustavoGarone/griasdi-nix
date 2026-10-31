{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
}:

let
  sources = lib.importJSON ./sources.json;
  inherit (stdenvNoCC.hostPlatform) system;
  source = sources.${system} or (throw "griasdi: unsupported system ${system}");

  meta = {
    description = "End-to-end encrypted chat and voice for groups";
    homepage = "https://griasdi.github.io/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "griasdi";
  };

  # The license forbids modifying the program, so it is unpacked as published
  # (no patchelf, no strip) and runs in an FHS environment instead.
  unwrapped = stdenvNoCC.mkDerivation {
    pname = "griasdi-unwrapped";
    version = "${sources.version}-${sources.channel}.${toString sources.build}";

    src = fetchurl { inherit (source) url sha256; };

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;
    dontPatchShebangs = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/griasdi
      cp -a . $out/opt/griasdi
      runHook postInstall
    '';

    inherit meta;
  };
in
buildFHSEnv {
  pname = "griasdi";
  inherit (unwrapped) version;

  runScript = "${unwrapped}/opt/griasdi/bin/griasdi";

  targetPkgs =
    pkgs:
    (with pkgs; [
      stdenv.cc.cc.lib
      alsa-lib
      pipewire
      dbus
      fontconfig
      freetype
      libglvnd
      libgbm
      libdrm
      mesa
      vulkan-loader
      wayland
      libxkbcommon
      libx11
      libxcb
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
    ]);

  # The desktop entry runs `griasdi %u`, which also makes griasdi the handler
  # for griasdi: links.
  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${unwrapped}/opt/griasdi/share/{applications,icons,metainfo} $out/share/
  '';

  passthru = {
    inherit unwrapped;
    updateScript = ./update.sh;
  };

  inherit meta;
}
