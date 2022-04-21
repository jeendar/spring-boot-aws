package tech.stratocrest.aws.demo.java.springboot.beanstalk;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class JavaSpringBootBeanstalkApplication {

	public static void main(String[] args) {
		SpringApplication.run(JavaSpringBootBeanstalkApplication.class, args);
	}

}
