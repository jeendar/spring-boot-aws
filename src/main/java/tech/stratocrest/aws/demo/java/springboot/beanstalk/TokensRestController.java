package tech.stratocrest.aws.demo.java.springboot.beanstalk;

import com.amazonaws.services.secretsmanager.AWSSecretsManager;
import com.amazonaws.services.secretsmanager.AWSSecretsManagerClientBuilder;
import com.amazonaws.services.secretsmanager.model.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.core.env.Environment;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Base64;

@RestController
public class TokensRestController {

    Logger logger = LoggerFactory.getLogger(TokensRestController.class);

    @Autowired
    private Environment env;

    @Cacheable(value = "tokens")
    @GetMapping(value = "/tokens", produces = MediaType.TEXT_PLAIN_VALUE)
    public String getTokens() {
        try {
            String applicationEnvironment = this.env.getProperty("application.environment");
            String applicationName = this.env.getProperty("application.name");
            String secretName = this.env.getProperty("application.secret");
            String secret = getSecret(secretName);
            String tokens = String.format("Spring boot application [%s] deployed on [%s] environment with secret [%s]", applicationName, applicationEnvironment, secret);
            logger.info(tokens);
            return tokens;

        } catch (Exception e) {
            logger.debug(String.valueOf(e));
            throw (e);
        }
    }


    private String getSecret(String secretName) {

        String region = "eu-central-1";

        // Create a Secrets Manager client
        AWSSecretsManager client = AWSSecretsManagerClientBuilder.standard()
                .withRegion(region)
                .build();

        // In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
        // See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        // We rethrow the exception by default.

        String secret, decodedBinarySecret;
        GetSecretValueRequest getSecretValueRequest = new GetSecretValueRequest()
                .withSecretId(secretName);
        GetSecretValueResult getSecretValueResult = null;

        try {
            getSecretValueResult = client.getSecretValue(getSecretValueRequest);
        } catch (DecryptionFailureException e) {
            // Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            // Deal with the exception here, and/or rethrow at your discretion.
            throw e;
        } catch (InternalServiceErrorException e) {
            // An error occurred on the server side.
            // Deal with the exception here, and/or rethrow at your discretion.
            throw e;
        } catch (InvalidParameterException e) {
            // You provided an invalid value for a parameter.
            // Deal with the exception here, and/or rethrow at your discretion.
            throw e;
        } catch (InvalidRequestException e) {
            // You provided a parameter value that is not valid for the current state of the resource.
            // Deal with the exception here, and/or rethrow at your discretion.
            throw e;
        } catch (ResourceNotFoundException e) {
            // We can't find the resource that you asked for.
            // Deal with the exception here, and/or rethrow at your discretion.
            throw e;
        }

        // Decrypts secret using the associated KMS CMK.
        // Depending on whether the secret is a string or binary, one of these fields will be populated.
        if (getSecretValueResult.getSecretString() != null) {
            secret = getSecretValueResult.getSecretString();
            logger.info("Secret value {}", secret);
            return secret;

        } else {
            decodedBinarySecret = new String(Base64.getDecoder().decode(getSecretValueResult.getSecretBinary()).array());
            logger.info("Secret value: {}", decodedBinarySecret);
            return decodedBinarySecret;
        }

        // Your code goes here.
    }
}
