{
  nix2container,
  arch,
  dockerTools,
  buildEnv,
  runCommand,

  acme-sh, # from flake input (or use fetchFromGitHub)
  openssl,
  curl,
  supercronic,
  busybox,
  ...
}: 
let
  acme-sh-pkg = runCommand "acme-sh-pkg" {} ''
    mkdir -p $out/acme.sh
    # Only include necessary stuff from acme.sh git repo
    cp -r ${acme-sh}/{deploy,dnsapi,notify,acme.sh} $out/acme.sh
    chmod -R 755 $out/acme.sh 
    patchShebangs $out/acme.sh 
  '';
  deps = buildEnv {
    name = "image-root";
    paths = [ supercronic curl openssl busybox ];
    pathsToLink = [ "/bin" ];
  };
  acmeRenewScript = runCommand "acme-renew.sh" {} ''
    mkdir -p $out/root
    ln -s ${./acme-renew.sh} $out/root/acme-renew.sh
  '';
in 
nix2container.buildImage {
  name = "bvngee/acme.sh";
  inherit arch;
  tag = "latest";
  created = "now";
  maxLayers = 125;
  copyToRoot = [
    deps
    acme-sh-pkg
    acmeRenewScript
    dockerTools.caCertificates
    dockerTools.fakeNss # Allows cron to append to /proc/1/fd/1 # do I still need this?
  ];
  config = {
    Cmd = [
      ../../util/run_with_secrets.sh
      "CF_Token"
      "CF_Account_ID"
      "\\"
      ./start.sh # Requests certs if that hasn't been done yet, otherwise starts supercronic
      ./crontab
    ];
    Volumes."/website-static" = { };
    Volumes."/acme.sh-certs" = { };
  };
}
