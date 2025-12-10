{
  nix2container,
  arch,
  dockerTools,
  lib,
  buildEnv,
  runCommand,
  webhook,

  busybox,
  nodejs,
  gitMinimal, 

  port ? 3000,
# defaults are specific to my use case
  extraPackages ? [ busybox nodejs gitMinimal ],
  extraFiles ? [ ./rebuild.sh ],
  hooksFile ? ./hooks.json,
  ...
}: nix2container.buildImage {
  name = "bvngee/webhook";
  inherit arch;
  tag = "latest";
  created = "now";
  maxLayers = 125;
  copyToRoot = [
    dockerTools.caCertificates
    dockerTools.usrBinEnv
    (buildEnv {
      name = "image-root";
      paths = [ webhook ] ++ extraPackages;
      pathsToLink = [ "/bin" ];
    })
    (runCommand "extraFiles" { } ''
      mkdir -p $out/root
      ${lib.concatStringsSep "\n" (map (f: "cp -r ${f} $out/root/${baseNameOf f}") extraFiles)}
    '')
  ];
  config = {
    WorkingDir = "/root";
    Cmd = [
      ../../util/run_with_secrets.sh
      "WEBHOOK_SECRET"
      "\\"
      ./start.sh
      (toString port)
      hooksFile 
    ];
    Volumes."/website-static" = { };
    ExportedPorts."${toString port}/tcp" = {};
  };
}
