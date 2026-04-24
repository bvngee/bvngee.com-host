default:
  @just --list

build-all:
  @just build webhook
  @just build acme-sh
  @just build nginx-proxy
  @just build github-readme-stats

build container:
  nix run .#containers.aarch64-linux.{{container}}.copyTo \
    docker://registry.bvngee.com/bvngee/{{container}}:latest

