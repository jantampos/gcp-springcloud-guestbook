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

# Enable Stackdriver Trace API

gcloud services enable cloudtrace.googleapis.com

# Add the Spring Cloud GCP Trace starter

# Backend
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-gcp-starter-trace</artifactId>
</dependency>

# Frontend
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-gcp-starter-trace</artifactId>
</dependency>

# Disable trace for testing purposes
spring.cloud.gcp.trace.enabled=false

# Enable trace sampling for the cloud profile for the backend and fe (put in application.properties)
spring.cloud.gcp.trace.enabled=true
spring.sleuth.sampler.probability=1
spring.sleuth.web.skipPattern=(^cleanup.*|.+favicon.*)

# Set up a service account

gcloud iam service-accounts create guestbook

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:guestbook@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/editor

gcloud iam service-accounts keys create \
  ~/service-account.json \
  --iam-account guestbook@${PROJECT_ID}.iam.gserviceaccount.com

# Run the app with service account

# BE
./mvnw spring-boot:run -Dserver.port=8081 -Dspring.profiles.active=cloud \
  -Dspring.cloud.gcp.credentials.location=file:///$HOME/service-account.json

# FE
./mvnw spring-boot:run -Dspring.profiles.active=cloud \
  -Dspring.cloud.gcp.credentials.location=file:///$HOME/service-account.json

# JAVAMS05 Messaging with Cloud Pub/Sub

# Enable Cloud Pub/Sub API

gcloud services enable pubsub.googleapis.com

# Create a Cloud Pub/Sub topic

gcloud pubsub topics create messages

# Add Spring Cloud GCP Pub/Sub starter FE

<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-gcp-starter-pubsub</artifactId>
</dependency>

# Publish a message

import org.springframework.cloud.gcp.pubsub.core.*;

@Autowired
private PubSubTemplate pubSubTemplate;

pubSubTemplate.publish("messages", name + ": " + message);


# Run
./mvnw -q spring-boot:run -Dserver.port=8081 -Dspring.profiles.active=cloud

# Create a subscription

gcloud pubsub subscriptions create messages-subscription-1 \
  --topic=messages

gcloud pubsub subscriptions pull messages-subscription-1

gcloud pubsub subscriptions pull messages-subscription-1

gcloud pubsub subscriptions pull messages-subscription-1 --auto-ack

# Process messages in subscriptions

cd ~
curl https://start.spring.io/starter.tgz \
  -d dependencies=cloud-gcp-pubsub \
  -d baseDir=message-processor | tar -xzvf -

...
     <dependencies>
          <dependency>
               <groupId>org.springframework.cloud</groupId>
               <artifactId>spring-cloud-gcp-starter-pubsub</artifactId>
          </dependency>
          <dependency>
               <groupId>org.springframework.boot</groupId>
               <artifactId>spring-boot-starter-test</artifactId>
               <scope>test</scope>
          </dependency>
     </dependencies>
...


import org.springframework.context.annotation.Bean;
import org.springframework.boot.CommandLineRunner;
import org.springframework.cloud.gcp.pubsub.core.*;

@Bean
public CommandLineRunner cli(PubSubTemplate pubSubTemplate) {
    return (args) -> {
        pubSubTemplate.subscribe("messages-subscription-1",
            (msg, ackConsumer) -> {
                System.out.println(msg.getData().toStringUtf8());
                ackConsumer.ack();
            });
    };
}


cd ~/message-processor
./mvnw -q spring-boot:run

## JAVAMS06 Integrating Cloud Pub/Sub with Spring

# Add the Spring Integration core

<dependency>
    <groupId>org.springframework.integration</groupId>
    <artifactId>spring-integration-core</artifactId>
</dependency>

# Create an outbound message gateway
...
  package com.example.frontend;

  import org.springframework.integration.annotation.MessagingGateway;

  @MessagingGateway(defaultRequestChannel = "messagesOutputChannel")
  public interface OutboundGateway {
    void publishMessage(String message);
  }
...

# Publish the message

@Autowired
private PubSubTemplate pubSubTemplate;

@Autowired
private OutboundGateway outboundGateway;

pubSubTemplate.publish("messages", name + ": " + message);

outboundGateway.publishMessage(name + ": " + message);

# Bind the output channel to the Cloud Pub/Sub topic

# configure a service activator to bind messagesOutputChannel to use Cloud Pub/Sub.
...
  import org.springframework.context.annotation.*;
  import org.springframework.cloud.gcp.pubsub.core.*;
  import org.springframework.cloud.gcp.pubsub.integration.outbound.*;
  import org.springframework.integration.annotation.*;
  import org.springframework.messaging.*;

  @Bean
  @ServiceActivator(inputChannel = "messagesOutputChannel")
  public MessageHandler messageSender(PubSubTemplate pubsubTemplate) {
    return new PubSubMessageHandler(pubsubTemplate, "messages");
  }
...

# Test the application in the Cloud Shell

./mvnw spring-boot:run -Dspring.profiles.active=cloud

gcloud pubsub subscriptions pull messages-subscription-1 --auto-ack

## JAVAMS07 Uploading and Storing Files

#  Add the Cloud Storage starter

<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-gcp-starter-storage</artifactId>
</dependency>

# Store the uploaded file
...
  <form action="/post" method="post" enctype="multipart/form-data">

  <!-- Add a file input -->
  <span>File:</span>
  <input type="file" name="file" accept=".jpg, image/jpeg"/>
...

...
  import org.springframework.cloud.gcp.core.GcpProjectIdProvider;
  import org.springframework.web.multipart.MultipartFile;
  import org.springframework.context.ApplicationContext;
  import org.springframework.core.io.Resource;
  import org.springframework.core.io.WritableResource;
  import org.springframework.util.StreamUtils;
  import java.io.*;

  // The ApplicationContext is needed to create a new Resource.
  @Autowired
  private ApplicationContext context;
  // Get the Project ID, as its Cloud Storage bucket name here
  @Autowired
  private GcpProjectIdProvider projectIdProvider;

  public String post(
    @RequestParam(name="file", required=false) MultipartFile file,
    @RequestParam String name,
    @RequestParam String message, Model model)
      throws IOException {
      String filename = null;
      if (file != null && !file.isEmpty()
          && file.getContentType().equals("image/jpeg")) {
              // Bucket ID is our Project ID
              String bucket = "gs://" +
                    projectIdProvider.getProjectId();
              // Generate a random file name
              filename = UUID.randomUUID().toString() + ".jpg";
              WritableResource resource = (WritableResource)
                    context.getResource(bucket + "/" + filename);
              // Write the file to Cloud Storage
              try (OutputStream os = resource.getOutputStream()) {
                    os.write(file.getBytes());
                }
      }
      ...
      payload.put("imageUri", filename);
      ...
  }
...

