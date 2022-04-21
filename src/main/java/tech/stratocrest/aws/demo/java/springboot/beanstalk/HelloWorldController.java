package tech.stratocrest.aws.demo.java.springboot.beanstalk;


import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestHeader;

@Controller
public class HelloWorldController {

    @GetMapping({"/", "hello"})
    public String helloWorld(@RequestParam(required = false, defaultValue = "World") String name, Model model) {
        model.addAttribute("name", name);
        return "hello-world";
    }

}

