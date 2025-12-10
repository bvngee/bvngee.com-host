{
  nix2container,
  arch,
  lib,
  dockerTools,
  callPackage,
  buildEnv,

  # note: this could use nodejs slim but then but then it wouldn't
  # be shared as a layer with my other containers that need full nodejs
  nodejs,
  busybox,

  port ? 9000,
  ...
}: nix2container.buildImage {
  name = "bvngee/github-readme-stats";
  inherit arch;
  tag = "latest";
  created = "now";
  maxLayers = 125;
  copyToRoot = [
    dockerTools.caCertificates
    (buildEnv {
      name = "image-root";
      paths = [ busybox ];
      pathsToLink = [ "/bin" ];
    })
  ];
  config = {
    Env = [
      "port=${toString port}"
    ];
    Cmd = [
      ../../util/run_with_secrets.sh
      "PAT_1"
      "\\"
      (lib.getExe nodejs)
      "${callPackage ./github-readme-stats {}}/lib/node_modules/github-readme-stats/express.js"
    ];
    ExportedPorts."${toString port}/tcp" = {};
  };
}
