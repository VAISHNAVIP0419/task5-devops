# Secure Jenkins & Nexus Deployment on AWS with Terraform, Docker, and Nginx

**Repository:** [https://github.com/VAISHNAVIP0419/task5-devops.git](https://github.com/VAISHNAVIP0419/task5-devops.git)

---

## Overview

This project provisions AWS EC2 instances with attached EBS volumes using Terraform, deploys Jenkins and Nexus using Docker Compose, configures DNS subdomains, secures the endpoints with Let's Encrypt SSL certificates (requested via `lego`), and exposes both applications over HTTPS through an Nginx reverse proxy.

**Result:**

* Jenkins: `https://vjenkins.vyturr.one`
* Nexus: `https://vnexus.vyturr.one`

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture](#architecture)
3. [Step 1 — Terraform Infrastructure Setup](#step-1---terraform-infrastructure-setup)
4. [Step 2 — Docker & Docker Compose Deployment](#step-2---docker--docker-compose-deployment)
5. [Step 3 — DNS Subdomain Configuration](#step-3---dns-subdomain-configuration)
6. [Step 4 — SSL Certificate Generation with Lego](#step-4---ssl-certificate-generation-with-lego)
7. [Step 5 — Nginx Reverse Proxy Setup](#step-5---nginx-reverse-proxy-setup)
8. [Step 6 — Validation & Testing](#step-6---validation--testing)
9. [Step 7 — Final Result](#step-7---final-result)
10. [Step 8 — CI/CD Pipeline Example (Jenkins + Nexus)](#step-8---cicd-pipeline-example-jenkins--nexus)
11. [Step 9 — Jenkins Setup](#step-9---jenkins-setup)
12. [Step 10 — Nexus Setup](#step-10---nexus-setup)
13. [Step 11 — CI Pipeline Flow](#step-11---ci-pipeline-flow)
14. [Quick Test](#quick-test)
15. [Notes & Troubleshooting](#notes--troubleshooting)

---

## Prerequisites

* AWS account with permissions to create EC2, EBS and related resources.
* Terraform installed and configured with AWS provider + credentials.
* A domain managed in DNS (in this project: `vyturr.one`) with the ability to create subdomains.
* SSH keypair for EC2 instances.
* Local tools (on the instances): `docker`, `docker-compose`, `nginx`, `lego` (for Let’s Encrypt), `curl`.

---

## Architecture

```
Internet
   |
   +--> vjenkins.vyturr.one  (Nginx reverse proxy on EC2 - forwards 443 -> Jenkins container 8080)
   |
   +--> vnexus.vyturr.one    (Nginx reverse proxy on EC2 - forwards 443 -> Nexus container 8081)

Each server:
- EC2 instance
- Attached EBS (15-20 GB) mounted at /data1
- Docker data-root configured to /data1/docker
- Docker Compose to run Jenkins / Nexus containers
- Nginx configured with SSL certificates in /etc/nginx/ssl
```

---

## Step 1 — Terraform Infrastructure Setup

**What was provisioned:**

* Two EC2 instances:

  * `jenkins_server` for Jenkins
  * `nexus_server` for Nexus
* Attached 15–20 GB EBS volumes to each instance.

**User data script (high level):**

* Install Docker and Docker Compose and check versions:

```bash
# example commands executed in user_data
apt-get update -y
apt-get install -y docker.io curl
# install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker --version
docker-compose version
```

* Detect, format, and mount attached EBS at `/data1`.
* Configure Docker’s data-root to `/data1/docker` (e.g. `/etc/docker/daemon.json`).
* Restart Docker service so Docker uses the mounted volume.

> Note: keep `set -e` in any provisioning scripts so failures stop the boot process and are visible.

---

## Step 2 — Docker & Docker Compose Deployment

**`docker-compose.yml`** (placed on each server as appropriate) runs:

* Jenkins LTS container on port `8080`.
* Nexus (latest) container on port `8081`.

Persistent volumes are mapped to directories on the mounted EBS volume so data survives instance reboots/termination.

**Bring the services up:**

```bash
docker-compose up -d
```

**Security note:**

* Expose only required ports to the outside world; prefer localhost binding and fronting with Nginx.

---

## Step 3 — DNS Subdomain Configuration

Create DNS records pointing to the public IP(s) of the servers (A records or ALIAS / CNAME depending on DNS provider):

* `vjenkins.vyturr.one` → Jenkins server
* `vnexus.vyturr.one` → Nexus server

This lets users reach services via friendly subdomains instead of raw IPs.

---

## Step 4 — SSL Certificate Generation with Lego

Install `lego` on each server:

```bash
sudo apt install -y lego
lego --version
```

Request Let's Encrypt certificates using `--http` verification (example):

```bash
# for Jenkins
sudo lego --email="your-email@example.com" \
  --domains="vjenkins.vyturr.one" --http run

# for Nexus
sudo lego --email="your-email@example.com" \
  --domains="vnexus.vyturr.one" --http run
```

Copy certificates to a place Nginx can use and secure them:

```bash
sudo mkdir -p /etc/nginx/ssl
sudo cp ~/.lego/certificates/vjenkins.vyturr.one.crt /etc/nginx/ssl/
sudo cp ~/.lego/certificates/vjenkins.vyturr.one.key /etc/nginx/ssl/
# fix permissions
sudo chown root:root /etc/nginx/ssl/*
sudo chmod 600 /etc/nginx/ssl/*.key
```

Repeat for Nexus (`vnexus.vyturr.one`) certificate files.

---

## Step 5 — Nginx Reverse Proxy Setup

Install Nginx and verify version:

```bash
sudo apt install -y nginx
nginx -v
```

Create configuration files (example locations):

* `/etc/nginx/conf.d/jenkins.conf`
* `/etc/nginx/conf.d/nexus.conf`

**Goals of the configs:**

* Redirect all HTTP (80) → HTTPS (443).
* Terminate SSL in Nginx using certs at `/etc/nginx/ssl/*.crt` and `.key`.
* Proxy pass HTTPS requests to local backend containers:

  * Jenkins backend: `127.0.0.1:8080`
  * Nexus backend: `127.0.0.1:8081`
* Add proxy headers for client info (e.g., `X-Forwarded-For`, `X-Real-IP`).

> Example snippet (SSL server block) — replace cert paths and proxy settings as required:

```nginx
server {
  listen 443 ssl;
  server_name vjenkins.vyturr.one;

  ssl_certificate /etc/nginx/ssl/vjenkins.vyturr.one.crt;
  ssl_certificate_key /etc/nginx/ssl/vjenkins.vyturr.one.key;

  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://127.0.0.1:8080;
  }
}

server {
  listen 80;
  server_name vjenkins.vyturr.one;
  return 301 https://$host$request_uri;
}
```

Repeat similar for Nexus (change `server_name` and `proxy_pass` to `127.0.0.1:8081`).

---

## Step 6 — Validation & Testing

Validate and reload Nginx config:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Test with `curl` or a browser:

* HTTP requests should redirect to HTTPS.
* SSL certificates should be valid/trusted in the browser (or at least issued by Let's Encrypt).
* Applications should load via the secure subdomains.

---

## Step 7 — Final Result

* Jenkins: `https://vjenkins.vyturr.one`
* Nexus: `https://vnexus.vyturr.one`

Both are served securely via Nginx + Let's Encrypt certificates.

---

## Step 8 — CI/CD Pipeline Example (Jenkins + Nexus)

This project demonstrates a sample CI pipeline that builds a small Python Flask app, creates a Docker image, and pushes it to Nexus (acting as a private Docker registry).

**Technologies used in the demo pipeline:**

* Python Flask app (sample app in repo)
* Docker (build image)
* Jenkins Pipeline (Jenkinsfile in repo)
* Nexus as private Docker registry (hosted on `vnexus.vyturr.one`)

---

## Step 9 — Jenkins Setup

1. Install Docker plugin in Jenkins.
2. Configure Nexus credentials in Jenkins credential store (example ID used in project):

   * `nexus-docker-credentials`
3. Create a Pipeline job in Jenkins and point SCM to this repository:

   * `https://github.com/VAISHNAVIP0419/task5-devops.git`
4. The `Jenkinsfile` defines the pipeline stages (checkout, build, tag, push, cleanup).

> Example minimal Jenkins pipeline stage for Docker build & push:

```groovy
pipeline {
  agent any
  environment {
    REGISTRY = "vnexus.vyturr.one:8081"
    REPO = "simple-flask-ci/simple-flask-ci"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build') {
      steps {
        sh 'docker build -t ${REPO}:latest .'
      }
    }
    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'nexus-docker-credentials', usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
          sh 'docker login ${REGISTRY} -u $NUSER -p $NPASS'
          sh 'docker tag ${REPO}:latest ${REGISTRY}/${REPO}:latest'
          sh 'docker push ${REGISTRY}/${REPO}:latest'
        }
      }
    }
    stage('Cleanup') { steps { sh 'docker rmi ${REPO}:latest || true' } }
  }
}
```

---

## Step 10 — Nexus Setup

1. Access Nexus: `https://vnexus.vyturr.one`
2. Create a Docker (hosted) repository in Nexus with name: `simple-flask-ci` (or similar top-level repo name).
3. Create or note Nexus user credentials; add these credentials into Jenkins (`nexus-docker-credentials`) so Jenkins can `docker login` and push images.

---

## Step 11 — CI Pipeline Flow

Typical successful pipeline flow in this project:

1. Jenkins pulls code from GitHub.
2. Docker image is built.
3. Image is tagged and pushed to Nexus registry.
4. Local image is cleaned up.

**Sample pipeline logs (illustrative):**

```
Successfully built ac977bbb2c7b
Successfully tagged simple-flask-ci:latest
Successfully pushed vnexus.vyturr.one/simple-flask-ci/simple-flask-ci:latest
Finished: SUCCESS
```

**Outcome:**

* Jenkins pipelines run from `https://vjenkins.vyturr.one`.
* Nexus stores Docker images at `https://vnexus.vyturr.one`.
* Example Flask CI app built and pushed to the Nexus registry.

---

## Quick Test

From a machine that can access the Nexus registry (replace ports and hostnames if your Nexus uses different ports):

```bash
# login to nexus docker registry
docker login vnexus.vyturr.one:8081

# pull the sample image built by the pipeline
docker pull vnexus.vyturr.one:8081/simple-flask-ci/simple-flask-ci:latest

# run the image locally
docker run -d -p 5000:5000 vnexus.vyturr.one:8081/simple-flask-ci/simple-flask-ci:latest

# Access the app (example):
# http://vjenkins.vyturr.one:5000/  (or use the server IP + port as appropriate)
```

**Result:** Jenkins pipeline and Nexus image working if the app responds.

---

## Notes & Troubleshooting

* If SSL issuance fails with `lego` using `--http`, ensure that port 80 is reachable and the domain resolves to the instance that runs lego.
* Verify that Docker's `data-root` is set correctly and Docker restarted after the change.
* On Nginx errors, always run `sudo nginx -t` to validate configuration before reloading.
* Keep credentials secure: store Nexus credentials in Jenkins credential store instead of hard-coding.
* If using a single EC2 host for both services behind Nginx, ensure containers bind to `127.0.0.1:<port>` or expose only on the internal interface.

---

## References

* Repo: [https://github.com/VAISHNAVIP0419/task5-devops.git](https://github.com/VAISHNAVIP0419/task5-devops.git)

---

*This README was created to document the Secure Jenkins & Nexus deployment implemented in this repository.*
