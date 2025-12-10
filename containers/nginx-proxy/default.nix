{
  nix2container,
  arch,
  dockerTools,
  buildEnv,
  runCommand,

  nginx,
  busybox,
  inotify-tools,
  ...
}: 
let
  nginxVar = runCommand "nginx-var" {} ''
    # afaik these paths must exist even if nginx is configured not to use them
    mkdir -p $out/var/log/nginx
    mkdir -p $out/var/cache/nginx
    mkdir -p $out/var/run # pid file
    # this also prevents an error
    mkdir -p $out/tmp
  '';
  # nginxConf = runCommand "nginx-conf" {} ''
  #   mkdir -p $out/etc/nginx
  #   # if I even split the config into more files, make this more dynamic
  #   cp ${./nginx.conf} $out/etc/nginx/nginx.conf
  #   cp ${./mime.types} $out/etc/nginx/mime.types
  # '';
  deps = buildEnv {
    name = "image-root";
    paths = [ nginx inotify-tools busybox ];
    pathsToLink = [ "/bin" ];
  };
in
nix2container.buildImage {
  name = "bvngee/nginx-proxy";
  inherit arch;
  tag = "latest";
  created = "now";
  maxLayers = 125;
  copyToRoot = [
    deps
    nginxVar
    # nginxConf
    dockerTools.fakeNss
  ];
  config = {
    Cmd = [
      ./start_nginx.sh
    ];
    Volumes."/usr/share/nginx/html" = { };
    Volumes."/usr/share/nginx/certs" = { };
    Volumes."/etc/nginx" = { }; # will be a bind mount to ./nginx-proxy-conf on host
    ExportedPorts."80/tcp" = {};
    ExportedPorts."443/tcp" = {};
  };
}
