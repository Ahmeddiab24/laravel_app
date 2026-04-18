# Docker + GitLab CI Setup

## 🚀 Building and Running Your Application

To start your application locally with Docker Compose, run:

```bash
docker compose up --build
```

Once built, your application will be accessible at:  
👉 **http://localhost:9020**

---

## 🐳 Using Docker-in-Docker (DinD) in GitLab CI

If you're using a Docker-based GitLab Runner and need to run Docker commands (e.g., to build or run containers within your CI pipeline), you'll need to enable **Docker-in-Docker** (DinD).

### 🔧 Step 1: Enable Privileged Mode

Edit the GitLab Runner configuration:

```bash
sudo nano /etc/gitlab-runner/config.toml
```

In the relevant runner section, set:

```toml
privileged = true
```

> ⚠️ Note: Privileged mode is required to run the Docker daemon inside the runner container.

### 📄 Step 2: Define Variables and CI Job

Update your `.gitlab-ci.yml`:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "" # Required to disable TLS and allow DinD

test:
  image: docker:28.1
  stage: test
  services:
    - name: docker:28.1-dind
  script:
    - docker version
```

This setup allows you to run Docker commands within your pipeline's `test` job using Docker-in-Docker.

---

## 🧩 Adding PHP Extensions

If your application requires additional PHP extensions, you’ll need to install them in the Docker image.

Open the `Dockerfile` and follow the included instructions or examples to add extensions as needed using tools like `docker-php-ext-install` or `pecl`.

---

## ☁️ Deploying Your Application to the Cloud

### 1. Build Your Image

To build the image locally:

```bash
docker build -t myapp .
```

If you're on a Mac (e.g., Apple Silicon) and deploying to a cloud platform using `amd64` architecture, build with:

```bash
docker build --platform=linux/amd64 -t myapp .
```

### 2. Push to Your Container Registry

Once built, tag and push the image:

```bash
docker tag myapp myregistry.com/myapp
docker push myregistry.com/myapp
```

Want to know more? Refer to Docker's official guide on [building and sharing containers](https://docs.docker.com/go/get-started-sharing/).
