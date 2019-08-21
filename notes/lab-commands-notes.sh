## JAVAMS01 Bootstrapping the Application Frontend and Backend

cd ~/
git clone https://github.com/saturnism/spring-cloud-gcp-guestbook.git

# Run the backedn locally
cp -a ~/spring-cloud-gcp-guestbook/1-bootstrap/guestbook-service \
  ~/guestbook-service

curl http://localhost:8081/guestbookMessages

curl -XPOST -H "content-type: application/json" \
  -d '{"name": "Ray", "message": "Hello"}' \
  http://localhost:8081/guestbookMessages

curl http://localhost:8081/guestbookMessages

# Run the frontend locally
cp -a ~/spring-cloud-gcp-guestbook/1-bootstrap/guestbook-frontend \
  ~/guestbook-frontend

cd ~/guestbook-frontend
./mvnw -q spring-boot:run

# Test FE
http://localhost:8080

# Test BE
curl -s http://localhost:8081/guestbookMessages

curl -s http://localhost:8081/guestbookMessages \
  | jq -r '._embedded.guestbookMessages[] | {name: .name, message: .message}'

## JAVAMS02 Configuring and Connecting to Cloud SQL


export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

gsutil ls gs://$PROJECT_ID

gsutil -m cp -r gs://$PROJECT_ID/* ~/

chmod +x ~/guestbook-frontend/mvnw
chmod +x ~/guestbook-service/mvnw

# Create a Cloud SQL instance, database, and table

# Enable Cloud SQL Administration API.
gcloud services enable sqladmin.googleapis.com

gcloud services list | grep sqladmin

gcloud sql instances list

# Create a Cloud SQL instance
gcloud sql instances create guestbook --region=us-central1

# Create a database in the Cloud SQL instance
gcloud sql databases create messages --instance guestbook

# Connect to Cloud SQL and create the schema
gcloud sql connect guestbook

show databases;

use messages;

# Create table 
CREATE TABLE guestbook_message (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name CHAR(128) NOT NULL,
  message CHAR(255),
  image_uri CHAR(255),
  PRIMARY KEY (id)
);

exit

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-gcp-dependencies</artifactId>
            <version>1.1.0.M1</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<repositories>
    <repository>
            <id>spring-milestones</id>
            <name>Spring Milestones</name>
            <url>https://repo.spring.io/libs-milestone</url>
            <snapshots>
                    <enabled>false</enabled>
            </snapshots>
    </repository>
</repositories>


# For Development: Disable Cloud SQL in the default profile
spring.cloud.gcp.sql.enabled=false

# Configure a Cloud Profile 

# Find the instance connection name by running the following command:
gcloud sql instances describe guestbook --format='value(connectionName)'

# Configure the connection pool
spring.datasource.hikari.maximum-pool-size=5

# Test the backend service running on Cloud SQL
cd ~/guestbook-service

./mvnw spring-boot:run -Dserver.port=8081 -Dspring.profiles.active=cloud


curl -XPOST -H "content-type: application/json" \
  -d '{"name": "Ray", "message": "Hello Cloud SQL"}' \
  http://localhost:8081/guestbookMessages

curl http://localhost:8081/guestbookMessages

gcloud sql connect guestbook

use messages
select * from guestbook_message;

exit;

## JAVAMS03 Working with Runtime Configurations

# Lab Prep
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

gsutil ls gs://$PROJECT_ID

gsutil -m cp -r gs://$PROJECT_ID/* ~/

chmod +x ~/guestbook-frontend/mvnw
chmod +x ~/guestbook-service/mvnw

# FE
<dependencies>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-gcp-starter-config</artifactId>
</dependency>
<dependency>
    <groupId>com.google.guava</groupId>
    <artifactId>guava</artifactId>
    <version>20.0</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
</dependencies>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-gcp-dependencies</artifactId>
            <version>1.1.0.M1</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<repositories>
    <repository>
        <id>spring-milestones</id>
        <name>Spring Milestones</name>
        <url>https://repo.spring.io/milestone</url>
        <snapshots>
            <enabled>false</enabled>
        </snapshots>
    </repository>
</repositories>

# Disable the runtime configuration server in the default profile

# boostrap.properties
spring.cloud.gcp.config.enabled=false

# Configure a cloud profile

# bootstrap-cloud.properties
spring.cloud.gcp.config.enabled=true
spring.cloud.gcp.config.name=frontend
spring.cloud.gcp.config.profile=cloud

# applicaton.properties
management.endpoints.web.exposure.include=*
# This property allows access to the Spring Boot Actuator endpoint so that you can dynamically refresh the configuration.

# Add RefreshScope to Contoller 
import org.springframework.cloud.context.config.annotation.RefreshScope;

@RefreshScope

# Create a runtime configuration

gcloud services enable runtimeconfig.googleapis.com

gcloud beta runtime-config configs create frontend_cloud

gcloud beta runtime-config configs variables set greeting \
  "Hi from Runtime Config" \
  --config-name frontend_cloud

gcloud beta runtime-config configs variables list --config-name=frontend_cloud

gcloud beta runtime-config configs variables \
  get-value greeting --config-name=frontend_cloud

# Run BE app

cd ~/guestbook-service

./mvnw -q spring-boot:run -Dserver.port=8081 -Dspring.profiles.active=cloud

# Run FE app

cd ~/guestbook-frontend

./mvnw spring-boot:run -Dspring.profiles.active=cloud

# Update and refresh a configuration

gcloud beta runtime-config configs variables set greeting \
  "Hi from Updated Config" \
  --config-name frontend_cloud

curl -XPOST http://localhost:8080/actuator/refresh

curl http://localhost:8080/actuator/configprops | jq

## JAVAMS04 Working with Stackdriver Trace


