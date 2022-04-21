package tech.stratocrest.aws.demo.java.springboot.beanstalk;

import io.lettuce.core.ReadFrom;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.connection.RedisStaticMasterReplicaConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;

@Configuration
public class RedisConfig {

    @Autowired
    private Environment env;

    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        final String REDIS_CLUSTER_PRIMARY_ENDPOINT = env.getProperty("spring.redis.lettuce.primary.endpoint");
        final String REDIS_CLUSTER_READER_ENDPOINT = env.getProperty("spring.redis.lettuce.reader.endpoint");
        final int redisPort = Integer.parseInt(env.getProperty("spring.redis.port"));
        final String redisPassword = env.getProperty("spring.redis.password");

        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
                .readFrom(ReadFrom.REPLICA_PREFERRED)
                .useSsl()
                .build();
        RedisStaticMasterReplicaConfiguration redisStaticMasterReplicaConfiguration =
                new
                        RedisStaticMasterReplicaConfiguration(REDIS_CLUSTER_PRIMARY_ENDPOINT, redisPort);
        redisStaticMasterReplicaConfiguration.addNode(REDIS_CLUSTER_READER_ENDPOINT, redisPort);
        redisStaticMasterReplicaConfiguration.setPassword(redisPassword);

        return new LettuceConnectionFactory(redisStaticMasterReplicaConfiguration, clientConfig);
    }
}
