# ElevateLabs Internship Task – Node.js CI/CD Pipeline

This project demonstrates a complete **CI/CD pipeline for a Node.js web application** using **GitHub Actions, Docker, and Docker Hub**.

The pipeline is divided into three dependent stages:

```text
Test Application
       ↓
Build Docker Image
       ↓
Publish Image to Docker Hub
```

The main objective of this task was to understand how CI/CD works in practice: validating application code first, building a deployable Docker image only after successful tests, and publishing that same image only when all previous stages pass.

---

## Pipeline Result

Add your successful GitHub Actions screenshot here:

```markdown
![Successful CI/CD Pipeline](docs/images/pipeline-success.png)
```

![Successful CI/CD Pipeline](docs/images/pipeline-success.png)

---

## CI/CD Workflow

### 1. Test Stage

The first job validates the Node.js application.

It performs:

```text
Checkout Source Code
        ↓
Setup Node.js
        ↓
npm ci
        ↓
Lint Check
        ↓
Start Application
        ↓
Readiness Check
        ↓
Integration Tests
```

The Build stage does not run if this stage fails.

---

### 2. Build Stage

The Build job uses:

```yaml
needs: test
```

This ensures the Docker image is built only after the Test job succeeds.

The stage:

- Checks out the source code
- Builds the Docker image
- Saves the image as a `.tar` file
- Uploads it as a GitHub Actions artifact

For this Node.js application, the **Docker image is the deployable artifact**.

---

### 3. Publish Stage

The Publish job depends on both Test and Build:

```yaml
needs:
  - test
  - build
```

It:

- Downloads the Docker image artifact
- Loads the image
- Authenticates to Docker Hub using GitHub Secrets
- Tags the image
- Pushes it to Docker Hub

The image is published only if the previous jobs succeed.

---

## Docker Image

Docker Hub image:

```text
ambujmishra1997/nodejs-demoapp:latest
```

Pull the image:

```bash
docker pull ambujmishra1997/nodejs-demoapp:latest
```

Run it:

```bash
docker run -d \
  -p 3000:3000 \
  --name nodejs-demoapp \
  ambujmishra1997/nodejs-demoapp:latest
```

Then open:

```text
http://localhost:3000
```

---

## Project Structure

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

## Dockerfile

The project uses a custom Dockerfile:

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

Important points:

- Uses a lightweight Node.js Alpine image
- Installs only production dependencies
- Runs the application using a non-root user
- Exposes port `3000`

---

## GitHub Secrets

Docker Hub credentials are stored securely using GitHub Repository Secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

No Docker Hub password or token is stored directly in the workflow file.

---

# What I Learned From This Task

This task helped me understand CI/CD much more practically instead of only knowing individual commands.

## 1. Difference Between Java/Maven and Node.js Builds

My previous hands-on experience was mainly with Java applications where I was familiar with:

```text
pom.xml
   ↓
mvn test
   ↓
mvn clean install
   ↓
target/*.war
```

While working on this Node.js project, I learned that a plain JavaScript/Express application does not necessarily generate a `.war` or `.jar`.

For this application:

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

The Docker image itself becomes the deployable artifact.

This helped me understand that the build process depends on the technology stack and not every application produces the same type of artifact.

---

## 2. `package.json` and `package-lock.json`

I learned that `package.json` is similar to `pom.xml` in the sense that it defines:

- Application metadata
- Dependencies
- npm scripts
- Development dependencies

I also learned that `package-lock.json` locks the exact dependency versions.

For CI, I used:

```bash
npm ci
```

instead of `npm install` so dependency installation is reproducible and follows the lock file.

---

## 3. Separate CI/CD Jobs

Instead of keeping everything inside one job, I created three separate jobs:

```text
Test
 ↓
Build
 ↓
Publish
```

This made the pipeline easier to understand and introduced me to GitHub Actions job dependencies.

The Build job depends on Test:

```yaml
needs: test
```

The Publish job depends on both:

```yaml
needs:
  - test
  - build
```

This means failed or untested code cannot be published.

---

## 4. Integration Tests Need a Running Application

One important difference I learned was that this application's tests send HTTP requests to the actual running Node.js server.

So the pipeline must:

```text
Start Application
       ↓
Check localhost:3000
       ↓
Run Integration Tests
```

This helped me understand the difference between simply starting a process and confirming that an application is actually ready to accept traffic.

This concept is also related to readiness checks used in container orchestration platforms such as Kubernetes.

---

## 5. GitHub Actions Runners Are Isolated

I learned that different GitHub Actions jobs run on separate temporary runners.

```text
Test Job     → Runner 1
Build Job    → Runner 2
Publish Job  → Runner 3
```

A Docker image created in the Build job is therefore not automatically available in the Publish job.

---

## 6. Passing Artifacts Between Jobs

To solve the isolated-runner problem, I learned how to transfer the built Docker image:

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

This also ensures that the **same Docker image created in the Build stage is the one published to Docker Hub**, instead of rebuilding it again in the Publish stage.

---

## 7. Docker Image Tagging and Traceability

The pipeline publishes:

```text
ambujmishra1997/nodejs-demoapp:latest
```

and also tags images using the Git commit SHA.

This helped me understand image traceability:

```text
Git Commit
    ↓
CI/CD Run
    ↓
Docker Image
```

Using commit-based tags makes it easier to identify exactly which version of the source code produced a particular image.

---

## 8. Secrets Management

I learned not to hard-code credentials inside CI/CD YAML files.

Docker Hub authentication is handled through:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

stored in GitHub Repository Secrets.

The workflow reads them securely through the GitHub Actions secrets context.

---

## 9. Pipeline Failure Control

The pipeline behaves as follows:

```text
Test ❌
Build → Skipped
Publish → Skipped
```

```text
Test ✅
Build ❌
Publish → Skipped
```

Only this path publishes the image:

```text
Test ✅
   ↓
Build ✅
   ↓
Publish ✅
```

This helped me understand how automated quality gates protect later CI/CD stages.

---

## Skills Practiced

- Git and GitHub
- GitHub Actions
- YAML
- Node.js
- npm
- CI/CD pipeline design
- Linting
- Integration testing
- Application readiness checks
- Docker
- Dockerfile creation
- Docker image build and tagging
- GitHub Actions artifacts
- Docker Hub
- GitHub Secrets
- Secure token-based authentication
- Job dependencies
- Troubleshooting CI/CD workflows

---

## Pipeline Evidence

### Successful GitHub Actions Pipeline

![Successful CI/CD Pipeline](docs/images/pipeline-success.png)

### Docker Hub Published Image

![Docker Hub Image](docs/images/dockerhub-image.png)

---

## Future Improvements

The next improvements I would add are:

- Trivy container vulnerability scanning
- SonarQube/SonarCloud code-quality analysis
- Docker layer caching
- Kubernetes Deployment and Service
- Kubernetes readiness and liveness probes
- Deployment stage after image publishing
- Prometheus and Grafana monitoring
- Terraform-based cloud infrastructure
- AWS deployment with cost optimization

---

## Application Source Acknowledgement

The Node.js application used as the workload for this DevOps exercise is based on the open-source project:

**benc-uk/nodejs-demoapp**

The CI/CD workflow, Dockerfile, Test → Build → Publish job structure, artifact transfer, Docker Hub integration, GitHub Secrets configuration, and documentation were created as part of my hands-on DevOps practice.

---

## Author

**Ambuj Mishra**

GitHub: [ambujmishra1997](https://github.com/ambujmishra1997)
