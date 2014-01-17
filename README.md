# Appd

Appd is a personal PaaS like [Dokku](https://github.com/progrium/dokku) but written in Ruby.

**Appd is still in development and is not ready yet to be use for real app hosting.**

_Appd is currently developed and tested to run a simple rails app under the last Ubuntu LTS._

Like Dokku, Appd use docker and heroku buildpacks to run your app processes and git to deploy your app.

It differs from Dokku in the following ways:
* It has a CLI client
* You don't need to ssh to your servers, the cli client will execute its command remotely.
* The server is configured using a Chef repo ([appd-cookbook](https://github.com/garnieretienne/appd-cookbook))

Appd is still in development and is not ready yet to be use for real hosting case.

Currently supported:
* Bootstrap a new server ready to host your application
* Deploy to the server
...

# Getting Started

This guide assume:
* You're using a server running an unmodified Ubuntu LTS 12.04 and have a root access to it, using 
a password or an ssh key from the current user
* The current user running the shell on your dev machine have an ssh key (`~/.ssh/id_rsa`)
* A wildcard domain is configured for this server (*.server.domain.tld)

## Install the latest development version

appd is not yet released as a Gem but you can clone the directory and use bundler to test appd:

```
$> git clone https://github.com/garnieretienne/appd.git; cd appd;
$> bundle install --path vendor/bundle
[...]
$> bundle exec bin/appd 
Commands:
  appd apps            # Manage apps (create / destroy)
  appd config          # Manage app config vars
  appd help [COMMAND]  # Describe available commands or one specific command
  appd nodes           # Manage servers
```

## Bootstrap a new server

`appd nodes bootstrap ssh://root:password@server.domain.tld`

This command will:
* update the server using `apt-get`
* configure the hostname (server) and the fully qualified domain name (server.domain.tld) on the host
* upload the current user public key to the server (~/.ssh/id_rsa.pub)
* install Opscode Chef
* run `chef-solo` with the [appd-cookbook](https://github.com/garnieretienne/appd-cookbook) to configure the server

After running the command you will have two ssh accounts that authenticate using your current user name and your current SSH key:
* A sysop ssh access: `ssh your_name@server.domain.tld` with a classic `/bin/bash` shell and sudo right
* A devop ssh access: `ssh appd@server.domain.tld` with a `git-shell` shell and basic access to the SSH API used by the Appd CLI client to deploy/build/run applications

Sample output:
```
$> bundle exec bin/appd nodes bootstrap ssh://root:password@srv2.yuweb.fr
>>  Bootstrapping srv2.yuweb.fr 
>>  Updating the system 
    Reading package lists...    
    Building dependency tree...    
    Reading state information...    
    The following packages have been kept back:
      linux-headers-generic-lts-raring linux-image-generic-lts-raring
    The following packages will be upgraded:
      accountsservice apport apt apt-transport-https apt-utils base-files bc
      bind9-host curl dnsutils gnupg gpgv grub-common grub-pc grub-pc-bin
      grub2-common initramfs-tools initramfs-tools-bin iproute landscape-common
      language-pack-en language-pack-en-base libaccountsservice0 libapt-inst1.4
      libapt-pkg4.12 libbind9-80 libcurl3 libcurl3-gnutls libdns81 libdrm-intel1
      libdrm-nouveau1a libdrm-radeon1 libdrm2 libisc83 libisccc80 libisccfg82
      liblwres80 libssl1.0.0 linux-firmware linux-generic-lts-raring openssl
      procps python-apport python-lazr.restfulclient python-problem-report rsyslog
      wpasupplicant
    47 upgraded, 0 newly installed, 0 to remove and 2 not upgraded.
    Need to get 36.6 MB of archives.
    After this operation, 60.4 kB disk space will be freed.
    Get:1 http://mirrors.digitalocean.com/ubuntu/ precise-updates/main base-files amd64 6.5ubuntu6.7 [61.0 kB]
    Get:2 http://mirrors.digitalocean.com/ubuntu/ precise-updates/main libapt-pkg4.12 amd64 0.8.16~exp12ubuntu10.16 [936 kB]
    [...]
>>  Configuring the system 
    configure hostname... (done)
    upload a sysop key for user 'kurt'... (/root/sysops/kurt.pub)
    upload a devop key for user 'kurt'... (/root/devops/kurt.pub)
>>  Installing and running Chef 
    install chef on the remote host... (done)
    Configure ohai :
    * create '/etc/chef/ohai_plugins' (done)
    * reload 'custom_plugins' ... (done)
    Configure sudo :
    * install 'sudo' ... (skipped)
    * create '/etc/sudoers.d' (nothing to do)
    * create '/etc/sudoers.d/README' (done)
    * create '/etc/sudoers' (done)
    Configure appd sysops:
    * create 'sysop' ... (done)
    * install 'sysop' ... (done)
    * create 'kurt' ... (done)
    * create '/home/kurt/.ssh' (done)
    * run 'register 'kurt' key' execute... (done)
    Configure git :
    * install 'git' ... (nothing to do)
    Configure appd appserver:
    * create 'appd' ... (done)
    * create '/srv/appd/.ssh' (done)
    * run 'allow 'kurt' to deploy applications' execute... (done)
    * create '/srv/appd/appd-template' (done)
    * create '/srv/appd/appd-template/hooks' (done)
    * create '/srv/appd/appd-template/hooks/pre-receive' (done)
    * create '/srv/appd/git-shell-commands' (done)
    * create '/srv/appd/git-shell-commands/help' (done)
    * create '/srv/appd/git-shell-commands/create' (done)
    * create '/srv/appd/git-shell-commands/build' (done)
    * create '/srv/appd/git-shell-commands/release' (done)
    * create '/srv/appd/git-shell-commands/run' (done)
    * create '/srv/appd/git-shell-commands/route' (done)
    * create '/srv/appd/git-shell-commands/list' (done)
    * create '/srv/appd/git-shell-commands/store' (done)
    * install 'appd' ... (done)
    * add 'docker' ... (done)
    * run 'update the linux kernel to support aufs' bash... (done)
    * install 'lxc-docker' ... (done)
    * enable 'docker' ... (nothing to do)
    * manage 'docker' ... (done)
    Configure apt :
    * run 'apt-get-update' execut (skipped)
    * install 'update-notifier-common' ... (nothing to do)
    * run 'apt-get-update-periodic' execut (skipped)
    * create '/var/cache/local' (done)
    * create '/var/cache/local/preseeding' (done)
    Configure nginx repo:
    * add 'nginx' ... (done)
    * create '/etc/chef/ohai_plugins/nginx.rb' (done)
    * reload 'reload_nginx' ... (done)
    Configure nginx package:
    * install 'nginx' ... (done)
    Configure nginx ohaiplugin:
    * reload 'reload_nginx' ... (done)
    Configure nginx package:
    * enable 'nginx' ... (done)
    Configure nginx commonsdir:
    * create '/etc/nginx' (nothing to do)
    * create '/var/log/nginx' (done)
    * create '/var/run' (nothing to do)
    * create '/etc/nginx/sites-available' (done)
    * create '/etc/nginx/sites-enabled' (done)
    * create '/etc/nginx/conf.d' (nothing to do)
    Configure nginx commonsscript:
    * create '/usr/sbin/nxensite' (done)
    * create '/usr/sbin/nxdissite' (done)
    Configure nginx commonsconf:
    * create 'nginx.conf' (done)
    * create '/etc/nginx/sites-available/default' (done)
    * run 'nxdissite default' execut (skipped)
    Configure nginx :
    * start 'nginx' ... (nothing to do)
    Configure appd appserver:
    * create '/srv/appd/routes' (done)
    * create '/etc/nginx/conf.d/appd.conf' (done)
    * sync '/srv/appd/buildstep' ... (done)
    * install 'curl' ... (nothing to do)
    * run 'download the buildstep base container "progrium/buildstep"' execute... (done)
    Configure nginx :
    * reload 'nginx' ... (done)
>>  Done. 
    Sysop: ssh kurt@srv2.yuweb.fr
    Devop: ssh appd@srv2.yuweb.fr
```

## Creating a new app on the server

`appd apps create --app myapp --node server.domain.tld`

This command will create a remote git repository ready to receive a new app to deploy it.

Sample output:
```
$> bundle exec bin/appd apps create --app myapp --node srv2.yuweb.fr
>>  Creating the 'myapp' application 
    create the git repository... (appd@srv2.yuweb.fr:myapp.git)
```

## Deploy your application using git

_I will use the [heroku sample app](https://github.com/heroku/ruby-rails-sample) here_

Sample output:
```
$> git remote add srv2.yuweb.fr appd@srv2.yuweb.fr:myapp.git
$> git push srv2.yuweb.fr master
Counting objects: 67, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (53/53), done.
Writing objects: 100% (67/67), 26.60 KiB, done.
Total 67 (delta 5), reused 0 (delta 0)
remote: 
remote: -----> Receiving push
remote: -----> Building myapp...
remote:        Ruby/Rails app detected
remote: -----> Using Ruby version: ruby-2.0.0
remote: -----> Installing dependencies using Bundler version 1.3.2
remote:        Running: bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin --deployment
remote:        Fetching gem metadata from https://rubygems.org/..........
remote:        Fetching gem metadata from https://rubygems.org/..
remote:        Installing rake (10.0.3)
remote:        Installing i18n (0.6.1)
               [...]
remote:        Installing uglifier (1.3.0)
remote:        Your bundle is complete! It was installed into ./vendor/bundle
remote:        Post-install message from rdoc:
remote:        Depending on your version of ruby, you may need to install ruby rdoc/ri data:
remote:        <= 1.8.6 : unsupported
remote:        = 1.8.7 : gem install rdoc-data; rdoc-data --install
remote:        = 1.9.1 : gem install rdoc-data; rdoc-data --install
remote:        >= 1.9.2 : nothing to do! Yay!
remote:        Cleaning up the bundler cache.
remote: -----> Writing config/database.yml to read from DATABASE_URL
remote: -----> Preparing app for Rails asset pipeline
remote:        Running: rake assets:precompile
               [...]
remote:        Asset precompilation completed (7.48s)
remote: -----> WARNINGS:
remote:        Injecting plugin 'rails_log_stdout'
remote:        Injecting plugin 'rails3_serve_static_assets'
remote:        Add 'rails_12factor' gem to your Gemfile to skip plugin injection
remote:        You have not declared a Ruby version in your Gemfile.
remote:        To set your Ruby version add this line to your Gemfile:
remote:        ruby '2.0.0'
remote:        # See https://devcenter.heroku.com/articles/ruby-versions for more information."
remote: -----> Discovering process types
remote:        Default process types for Ruby/Rails -> rake, console, web, worker
remote: -----> Deploying
remote: -----> Launching v1
remote: -----> Done:
remote:        http://myapp.srv2.yuweb.fr
remote: 
To appd@srv2.yuweb.fr:myapp.git
 * [new branch]      master -> master
```

The web app should be available at the given URL: `http://myapp.server.domain.tld`.

You can connect to your server using your sysop SSH access to check docker processes:
```
$> docker ps
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS              PORTS                   NAMES
460a62cd8e5d        myapp:v1            /bin/bash -c PORT=80   1 minutes ago       Up 1 minutes        0.0.0.0:49153->80/tcp   lonely_bardeen
```

## Setting / Unsetting environment variables

You can set / unset ENV variables using the CLI client:
```
$> bundle exec bin/appd config
Commands:
  appd config help [COMMAND]                                           # Describe subcommands or one specific subcommand
  appd config list --app=APP --node=NODE                               # Display the config vars for an app
  appd config set KEY1=VALUE1 [KEY2=VALUE2 ...] --app=APP --node=NODE  # Set one or more config vars
  appd config unset KEY1 [KEY2 ...] --app=APP --node=NODE              # Unset one or more config vars
```

Example: Setting the `DATABASE_URL`
```
$> bundle exec bin/appd config set DATABASE_URL=postgres://root:root@localhost:4567 --node srv2.yuweb.fr --app myapp
>>  Setting config vars for 'myapp' 
    set DATABASE_URL... (postgres://root:root@localhost:4567)
    restart the app... (v2)

$> bundle exec bin/appd config list --node srv2.yuweb.fr --app myapp
>>  Displaying config vars for 'myapp' 
    DATABASE_URL=postgres://root:root@localhost:4567
    
```