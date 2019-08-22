package gcp.jan.guestbook.frontend;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.hateoas.*;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@FeignClient(
	value="messages", 
	url="${messages.endpoint:http://localhost:8081/guestbookMessages}")
//@FeignClient(value="messages", url = "http://localhost:8081")
public interface GuestbookMessagesClient {

	@RequestMapping(method=RequestMethod.GET, path="/")
	Resources<Map> getMessages();
	
	@RequestMapping(method=RequestMethod.GET, path="/{id}")
	Map getMessage(@PathVariable("id") long messageId);
	
	@RequestMapping(method=RequestMethod.POST, path="/")
	Resource<Map> add(@RequestBody Map message);
}