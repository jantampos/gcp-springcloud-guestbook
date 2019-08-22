package gcp.jan.guestbook.frontend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.hateoas.config.EnableHypermediaSupport;
import org.springframework.cloud.openfeign.EnableFeignClients;

import org.springframework.context.annotation.*;
import org.springframework.cloud.gcp.pubsub.core.*;
import org.springframework.cloud.gcp.pubsub.integration.outbound.*;
import org.springframework.integration.annotation.*;
import org.springframework.messaging.*;

import java.io.IOException;
import com.google.cloud.vision.v1.*;
import com.google.api.gax.core.CredentialsProvider;

@SpringBootApplication
@EnableFeignClients
@EnableHypermediaSupport(type = EnableHypermediaSupport.HypermediaType.HAL)
public class GuestbookFrontendApplication {

	public static void main(String[] args) {
		SpringApplication.run(GuestbookFrontendApplication.class, args);
	}

	@Bean
    @ServiceActivator(inputChannel = "messagesOutputChannel")
    public MessageHandler messageSender(PubSubTemplate pubsubTemplate) {
        return new PubSubMessageHandler(pubsubTemplate, "messages");
    }

    /**
     * This configures the Vision API settings with a credential 
     * using the the scope we specified in the application.properties.
     */
    @Bean
    public ImageAnnotatorSettings imageAnnotatorSettings(CredentialsProvider credentialsProvider) throws IOException {
        return ImageAnnotatorSettings.newBuilder().setCredentialsProvider(credentialsProvider).build();
    }

    @Bean
    public ImageAnnotatorClient imageAnnotatorClient(ImageAnnotatorSettings settings) throws IOException {
        return ImageAnnotatorClient.create(settings);
    }

}
