project decalration: 

The pom.xml file is a crucial part of a Maven project, defining the project's structure, dependencies, and build configurations.This section declares the XML namespace and schema for the POM file.
model version:Specifies the version of the POM model being used

modelversion:
Specifies the version of the POM model being used.

Project Coordinates:
groupId: The unique identifier for the group or organization.
artifactId: The unique identifier for the project.
version: The version of the project.
packaging: The type of artifact produced (in this case, a JAR file).

Parent Project:

This section specifies that the project inherits from the Spring Boot starter parent, which provides default configurations and dependency management.

Properties:
Defines project properties, such as the Java version to be used.

Dependencies:
Lists the project's dependencies. In this case, it includes the Spring Boot starter for web applications.

Build Configuration:
This section configures the build process, specifying the Spring Boot Maven plugin, which is used to package the application.

Overall, the pom.xml file defines a Spring Boot project that produces a JAR file, uses Java 17, and includes the necessary dependencies for a web application.

## Maven Build Process

**What happens when you run `mvn clean package`:**

1. **Compile Phase**: Maven compiles the Java source code from `src/main/java/` using Java 17 (as specified in pom.xml).

2. **Test Phase**: Runs unit tests (if any exist in `src/test/java/`).

3. **Package Phase**: 
   - Creates a JAR file: `geo-service-1.0.0.jar`
   - Stores it in the `target/` directory
   - Spring Boot Maven plugin embeds all dependencies into the JAR

4. **Output**: You get an executable JAR file that can run as a standalone application.

**Key Maven Commands:**
- `mvn clean package` - Build the JAR (removes old builds first)
- `mvn clean install` - Build and install to local repository
- `mvn compile` - Just compile, don't package
- `mvn test` - Run tests only

## Build Flow in Your Project

```
Maven (pom.xml)
    ↓ mvn clean package
    ↓
Target Directory (JAR created)
    ↓ (used by Ant)
build.xml (Ant script)
    ↓ ant package
    ↓
Installer Bundle (dist/installer-bundle/)
    ├── bin/ (JAR file)
    ├── conf/ (application.properties)
    └── scripts/ (install.sh, upgrade.sh, uninstall.sh)
    ↓ (used by Docker & Packer)
Docker/Packer
    ↓
Container Image & Golden AMI
```

## Build.xml Overview
The build.xml is an Apache Ant build script that creates a distributable installer bundle for the geo-service application. It orchestrates the packaging process after Maven builds the JAR.

Key Components:
1. Properties (Configuration Variables)
```
dist.dir = dist/
bundle.dir = dist/installer-bundle/
bin.dir = dist/installer-bundle/bin/
conf.dir = dist/installer-bundle/conf/
scripts.dir = dist/installer-bundle/scripts/
target.dir = target/ (Maven's output directory)
jar.name = geo-service-1.0.0.jar
```
2. Build Targets (Tasks)

clean: Removes the old dist directory to ensure a fresh build.

prepare: Creates the directory structure for the installer bundle:

bin/ - Stores the JAR file
conf/ - Stores configuration files
scripts/ - Stores installation/upgrade scripts
copy-jar:

Checks if Maven has already built the JAR
Fails with an error message if the JAR is missing
Copies the JAR from target to bin/ directory
add-assets: Creates and adds critical files:

upgrade.sh - Backs up and upgrades the existing geo-service
install.sh - Installs geo-service to /opt/geo-service/
uninstall.sh - Removes the application
application.properties - Configuration template with server port (8080)
zip: Compresses the entire installer-bundle/ directory into a single ZIP file: geo-service-installer-bundle.zip

package (Default target): Final output message showing successful bundle creation

Execution flow
```
clean → prepare → copy-jar → add-assets → zip → package
```

What You Get After Running Ant:
A ZIP file containing:
```
geo-service-installer-bundle.zip
├── bin/
│   └── geo-service-1.0.0.jar
├── conf/
│   └── application.properties
└── scripts/
    ├── install.sh
    ├── upgrade.sh
    └── uninstall.sh
```
This bundle is ready for distribution and installation on Linux servers!

## Packer Configuration Overview
Packer is an Infrastructure-as-Code tool that automates the creation of machine images (AMIs) for AWS. This file creates a custom Golden AMI with your geo-service application pre-installed.

Key Sections:
1. Required Plugins
```amazon plugin >= 1.2.8
```
Specifies that Packer needs the HashiCorp AWS plugin to build AMIs.

2. Variables (Configurable Parameters)

region: AWS region where the AMI is built (default: us-west-2)
instance_type: EC2 instance type to use for building (default: t3.micro)
ami_name_prefix: Name prefix for the resulting AMI (default: geo-service-ami)
3. Locals (Computed Values)

build_timestamp: Creates a unique timestamp for each AMI build (e.g., 20260114120530)

4. Source AMI Configuration

Starts from a base Ubuntu 22.04 LTS AMI (Canonical)
Creates an EC2 instance temporarily for provisioning
Generates the final AMI with naming pattern: geo-service-ami-20260114120530
Tags the AMI for easy tracking

5. Build Process (Provisioners)

The build section runs these steps in order:

Copy JAR File: Transfers geo-service-1.0.0.jar from Maven's target directory to the EC2 instance
Copy Systemd Service File: Copies geo-service.service for Linux service management
Install Java: Runs install_java.sh script to install Java 17
Setup geo-service: Runs setup_geo_service.sh to configure the application and systemd service
Install Node Exporter: Runs install_node_exporter.sh for Prometheus monitoring

```
1. file provisioner → Copy geo-service-1.0.0.jar to /tmp/
2. file provisioner → Copy geo-service.service to /tmp/
3. shell provisioner → Run install_java.sh (installs Java 17)
4. shell provisioner → Run setup_geo_service.sh (configures app & systemd)
5. shell provisioner → Run install_node_exporter.sh (monitoring setup)
6. Packer creates AMI from configured instance
7. Packer terminates the temporary EC2 instance

```

Output:
A Golden AMI ready to deploy - pre-configured with:

Java runtime
geo-service application JAR
Systemd service file (auto-start capability)
Node Exporter for monitoring
This AMI can be used to launch production EC2 instances quickly without manual setup!

#### Packer Files Configuration Explained
Here's a comprehensive breakdown of all configuration files in the packer directory:
```[Unit]
Description=Geo Service (Spring Boot)
After=network.target
```
Defines this as a system service that starts after the network is ready
Makes geo-service a managed service on Linux

```
[Service]
Type=simple
User=root
WorkingDirectory=/opt/geo-service
ExecStart=/usr/bin/java -jar /opt/geo-service/geo-service.jar
Restart=always
RestartSec=5
SuccessExitStatus=143
```
Type=simple: Standard service type
User=root: Runs as root (can be changed for security)
ExecStart: Command to start the application (Java runs the JAR)
Restart=always: Auto-restarts if the service crashes
RestartSec=5: Waits 5 seconds before restarting

```
[Install]
WantedBy=multi-user.target
```
Enables auto-start when the system boots up
Result: geo-service runs automatically on system startup and restarts if it fails!

2. install_java.sh (Java Installation Script)
Purpose: Installs Java 17 runtime on the Ubuntu instance
```
sudo apt-get update -y                    # Update package manager
sudo apt-get install -y openjdk-17-jre   # Install Java 17 (JRE only, not full JDK)
java -version                            # Verify installation

```
Purpose: Installs Java 17 runtime on the Ubuntu instance

3. setup_geo_service.sh (Application Setup Script)
```
sudo mkdir -p /opt/geo-service
sudo mv /tmp/geo-service.jar /opt/geo-service/geo-service.jar
sudo chmod 755 /opt/geo-service/geo-service.jar
```
Creates the /opt/geo-service/ directory
Moves the JAR from temp to its permanent location
Sets execute permissions

```
sudo mv /tmp/geo-service.service /etc/systemd/system/geo-service.service
sudo systemctl daemon-reload
sudo systemctl enable geo-service
sudo systemctl start geo-service
```
Installs the systemd service file
Reloads systemd configuration
Enables auto-start on boot
Starts the service immediately

4. install_node_exporter.sh (Monitoring Setup Script)
```
NODE_EXPORTER_VERSION="1.7.0"
sudo useradd --no-create-home --shell /bin/false node_exporter
```
Creates a dedicated non-privileged node_exporter user

```
curl -LO "https://github.com/prometheus/node_exporter/releases/..."
tar xvf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
sudo cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
```
Downloads Node Exporter binary (Prometheus monitoring agent)
Extracts and installs it to /usr/local/bin/
Purpose: Enables system metrics collection for monitoring (CPU, memory, disk, network)

```
Packer Start
    ↓
Launch Ubuntu 22.04 EC2 Instance
    ↓
File Provisioner → Copy geo-service-1.0.0.jar
    ↓
File Provisioner → Copy geo-service.service
    ↓
Shell Provisioner → Run install_java.sh
    (Installs Java 17)
    ↓
Shell Provisioner → Run setup_geo_service.sh
    (Configures app directory, enables systemd service, starts geo-service)
    ↓
Shell Provisioner → Run install_node_exporter.sh
    (Installs Prometheus monitoring agent)
    ↓
Packer Creates AMI Snapshot
    ↓
Golden AMI Ready! (geo-service-ami-20260114120530)
```

What the Golden AMI Contains:
✅ Ubuntu 22.04 base OS
✅ Java 17 JRE
✅ geo-service JAR application
✅ Systemd service configured for auto-start & auto-restart
✅ Node Exporter for Prometheus monitoring

Ready to deploy: Launch an EC2 instance from this AMI, and geo-service runs automatically!


## Jenkinsfile Explanation
The Jenkinsfile is a declarative CI/CD pipeline that automates the entire build, package, and testing process for the geo-service application. It orchestrates Maven, Ant, Docker, and testing.

Pipeline Configuration
```
pipeline {
    agent any
```

Runs the pipeline on any available Jenkins agent/node
```
    environment {
        APP_NAME = "geo-service"
        VERSION  = "1.0.0"
        DOCKER_IMAGE = "${APP_NAME}:${VERSION}"
    }
```
Defines environment variables used throughout the pipeline
DOCKER_IMAGE resolves to geo-service:1.0.0

Build Stages
1. Checkout Stage
```
stage('Checkout') {
    steps { checkout scm }
}
```
Clones/pulls the latest code from Git repository
scm = Source Control Management

2. Build (Maven) Stage

```
stage('Build (Maven)') {
    steps {
        sh 'mvn clean package'
    }
}

```
Runs Maven to compile, test, and package the Java application
Output: geo-service-1.0.0.jar

3. Package (Ant) Stage
```
stage('Package (Ant)') {
    steps {
        sh 'ant package'
    }
}

```
Runs Ant to create the installer bundle
Takes the JAR from Maven and bundles it with scripts, config, and installation files
Output: geo-service-installer-bundle.zip

4. Docker Build Stage
```
stage('Docker Build') {
    steps {
        sh "docker build -t ${DOCKER_IMAGE} -f docker/Dockerfile ."
    }
}
```
Builds a Docker container image
Tags it as geo-service:1.0.0
Uses the Dockerfile located in Dockerfile

5. Smoke Test Stage
```
stage('Smoke Test') {
    steps {
        sh """
          docker rm -f ${APP_NAME} || true
          docker run -d --name ${APP_NAME} -p 8081:8080 ${DOCKER_IMAGE}
          sleep 5
          curl -s http://localhost:8081/health | grep -i OK
          docker rm -f ${APP_NAME}
        """
    }
}
```

Removes any existing container with the same name
Starts the Docker container in the background (-d)
Maps port 8081 (host) → 8080 (container)
Waits 5 seconds for the app to start
Tests by calling the health endpoint: http://localhost:8081/health
Checks for "OK" response
Cleans up by removing the container

Purpose: Verifies the application starts and responds correctly before deployment

```
post {
    always {
        archiveArtifacts artifacts: 'dist/**/*.zip, target/*.jar', fingerprint: true
    }
}
```
Always runs regardless of pipeline success/failure
Archives (stores as build artifacts):
All ZIP files in dist directory (installer bundle)
JAR files in target directory (application)
Fingerprints allow Jenkins to track which builds produced which artifacts

```
Git Repository (Push/Webhook)
    ↓
Jenkins Triggered
    ↓
[Checkout] → Clone code from Git
    ↓
[Build Maven] → Compile & test Java code
    Output: target/geo-service-1.0.0.jar
    ↓
[Package Ant] → Create installer bundle
    Output: dist/geo-service-installer-bundle.zip
    ↓
[Docker Build] → Create container image
    Output: geo-service:1.0.0 (in Docker registry)
    ↓
[Smoke Test] → Verify application health
    ✅ Start container
    ✅ Test /health endpoint
    ✅ Verify response
    ↓
[Archive Artifacts] → Store JAR and ZIP for deployment

```

What Gets Delivered After Successful Pipeline:
✅ Maven JAR: geo-service-1.0.0.jar (executable application)
✅ Ant Bundle: geo-service-installer-bundle.zip (with scripts for Linux installation)
✅ Docker Image: geo-service:1.0.0 (ready to push to registry)
✅ Artifacts Archived: Available in Jenkins for download and deployment

This pipeline is fully automated and can be triggered by Git commits, pull requests, or scheduled builds!






