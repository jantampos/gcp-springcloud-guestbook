package gcp.jan.guestbook.backend;

import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource
public interface GuestbookMessageRepository extends 
	PagingAndSortingRepository<GuestbookMessage, Long> {
}