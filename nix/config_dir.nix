{ sources ? null
  , vars
}:
with builtins;

let
  deps = import ./deps.nix { inherit sources; };
  inherit (deps) pkgs;
  lib = pkgs.lib;

  backendConfig = scopedImport { inherit vars lib; } ./config.php.nix;
  backendConfigFile = pkgs.writeText "config.php" backendConfig;

  privateKeydir =
    if (!(isString vars.privateKeydir) && vars.copyPrivateKeysToStore == false) then
      throw ''
        privateKeydir cannot be a path (without quotes) when copyPrivateKeysToStore is not enabled!
        Paths are copied to the Nix store which may be a security risk!

        Use a string with double quotes as keydir and copyPrivateKeysToStore = false to link keys to the Nix store.
        This only works when Nix sandboxing is not enabled.

        If you really want to copy the keys to the Nix store, set copyPrivateKeysToStore = true.''
    else vars.privateKeydir;

  publicKeydir = vars.publicKeydir;

  permissionPublicKeyFiles = if (vars.publicKeydir == null) then [] else
    map (i: "${publicKeydir}/PermissionServer${toString i}.publickey.pem") (lib.range 1 (length vars.backendUrls));

  tallyPublicKeyFiles = if (vars.publicKeydir == null) then [] else
    map (i: "${publicKeydir}/TallyServer${toString i}.publickey.pem") vars.tallyServerNumbers;

  publicKeyFiles = permissionPublicKeyFiles ++ tallyPublicKeyFiles;

  varsForDebugOutput = removeAttrs vars ["__unfix__"];

in pkgs.runCommand "vvvote-backend-config" {} (''
  mkdir $out
  # linking doesn't work because PHP uses the location of the real file for __DIR__
  cp ${backendConfigFile} $out/config.php
  # not needed in production, but helpful for debugging
  ln -s ${pkgs.writeText "vars.json" (builtins.toJSON varsForDebugOutput)} $out/vars.json
''
+ lib.optionalString (vars.publicKeydir != null) ''
  key_dir=$out/voting-keys
  mkdir $key_dir
  # copy public server keys (optional: pass them as argument?)
  ${lib.concatMapStringsSep "\n" (k: "cp ${k} $key_dir") publicKeyFiles}
''
+ lib.optionalString (vars.privateKeydir != null) ''
  # link private keys
  ln -s ${privateKeydir}/PermissionServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
''
+ lib.optionalString (vars.privateKeydir != null && vars.isTallyServer) ''
  ln -s ${privateKeydir}/TallyServer${toString vars.serverNumber}.privatekey.pem.php $key_dir
'')