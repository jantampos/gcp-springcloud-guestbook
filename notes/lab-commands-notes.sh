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

## JAVAMS08 Using Cloud Platform APIs

# Enable Vision API

gcloud services enable vision.googleapis.com

# Add the Vision client library

<dependency>
  <groupId>com.google.cloud</groupId>
  <artifactId>google-cloud-vision</artifactId>
</dependency>

# Add a GCP credential scope for Spring

# /application.properties
spring.cloud.gcp.credentials.scopes=https://www.googleapis.com/auth/cloud-platform


# Create a Vision API client bean
...
import java.io.IOException;
import com.google.cloud.vision.v1.*;
import com.google.api.gax.core.CredentialsProvider;

// This configures the Vision API settings with a
// credential using the the scope we specified in
// the application.properties.
@Bean
public ImageAnnotatorSettings imageAnnotatorSettings(
            CredentialsProvider credentialsProvider)
            throws IOException {
            return ImageAnnotatorSettings.newBuilder()
            .setCredentialsProvider(credentialsProvider).build();
}

@Bean
public ImageAnnotatorClient imageAnnotatorClient(
            ImageAnnotatorSettings settings)
            throws IOException {
        return ImageAnnotatorClient.create(settings);
}
...

# Analyze the image
...
import com.google.cloud.vision.v1.*;


@Autowired
private ImageAnnotatorClient annotatorClient;

private void analyzeImage(String uri) {
    # // After the image was written to GCS,
    # // analyze it with the GCS URI.It's also
    # // possible to analyze an image embedded in
    # // the request as a Base64 encoded payload.
    List<AnnotateImageRequest> requests = new ArrayList<>();
    ImageSource imgSrc = ImageSource.newBuilder()
          .setGcsImageUri(uri).build();
    Image img = Image.newBuilder().setSource(imgSrc).build();
    Feature feature = Feature.newBuilder()
          .setType(Feature.Type.LABEL_DETECTION).build();
    AnnotateImageRequest request = AnnotateImageRequest
          .newBuilder()
          .addFeatures(feature)
          .setImage(img)
          .build();
    requests.add(request);
    BatchAnnotateImagesResponse responses =
          annotatorClient.batchAnnotateImages(requests);
      #  // We send in one image, expecting just
      #  // one response in batch
    AnnotateImageResponse response =responses.getResponses(0);
    System.out.println(response);
}

// After written to GCS, analyze the image.
analyzeImage(bucket + "/" + filename);
...

## JAVAMS09 Deploying to App Engine

# Initialize App Engine

gcloud app create --region=us-central

# Make the guestbook frontend App Engine friendly
... 
#pom.xml
<plugin>
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>appengine-maven-plugin</artifactId>
  <version>1.3.1</version>
  <configuration>
        <version>1</version>
  </configuration>
</plugin>

#mkdir -p ~/guestbook-frontend/src/main/webapp/WEB-INF/
<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
  <service>default</service>
  <version>1</version>
  <threadsafe>true</threadsafe>
  <runtime>java8</runtime>
  <instance-class>B4_1G</instance-class>
  <sessions-enabled>true</sessions-enabled>
  <manual-scaling>
    <instances>2</instances>
  </manual-scaling>
  <system-properties>
    <property name="spring.profiles.active" value="cloud" />
  </system-properties>
</appengine-web-app>
...

gcloud beta runtime-config configs variables set messages.endpoint \
  "https://guestbook-service-dot-${PROJECT_ID}.appspot.com/guestbookMessages" \
  --config-name frontend_cloud

#  Make the backend service application App Engine friendly
...
# pom.xml
<plugin>
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>appengine-maven-plugin</artifactId>
  <version>1.3.1</version>
  <configuration>
        <version>1</version>
  </configuration>
</plugin>
# mkdir -p ~/guestbook-service/src/main/webapp/WEB-INF/
<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
  <service>guestbook-service</service>
  <version>1</version>
  <threadsafe>true</threadsafe>
  <runtime>java8</runtime>
  <instance-class>B4_1G</instance-class>
  <manual-scaling>
    <instances>2</instances>
  </manual-scaling>
  <system-properties>
    <property name="spring.profiles.active" value="cloud" />
  </system-properties>
</appengine-web-app>

# Deploy
./mvnw appengine:deploy -DskipTests
./mvnw package appengine:deploy -DskipTests

## JAVAMS10 Debugging with Stackdriver Debugge

# Upload a source code capture to Google server
gcloud services enable sourcerepo.googleapis.com

gcloud source repos create google-source-captures

git config --global user.email $(gcloud config get-value core/account)
git config --global user.name "devstar"

gcloud beta debug source upload --project=$PROJECT_ID \
 --branch=[CAPTURE_BRANCH_ID] ./src/

## JAVAMS11 Working with Cloud Spanner

# Enable Cloud Spanner API
gcloud services enable spanner.googleapis.com

# Create and provision a Cloud Spanner instance
gcloud spanner instances create guestbook --config=regional-us-central1 \
  --nodes=1 --description="Guestbook messages"

gcloud spanner databases create messages --instance=guestbook

gcloud spanner databases list --instance=guestbook

cd ~/guestbook-service
mkdir db

# spanner.ddl
CREATE TABLE guestbook_message (
    id STRING(36) NOT NULL,
    name STRING(255) NOT NULL,
    image_uri STRING(255),
    message STRING(255)
) PRIMARY KEY (id);

gcloud spanner databases ddl update messages \
  --instance=guestbook --ddl="$(<db/spanner.ddl)"

# Add the Spring Cloud GCP Cloud Spanner starter

<dependency>
      <groupId>org.springframework.cloud</groupId>
      <artifactId>spring-cloud-gcp-starter-data-spanner</artifactId>
</dependency>

# Configure the cloud profile to use Cloud Spanner

spring.cloud.gcp.sql.enabled=true
spring.cloud.gcp.sql.database-name=messages
spring.cloud.gcp.sql.instance-connection-name=...

spring.cloud.gcp.spanner.instance-id=guestbook
spring.cloud.gcp.spanner.database=messages

# Update the backend service to use Cloud Spanner

package com.example.guestbook;

import lombok.*;
import org.springframework.cloud.gcp.data.spanner.core.mapping.*;
import org.springframework.data.annotation.Id;

@Data
@Table(name = "guestbook_message")
public class GuestbookMessage {
  @PrimaryKey
  @Id
  private String id;

  private String name;

  private String message;

  @Column(name = "image_uri")
  private String imageUri;

  public GuestbookMessage() {
          this.id = java.util.UUID.randomUUID().toString();
  }
}

# Add a method to find messages by name
...
import java.util.List;
public interface GuestbookMessageRepository extends
        PagingAndSortingRepository<GuestbookMessage, String> {
  
  List<GuestbookMessage> findByName(String name);
}
...

# Run and test
curl -XPOST -H "content-type: application/json" \
  -d '{"name": "Ray", "message": "Hello Cloud Spanner"}' \
  http://localhost:8081/guestbookMessages

curl http://localhost:8081/guestbookMessages/search/findByName?name=Ray


gcloud spanner databases execute-sql messages --instance=guestbook \
    --sql="SELECT * FROM guestbook_message WHERE name = 'Ray'"


## JAVAMS12 Deploying to Kubernetes Engine

# Create a Kubernetes Engine cluster

gcloud services enable container.googleapis.com

gcloud container clusters create guestbook-cluster \
  --zone=us-central1-a \
  --num-nodes=2 \
  --machine-type=n1-standard-2 \
  --enable-autorepair \
  --enable-cloud-monitoring \
  --enable-cloud-logging

# Containerize the applications

gcloud services enable containerregistry.googleapis.com

gcloud config list --format 'value(core.project)'

<plugin>
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>jib-maven-plugin</artifactId>
  <version>0.9.6</version>
  <configuration>
          <to>
      <image>gcr.io/[PROJECT_ID]/guestbook-frontend</image>
    </to>
  </configuration>
</plugin>

./mvnw clean compile jib:build

# generate a service account 

gcloud iam service-accounts create guestbook

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:guestbook@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/editor

gcloud iam service-accounts keys create \
  ~/service-account.json \
  --iam-account guestbook@${PROJECT_ID}.iam.gserviceaccount.com

# set service-account.json a k8s secret

kubectl create secret generic guestbook-service-account \
  --from-file=$HOME/service-account.json

kubectl describe secret guestbook-service-account

# Deploy the containers
kubectl apply -f ~/kubernetes/

kubectl get svc guestbook-frontend

kubectl get svc

## JAVAMS13 Working with Kubernetes Monitoring


# Enable Stackdriver Monitoring and view the Stackdriver Kubernetes Monitoring dashboard

# Enable Prometheus Monitoring

gcloud container clusters get-credentials guestbook-cluster \
 --zone=us-central1-a

# Install role-based access control for the Prometheus agent.
kubectl apply -f \
https://storage.googleapis.com/stackdriver-prometheus-documentation/rbac-setup.yml \
  --as=admin --as-group=system:masters

# Install the Prometheus agent.
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
curl -s \
https://storage.googleapis.com/stackdriver-prometheus-documentation/prometheus-service.yml | \
  sed -e "s/\(\s*_kubernetes_cluster_name:*\).*/\1 'guestbook-cluster'/g" | \
  sed -e "s/\(\s*_kubernetes_location:*\).*/\1 'us-central1'/g" | \
  sed -e "s/\(\s*_stackdriver_project_id:*\).*/\1 '${PROJECT_ID}'/g" | \
  kubectl apply -f -

# Verify that the Prometheus agent is running.
kubectl get pods -n stackdriver

# Expose Prometheus metrics from Spring Boot applications

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
  <scope>runtime</scope>
</dependency>

# application.properties
management.server.port=8081
management.endpoints.web.exposure.include=*

# Rebuild the containers

./mvnw clean compile jib:build

# You add Prometheus annotations to the deployment.spec.template.metadata.annotation section of the build YAML file for the frontend application.
 annotations:
  prometheus.io/scrape: 'true'
  prometheus.io/path: '/actuator/prometheus'
  prometheus.io/port: '8081'

# build

./mvnw clean compile jib:build

