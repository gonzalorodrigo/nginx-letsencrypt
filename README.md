# NGINX with LetsEncrypy certs autogeneration and SSL wrapping

This Docker container includes NGINX:1.13.12 with:

- Capacity to run wit uid:gid set from enviroment variables.
- Capacity to use external configuration files for "deault"
- Support for enviroment variables in configuration files.
- SSL certigicate auto-generation and renewal with [EFF's](https://www.eff.org/)
[LetsEncrypt](https://letsencrypt.org/) tools.

**Operational requirements summary**

- Any call on http://NGINX_SERVER_NAME must land in port 80 of the container.
- Any call on https://NGINX_SERVER_NAME must land in port 443 of the container.
- Service domain name (NGINX_SERVER_NAME) and cert email (NGINX_CERT_EMAIL) set
as env vars.
- UID (NGINX_UID) and GID (NGINX_GID) to be used by the NGINX process (Important
for SPIN!) set as env vars.
- A persistent file system location with write permissions mapped on
/etc/letsencrypt
- Templates for nginx's default.conf file mapped on /conf.d.

## Configuration

- For Docker: Follow example in docker-compose.yml and conf.d folder.
- For **Spin/Rancher**: follow example in rancher/docker-compose.yml and conf.d
folder.

### Certificate location mapping

A persistent, write-enabled file system must be mapped to the internal location
/etc/letsencrypt. Otherwise, the certificates will be lost of the container
is destroyed. 

### Port forwarding

Ports 80 and 443 for the service domain name must land in the NGINX container.

### NGINX settings

The containers require the following environment variables:

- Service server hostname (NGINX_SERVER_NAME, required): Defines the hostname
that is configured to access the services behind nginx.
- Certificate email(NGINX_CERT_EMAIL, required): Defines the email to be used
to register a certificate for NGINX_SERVER_NAME
- UID for the internal nginx process (NGINX_UID, optional): If set to a number,
the uid of the nginx process will be set to it.
- GID for the internal nginx process (NGINX_GID, optional): If set to a number,
the gid of the nginx process will be set to it.

### NGINX service configuration

NGINX will try to read two files: 
~~~
/conf.d/default.conf.tmplt.cert 		# Used when certificates are present
/conf.d/default.conf.tmplt.fallback     # Used when certificates could not be generated
~~~

**Adding the configuration in the container**

An external directory with those two files and appropriate permissions must be
mapped (ro) on /conf.d. Permissions can be set to o+r or the NGINX UID and GID
can be set to the corresponding user with NGINX_UID, NGINX_GID.

**File format**

Examples of the files have been included in the conf.d folder. Important points:

- Fill your nginx behavior in this files. 
- default.conf.tmplt.cert will be used if the certificates are installed. It
must include the listen 443 and cert location instructions.
- default.conf.tmplt.fallback will be used if the certificates are not installed
and new ones cannot be produced. It must include the listen 80.

**Variable substitution**

Values in the conf files can be replaced by enviroment variables. Anything with
the format ${VAR} that is set in the container enviroment will be replaced. If
not set, it will be left as it is. 

This is specially interesting to use the same conf files for different services.
Read example of docker-compose.yml and files in conf.d for more details.

### SPIN considerations

If /conf.d is mapped on a /project location, it is important that nginx runs
with the uid:gid of the user running the container so it has capacity to read
the files. Env vars NGINX_UID and NGINX_GID must be set to the uid and gid of
the user running the container.

## Certificate generation

### Requirements

- Any GET call on http://NGINX_SERVER_NAME must land in the port 80 of the nginx
container.
- /etc/letsencrypt must be mapped to a persistent file system.

### Renewal

The container will try to renew the certificate each month.

### Cert generation Process

If no certificates are present, the entrypoint of the container will
automatically generate new upon start-up. The process is as follows:

- NGIX is configured on to serve on "/" the internal folder /webroot
- Letsencrypt tool is invoked and places some challenge files in /webroot.
- The tool contacts the remote cert server and starts a certification challenge.
- The remote server will retrieve http://NGINX_SERVER_NAME:80/some_challenge_file
- If the remote server is sucessful, it will emit new certificates for
NGINX_SERVER_NAME.
- The Letsencrypt tools install the certificates.
- NGINX is restarted with the /conf.d/default.conf.tmplt.cert configuration.

## Building

If desired the container can be built and pushed to the NERSC registry with the
script:
~~~
./build_container_push_spin_registry.sh
~~~
It will be tagged with the branch of the repo and and the build time. It
requires that login to such registry has been performed at one point before 
with:
~~~
docker login https://registry.spin.nersc.gov/
~~~