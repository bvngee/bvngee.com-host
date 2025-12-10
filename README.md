# Website Self-hosting Setup

This is everything I use to build and host my website as well as a few other miscellaneous applications (all under *.bvngee.com). 
I package everything using container images that are generated purely using Nix expressions (no Dockerfiles!!) and sent
to my private self-hosted container registry using nix2container (which internally uses a patched version of Skopeo).

This setup is quite elaborate (and arguably overcomplicated). I plan to write a blog post discussing everything
in the future, including my decision making process (I've been meaning to for a while).

# Bootstrap Instructions (from scratch):

1. install docker engine on host machine
2. package containers locally with nix2container, build with skopeo (cross compile if 
        necessary & possible) to regular tar files, eg:
        `nix run .#containers.aarch64-linux.webhook.copyTo "docker-archive:webhook.tar:bvngee/webhook:latest"`
        `nix run .#containers.aarch64-linux.acme-sh.copyTo "docker-archive:acme-sh.tar:bvngee/acme.sh:latest"`
        etc
3. send tar files to server (eg with `scp`), import to docker engine with `docker image load -i image.tar`
4. send over compose.yaml, which will spin up a registry, which will be exposed by nginx reverse proxy 
        image that was just manually imported and also started by compose.yaml
5. import all manually sent images to now-running registry, tar files can be deleted
6. from then on, use nix2container's skopeo to push directly to self-hosted registry and deploy from there, eg:
        `nix run .#containers.aarch64-linux.acme-sh.copyTo docker://registry.bvngee.com/bvngee/acme.sh:latest`




note that nginx (when non-root) requires correct file permissions to be set on the
nginx.htpasswd secret, so you must `chmod 644 ./secrets/nginx.htpasswd` on host before
sending over the secrets

To add a new username/password combo to the htpasswd file:
`nix shell nixpkgs#apacheHttpd -c htpasswd -B secrets/nginx.htpasswd username`


docker compose exec -it registry /bin/registry garbage-collect /etc/docker/registry/config.yml


If you see a "sh: program: command not found" in any app/script, it very likely means that
something thats being attempted to be called has a shebang that doesnt exist (eg. /usr/bin/env)!
