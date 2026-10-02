# Node.js CI/CD Pipeline with GitHub Actions

A hands-on DevOps project that implements a complete **CI/CD pipeline for a Node.js web application** using **GitHub-Actions, Docker, and Docker Hub**.

The pipeline is designed around three clear stages:

```text
Test  →  Build  →  Publish
```

Each stage depends on the successful completion of the previous stage, ensuring that only tested and successfully built code is published as a Docker image.

---

## Overview

This project demonstrates how to:

- Validate a Node.js application using linting and integration tests
- Build a Docker image only after tests pass
- Transfer the built image between isolated GitHub Actions jobs
- Publish the same tested image to Docker Hub
- Manage Docker Hub credentials securely using GitHub Secrets
- Use Git commit SHA tags for image traceability

For this Node.js application, there is no Maven-style `.jar` or `.war` artifact.  
The **Docker image itself is treated as the deployable artifact**.

---

## CI/CD Architecture

```text
Developer
   |
   | git push
   v
GitHub Repository
   |
   v
GitHub Actions
   |
   +-----------------------+
   |                       |
   v                       |
TEST                       |
- Checkout code            |
- Setup Node.js            |
- npm ci                   |
- Lint                     |
- Start application        |
- Readiness check          |
- Integration tests        |
   |                       |
   | PASS                  |
   v                       |
BUILD                      |
- Checkout code            |
- docker build             |
- docker save              |
- Upload image artifact    |
   |                       |
   | PASS                  |
   v                       | 
PUBLISH                    |
- Download artifact        |
- docker load              |
- Docker Hub login         |
- Tag image                |
- Push image               |
   |                       |
   v                       |
Docker Hub <---------------+
```

---

## Pipeline Dependency Flow

The jobs are connected using GitHub Actions `needs`.

```text
Test ✅
   ↓
Build ✅
   ↓
Publish ✅
```

Failure behavior:

```text
Test ❌
   ↓
Build skipped
   ↓
Publish skipped
```

```text
Test ✅
   ↓
Build ❌
   ↓
Publish skipped
```

This ensures that a Docker image is never published unless validation and image creation both succeed.

---

## Pipeline Evidence

### Successful GitHub Actions Run

Attached successful workflow screenshot below:

```markdown
![Successful CI/CD Pipeline](docs/images/pipeline-success.png)
```

![Successful CI/CD Pipeline](docs/images/pipeline-success.png)

### Docker Hub Image

Attached Docker Hub screenshot below:

```markdown
![Docker Hub Image](docs/images/dockerhub-image.png)
```

![Docker Hub Image](docs/images/dockerhub-image.png)

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── my-ci.yaml
│
├── docs/
│   └── images/
│       ├── pipeline-success.png
│       └── dockerhub-image.png
│
├── src/
│   ├── public/
│   ├── routes/
│   ├── tests/
│   ├── todo/
│   ├── views/
│   ├── .env.sample
│   ├── eslint.config.mjs
│   ├── graph.mjs
│   ├── package.json
│   ├── package-lock.json
│   └── server.mjs
│
├── Dockerfile
├── .dockerignore
├── .gitignore
├── .prettierrc.yaml
└── README.md
```

---

## Tech Stack

- **Node.js**
- **npm**
- **GitHub**
- **GitHub Actions**
- **Docker**
- **Docker Hub**
- **Linux GitHub-hosted runners**
- **Git**
- **YAML**

---

# Workflow Breakdown

## 1. Test Job

The Test job validates the application before any image is built.

### Steps

```text
Checkout Source Code
        ↓
Setup Node.js
        ↓
npm ci
        ↓
npm run lint
        ↓
npm start
        ↓
Readiness Check
        ↓
npm test
```

### Why `npm ci`?

`npm ci` is used instead of `npm install` because it installs dependencies using the exact versions recorded in `package-lock.json`.

This makes CI runs more predictable and reproducible.

### Why start the application before testing?

The application uses integration tests that send HTTP requests to the running Node.js server.

So the workflow must:

```text
Start Application
       ↓
Wait until port 3000 responds
       ↓
Run Integration Tests
```

This avoids false failures caused by tests starting before the application is ready.

---

## 2. Build Job

The Build job runs only after the Test job succeeds.

```yaml
needs: test
```

### Build flow

```text
Checkout Source Code
        ↓
docker build
        ↓
Docker Image
        ↓
docker save
        ↓
nodejs-demoapp.tar
        ↓
Upload GitHub Artifact
```

The Docker image is tagged using the Git commit SHA:

```text
nodejs-demoapp:<commit-sha>
```

This provides traceability between the source commit and the built image.

---

## 3. Publish Job

The Publish job depends on both Test and Build.

```yaml
needs:
  - test
  - build
```

### Publish flow

```text
Download Docker Artifact
        ↓
docker load
        ↓
Login to Docker Hub
        ↓
Tag Image
        ↓
Push Image
```

The image is published to:

```text
ambujmishra1997/nodejs-demoapp:latest
```

It is also published with the Git commit SHA as a version tag.

Example:

```text
ambujmishra1997/nodejs-demoapp:<commit-sha>
```

---

# Why the Docker Image Is the Artifact

My earlier hands-on experience was mainly with Java and Maven.

A typical Java build looks like:

```text
pom.xml
   ↓
mvn test
   ↓
mvn clean install
   ↓
target/*.war
```

For this Node.js application, there is no equivalent `.war` or `.jar` output.

The application runs directly from JavaScript source:

```text
package.json
     ↓
npm ci
     ↓
Lint + Tests
     ↓
docker build
     ↓
Docker Image
```

So in this project, the **Docker image is the deployable build artifact**.

---

# Dockerfile

The project uses the following Dockerfile:

```dockerfile
FROM node:24-alpine

WORKDIR /app

COPY src/package*.json ./

RUN npm ci --omit=dev

COPY src/ .

ENV NODE_ENV=production

EXPOSE 3000

USER node

CMD ["npm", "start"]
```

### Dockerfile Design

- Uses a lightweight Alpine-based Node.js image
- Copies dependency files before source code for better Docker layer reuse
- Installs only production dependencies
- Runs the application using a non-root user
- Exposes application port `3000`

---

# Docker Hub

## Image

```text
ambujmishra1997/nodejs-demoapp:latest
```

## Pull the image

```bash
docker pull ambujmishra1997/nodejs-demoapp:latest
```

## Run the container

```bash
docker run -d \
  -p 3000:3000 \
  --name nodejs-demoapp \
  ambujmishra1997/nodejs-demoapp:latest
```

Open:

```text
http://localhost:3000
```

---

# GitHub Secrets

Docker Hub credentials are not stored directly in the workflow.

The following repository secrets are configured:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

They are accessed securely in GitHub Actions using:

```yaml
${{ secrets.DOCKERHUB_USERNAME }}
${{ secrets.DOCKERHUB_TOKEN }}
```

This keeps credentials out of the repository and workflow source.

---

# Why the Docker Image Is Saved as a GitHub Artifact

Each GitHub Actions job runs on a separate temporary runner.

```text
Test Job     → Runner 1
Build Job    → Runner 2
Publish Job  → Runner 3
```

The Docker image built in the Build job does not automatically exist in the Publish job.

To transfer the same image between jobs:

```text
docker build
     ↓
Docker Image
     ↓
docker save
     ↓
nodejs-demoapp.tar
     ↓
Upload Artifact
     ↓
Download Artifact
     ↓
docker load
     ↓
docker push
```

This also prevents the image from being rebuilt during the Publish stage.

The exact image produced by Build is the image that gets published.

---

# What I Learned

This project helped me understand CI/CD as a complete workflow rather than as a collection of individual commands.

## 1. Mapping Java/Maven Concepts to Node.js

My previous build experience was mostly with Java and Maven.

I was familiar with:

```text
pom.xml
   ↓
mvn test
   ↓
mvn clean install
   ↓
target/*.war
```

In this project I learned that a plain Node.js application does not necessarily generate a `.jar` or `.war`.

Instead:

```text
package.json
     ↓
npm ci
     ↓
Lint + Tests
     ↓
Docker Build
     ↓
Docker Image
```

This helped me understand that the artifact strategy depends on the application stack.

---

## 2. `package.json` vs `pom.xml`

I learned that `package.json` is the main project definition file for a Node.js application.

It contains:

- Dependencies
- Development dependencies
- Application metadata
- npm scripts

I also learned that `package-lock.json` locks exact dependency versions.

For CI, `npm ci` is useful because it performs a clean and reproducible dependency installation.

---

## 3. Building Multi-Job Pipelines

I learned how to split a workflow into clear jobs:

```text
Test
 ↓
Build
 ↓
Publish
```

Instead of putting everything in one long job, each job has a clear responsibility.

This makes the pipeline easier to understand, troubleshoot, and extend.

---

## 4. Job Dependencies with `needs`

I learned how GitHub Actions controls execution order using `needs`.

```yaml
build:
  needs: test
```

and:

```yaml
publish:
  needs:
    - test
    - build
```

This ensures later stages are blocked automatically if earlier stages fail.

---

## 5. Integration Testing

I learned the difference between normal build-time tests and tests that require a running application.

The application must be started first:

```text
npm start
   ↓
Readiness Check
   ↓
npm test
```

This taught me an important DevOps principle:

> A process being started does not always mean the application is ready to serve traffic.

This concept is also important later in Kubernetes readiness and liveness probes.

---

## 6. GitHub Actions Runners Are Ephemeral

I learned that GitHub Actions jobs do not necessarily run on the same machine.

Each job can receive a fresh runner, and that runner is destroyed after the job completes.

Because of this, files and Docker images must be explicitly transferred between jobs when needed.

---

## 7. Passing Artifacts Between Jobs

I learned how to move a Docker image from Build to Publish without rebuilding it:

```text
docker save
   ↓
Upload Artifact
   ↓
Download Artifact
   ↓
docker load
```

This was one of the most important practical lessons from the project.

---

## 8. Docker as a Deployable Artifact

I learned how to package an application, its runtime, and its production dependencies into a single Docker image.

The Docker image becomes the portable unit that can later be deployed to:

- Docker hosts
- Kubernetes
- Cloud platforms
- Container services

---

## 9. Image Tagging and Traceability

I learned why relying only on `latest` is not enough.

Using the Git commit SHA as an image tag creates traceability:

```text
Git Commit
    ↓
GitHub Actions Run
    ↓
Docker Image
```

This makes it easier to identify exactly which version of the application is running.

---

## 10. Secure Credential Management

I learned not to hard-code Docker Hub credentials in workflow files.

Instead, GitHub Secrets are used for:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

This introduced me to secure credential handling in CI/CD systems.

---

## 11. Failure Control and Quality Gates

I learned how pipeline stages act as quality gates.

```text
Test ❌
   ↓
Build skipped
   ↓
Publish skipped
```

and:

```text
Test ✅
   ↓
Build ✅
   ↓
Publish ✅
```

Only validated code reaches the registry.

---

# Skills Practiced

- Git and GitHub
- GitHub Actions
- CI/CD pipeline design
- YAML
- Node.js
- npm
- Dependency management
- Linting
- Integration testing
- Application readiness checks
- Dockerfile creation
- Docker image building
- Docker image tagging
- Docker Hub
- GitHub Secrets
- Token-based authentication
- GitHub Actions artifacts
- Job dependencies
- Commit SHA versioning
- Pipeline troubleshooting

---

# Future Improvements

The next improvements planned for this project are:

- Trivy container vulnerability scanning
- SonarQube / SonarCloud code-quality analysis
- Docker build caching
- Kubernetes Deployment and Service
- Kubernetes readiness and liveness probes
- Automated deployment after image publishing
- Prometheus and Grafana monitoring
- Terraform-based infrastructure
- AWS deployment with cost optimization
- Rollback strategy
- Environment-based deployments such as Dev / Staging / Production

---

# Application Source

The Node.js application used as the workload for this DevOps project is based on the open-source project:

**benc-uk/nodejs-demoapp**

The CI/CD workflow, Dockerfile, Test → Build → Publish pipeline design, artifact transfer, Docker Hub publishing, secret configuration, and project documentation were created as part of hands-on DevOps practice.

---

## Author

**Ambuj Mishra**

GitHub: [ambujmishra1997](https://github.com/ambujmishra1997)
